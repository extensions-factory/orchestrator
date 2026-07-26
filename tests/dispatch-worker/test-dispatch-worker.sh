#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/dispatch-worker.mjs"
SKILL="$REPO_ROOT/skills/dispatch-agent/SKILL.md"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
check() {
  local needle="$1"
  grep -Fq -- "$needle" "$SKILL" || fail "missing skill contract: $needle"
}
assert_contains() {
  local value="$1" needle="$2"
  [[ "$value" == *"$needle"* ]] || fail "expected '$needle' in '$value'"
}

check 'Step 4a: Read the provider rescue doc'
check '<plugin-root>/<provider>/<ver>/commands/rescue.md'
check 'flag surface, effort enum, model aliases, plugin root, and profile policy'
check 'Cache this read once per provider per session.'
check 'Ignore the entire "Execution mode" section.'
check '`none|minimal|low|medium|high|xhigh`'
check '`low|medium|high`'

PLUGIN="$TMP/plugin"
mkdir -p "$PLUGIN/scripts"
cat > "$PLUGIN/scripts/codex-companion.mjs" <<'FAKE'
import { appendFileSync, existsSync } from "node:fs";

const [command, ...args] = process.argv.slice(2);
if (process.env.FAKE_TRACE) appendFileSync(process.env.FAKE_TRACE, `${command} ${args.join(" ")}\n`);
if (command === "task") {
  console.log("Queued task-fixture-1: Codex Task.");
} else if (command === "status") {
  if (process.env.FAKE_JOB_FILE && !existsSync(process.env.FAKE_JOB_FILE)) {
    console.error("job file missing before wait");
    process.exit(2);
  }
  const mode = process.env.FAKE_CASE;
  const status =
    mode === "long" || mode === "runaway" ? "running" :
    mode === "killed" ? "killed" :
    mode === "future" ? "archived" :
    "completed";
  const createdAt = mode === "runaway" ? "1970-01-01T00:00:00.000Z" : new Date().toISOString();
  console.log(JSON.stringify({id: "task-fixture-1", status, phase: status, createdAt}));
} else if (command === "result") {
  if (process.env.FAKE_CASE === "malformed") console.log("worker returned prose");
  else console.log('worker prose\n```json\n{"message_type":"deliver","output":{"status":"done"}}\n```');
}
FAKE

run_case() {
  local mode="$1" work="$TMP/$1"
  mkdir -p "$work"
  printf '{}\n' > "$work/turn-1-request.json"
  printf 'bounded prompt\n' > "$work/turn-1-prompt.txt"
  FAKE_CASE="$mode" node "$SCRIPT" \
    --provider codex \
    --plugin-root "$PLUGIN" \
    --request "$work/turn-1-request.json" \
    --prompt "$work/turn-1-prompt.txt" \
    --model gpt-5.6-sol \
    --effort high
}

output="$(run_case happy)"
[[ "$output" == "TERMINAL completed $TMP/happy/turn-1-response.json" ]] || fail "happy output: $output"
node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$TMP/happy/turn-1-response.json"
[[ -s "$TMP/happy/turn-1-job.txt" ]] || fail "job id was not persisted"

output="$(run_case malformed)"
[[ "$output" == "TERMINAL malformed $TMP/malformed/turn-1-result-raw.txt" ]] || fail "malformed output: $output"
grep -Fq 'worker returned prose' "$TMP/malformed/turn-1-result-raw.txt" || fail "raw result not preserved"
[[ ! -e "$TMP/malformed/turn-1-response.json" ]] || fail "malformed result created a response"

output="$(run_case killed)"
assert_contains "$output" "TERMINAL failed killed"

output="$(run_case long)"
assert_contains "$output" $'PENDING task-fixture-1\nRESUME node scripts/dispatch-worker.mjs --job \'task-fixture-1\''

TRACE="$TMP/resume.trace"
FAKE_TRACE="$TRACE" FAKE_CASE=long node "$SCRIPT" \
  --job task-fixture-1 \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$TMP/long/turn-1-request.json" \
  --prompt "$TMP/long/turn-1-prompt.txt" \
  --model gpt-5.6-sol \
  --effort high >/dev/null
grep -q '^status ' "$TRACE" || fail "resume did not wait"
! grep -q '^task ' "$TRACE" || fail "resume spawned a replacement job"

output="$(FAKE_CASE=long node "$SCRIPT" \
  --job 'task-fixture-1;echo-pwned' \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$TMP/long/turn-1-request.json" \
  --prompt "$TMP/long/turn-1-prompt.txt" \
  --model gpt-5.6-sol \
  --effort high)"
assert_contains "$output" "TERMINAL failed wrapper invalid---job-task-fixture-1;echo-pwned"
[[ "$output" != *"RESUME "* ]] || fail "invalid job emitted a resume command"

output="$(run_case future)"
assert_contains "$output" "TERMINAL failed archived"

check 'Step 4c: Invoke the haiku forwarder'
check 'Run the command given below. Then:'
check 'Output begins TERMINAL -> return that line verbatim. Stop.'
check 'Output begins PENDING  -> run the RESUME command printed beneath it. Repeat.'
check 'Return nothing else. Do not read files, summarize, or run any other command.'
check 'COMMAND:'

work="$TMP/crash"
mkdir -p "$work"
printf '{}\n' > "$work/turn-1-request.json"
printf 'bounded prompt\n' > "$work/turn-1-prompt.txt"
output="$(FAKE_CASE=happy FAKE_JOB_FILE="$work/turn-1-job.txt" node "$SCRIPT" \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$work/turn-1-request.json" \
  --prompt "$work/turn-1-prompt.txt" \
  --model gpt-5.6-sol \
  --effort high)"
assert_contains "$output" "TERMINAL completed"
check 'node scripts/dispatch-worker.mjs --job $(cat turn-N-job.txt) ...<same flags>'
check 'If haiku returns no `TERMINAL` line'

work="$TMP/runaway"
mkdir -p "$work"
printf '{}\n' > "$work/turn-1-request.json"
printf 'bounded prompt\n' > "$work/turn-1-prompt.txt"
output="$(FAKE_CASE=runaway node "$SCRIPT" \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$work/turn-1-request.json" \
  --prompt "$work/turn-1-prompt.txt" \
  --model gpt-5.6-sol \
  --effort high \
  --max-wall-ms 1)"
[[ "$output" == "TERMINAL failed timeout task-fixture-1" ]] || fail "runaway output: $output"

output="$(FAKE_CASE=long node "$SCRIPT" \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$TMP/long/turn-1-request.json" \
  --prompt "$TMP/long/turn-1-prompt.txt" \
  --model gpt-5.6-sol \
  --effort high \
  --max-wall-ms 3600000)"
assert_contains "$output" "PENDING task-fixture-1"
assert_contains "$output" "'--max-wall-ms' '3600000'"

echo "PASS test-dispatch-worker"
