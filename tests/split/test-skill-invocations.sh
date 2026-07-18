#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGETS=(
  "$ROOT/skills"
  "$ROOT/hooks"
  "$ROOT/assets/message-protocol.json"
  "$ROOT/CLAUDE.md"
  "$ROOT/.github/PULL_REQUEST_TEMPLATE.md"
  "$ROOT/docs/orchestrator-workflow.md"
  "$ROOT/README.md"
)

fail=0

if legacy="$(rg -n 'superpowers:[a-z0-9-]+' "${TARGETS[@]}" || true)"; [[ -n "$legacy" ]]; then
  echo "[FAIL] legacy superpowers: skill references"
  echo "$legacy"
  fail=1
fi

bare="$(rg -n '(^|[^:[:alnum:]/-])dispatch-agent([^/[:alnum:]-]|$)' "${TARGETS[@]}" \
  | grep -v '/skills/dispatch-agent/SKILL.md:2:name: dispatch-agent$' || true)"
if [[ -n "$bare" ]]; then
  echo "[FAIL] bare dispatch-agent references"
  echo "$bare"
  fail=1
fi

grep -Fq 'superpowers-orchestrator:subagent-driven-development' "$ROOT/skills/writing-plans/SKILL.md" || {
  echo "[FAIL] writing-plans missing namespaced subagent-driven-development"
  fail=1
}
grep -Fq 'superpowers-orchestrator:dispatch-agent' "$ROOT/skills/subagent-driven-development/SKILL.md" || {
  echo "[FAIL] subagent-driven-development missing namespaced dispatch-agent"
  fail=1
}
grep -Fq 'superpowers-worker:test-driven-development' "$ROOT/skills/writing-skills/SKILL.md" || {
  echo "[FAIL] writing-skills missing worker-owned TDD namespace"
  fail=1
}
grep -Fq 'never use legacy `superpowers:*` or a bare skill name at an invocation point' "$ROOT/skills/writing-skills/SKILL.md" || {
  echo "[FAIL] writing-skills does not teach fully qualified invocation IDs"
  fail=1
}
grep -Fq 'superpowers-orchestrator:writing-plans' "$ROOT/skills/brainstorming/SKILL.md" || {
  echo "[FAIL] brainstorming missing namespaced writing-plans invocation"
  fail=1
}
grep -Fq '`skill: superpowers-worker:receiving-code-review`' "$ROOT/skills/subagent-driven-development/SKILL.md" || {
  echo "[FAIL] review remediation missing worker-owned skill namespace"
  fail=1
}
grep -Fq 'For every agent, set `skill` to the namespaced discipline' "$ROOT/skills/dispatch-agent/SKILL.md" || {
  echo "[FAIL] dispatch-agent does not namespace worker skill for every provider"
  fail=1
}

[[ "$fail" -eq 0 ]] || exit 1
echo 'PASS test-skill-invocations'
