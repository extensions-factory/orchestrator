#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_UNDER_TEST="$REPO_ROOT/hooks/pre-agent-dispatch"
POST_HOOK_UNDER_TEST="$REPO_ROOT/hooks/post-agent-dispatch"
WRAPPER_UNDER_TEST="$REPO_ROOT/hooks/run-hook.cmd"

FAILURES=0

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

assert_valid_reminder() {
    local description="$1"
    shift

    local output
    if ! output="$(echo '{"tool_name":"Agent","tool_input":{}}' | CLAUDE_PLUGIN_ROOT="$REPO_ROOT" "$@" 2>&1)"; then
        fail "$description"
        echo "    hook exited non-zero"
        echo "$output" | sed 's/^/      /'
        return
    fi

    if printf '%s' "$output" | node -e '
const fs = require("fs");
let payload;
try {
  payload = JSON.parse(fs.readFileSync(0, "utf8"));
} catch (error) {
  console.error(`invalid JSON: ${error.message}`);
  process.exit(1);
}
const hookOutput = payload.hookSpecificOutput;
if (!hookOutput || typeof hookOutput !== "object") {
  console.error("missing hookSpecificOutput");
  process.exit(1);
}
if (hookOutput.hookEventName !== "PreToolUse") {
  console.error(`unexpected hookEventName: ${hookOutput.hookEventName}`);
  process.exit(1);
}
const context = hookOutput.additionalContext;
if (typeof context !== "string" || context.trim() === "") {
  console.error("additionalContext was empty");
  process.exit(1);
}
if (!context.includes("model-lookup.sh")) {
  console.error("additionalContext did not mention model-lookup.sh");
  process.exit(1);
}
if (!context.includes("agent=codex") ||
    !context.includes("/codex:rescue --wait --fresh --write --model <model> --effort <effort>") ||
    !context.includes("/codex:review --wait --model <model> --base <base_sha>") ||
    !context.includes("/codex:adversarial-review --wait --model <model> --base <base_sha>")) {
  console.error("additionalContext did not force all Codex command families");
  process.exit(1);
}
'; then
        pass "$description"
    else
        fail "$description"
        echo "    output:"
        echo "$output" | sed 's/^/      /'
    fi
}

echo "PreToolUse pre-agent-dispatch hook output tests"

assert_valid_reminder \
    "hook emits nested PreToolUse additionalContext mentioning model-lookup.sh" \
    bash "$HOOK_UNDER_TEST"

assert_valid_reminder \
    "run-hook.cmd wrapper dispatches to the named pre-agent-dispatch script" \
    bash "$WRAPPER_UNDER_TEST" pre-agent-dispatch

codex_review_output="$(echo '{"tool_name":"Skill","tool_input":{"skill":"codex:review"}}' | bash "$HOOK_UNDER_TEST")"
if [[ "$codex_review_output" == *'/codex:review --wait --model <model> --base <base_sha>'* ]]; then
    pass "hook preserves the exact quality-review command"
else
    fail "hook preserves the exact quality-review command"
fi

codex_security_output="$(echo '{"tool_name":"Skill","tool_input":{"skill":"codex:adversarial-review"}}' | bash "$HOOK_UNDER_TEST")"
codex_security_context="$(printf '%s' "$codex_security_output" | jq -r '.hookSpecificOutput.additionalContext')"
if [[ "$codex_security_context" == *'/codex:adversarial-review --wait --model <model> --base <base_sha> "<security focus>"'* ]]; then
    pass "hook preserves the exact security-review command"
else
    fail "hook preserves the exact security-review command"
fi

post_review_output="$(echo '{"tool_name":"Skill","tool_input":{"skill":"codex:review"}}' | bash "$POST_HOOK_UNDER_TEST")"
post_review_context="$(printf '%s' "$post_review_output" | jq -r '.hookSpecificOutput.additionalContext')"
if [[ "$post_review_context" == *'.superpowers/<task>/turn-<turn>-review.md'* && "$post_review_context" == *'construct'*'response envelope'* ]]; then
    pass "post hook enforces the native-review adapter"
else
    fail "post hook enforces the native-review adapter"
fi

post_rescue_output="$(echo '{"tool_name":"Skill","tool_input":{"skill":"codex:rescue"}}' | bash "$POST_HOOK_UNDER_TEST")"
post_rescue_context="$(printf '%s' "$post_rescue_output" | jq -r '.hookSpecificOutput.additionalContext')"
if [[ "$post_rescue_context" == *'.superpowers/<task>/turn-<turn>-response.json'* ]]; then
    pass "post hook preserves the rescue response path"
else
    fail "post hook preserves the rescue response path"
fi

post_unrelated_output="$(echo '{"tool_name":"Skill","tool_input":{"skill":"brainstorming"}}' | bash "$POST_HOOK_UNDER_TEST")"
if [[ -z "$post_unrelated_output" ]]; then
    pass "post hook stays silent for non-Codex skills"
else
    fail "post hook stays silent for non-Codex skills"
fi

unrelated_output="$(echo '{"tool_name":"Skill","tool_input":{"skill":"brainstorming"}}' | bash "$HOOK_UNDER_TEST")"
if [[ -z "$unrelated_output" ]]; then
    pass "hook stays silent for non-Codex skills"
else
    fail "hook stays silent for non-Codex skills"
fi

echo "---jq schema check---"
if jq -e '.hooks.PreToolUse[] | select(.matcher | contains("Agent")) | .hooks[] | select(.type == "command") | .command' \
    "$REPO_ROOT/hooks/hooks.json" >/dev/null; then
    pass "hooks.json registers PreToolUse matcher Agent -> pre-agent-dispatch"
else
    fail "hooks.json missing PreToolUse matcher Agent entry"
fi

if [[ "$FAILURES" -gt 0 ]]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
fi

echo "STATUS: PASSED"
