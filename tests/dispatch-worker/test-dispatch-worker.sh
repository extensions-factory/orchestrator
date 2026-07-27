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
    mode === "long" || mode === "runaway" || mode === "no-created-at" ? "running" :
    mode === "killed" ? "killed" :
    mode === "future" ? "archived" :
    "completed";
  const createdAt = mode === "runaway" ? "1970-01-01T00:00:00.000Z" : new Date().toISOString();
  const state = {id: "task-fixture-1", status, phase: status, createdAt};
  if (mode === "no-created-at") delete state.createdAt;
  console.log(JSON.stringify(state));
} else if (command === "result") {
  if (process.env.FAKE_CASE === "malformed") console.log("worker returned prose");
  else console.log('worker prose\n```json\n{"message_type":"deliver","output":{"status":"done"}}\n```');
}
FAKE

case_dir() {
  printf '%s/%s/.superpowers/runs/20260727T141500Z-test/40-execution/tasks/task-%s/turns/001-implement' "$TMP" "$1" "$1"
}

run_case() {
  local mode="$1" work
  work="$(case_dir "$mode")"
  mkdir -p "$work"
  printf '{}\n' > "$work/request.json"
  printf 'bounded prompt\n' > "$work/prompt.txt"
  FAKE_CASE="$mode" node "$SCRIPT" \
    --provider codex \
    --plugin-root "$PLUGIN" \
    --request "$work/request.json" \
    --prompt "$work/prompt.txt" \
    --model gpt-5.6-sol \
    --effort high
}

scoped="$TMP/scoped/.superpowers/runs/20260727T141500Z-test/40-execution/tasks/task-1-build/turns/001-implement"
mkdir -p "$scoped"
printf '{}\n' > "$scoped/request.json"
printf 'bounded prompt\n' > "$scoped/prompt.txt"
output="$(FAKE_CASE=happy node "$SCRIPT" \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$scoped/request.json" \
  --prompt "$scoped/prompt.txt" \
  --model gpt-5.6-sol \
  --effort high)"
[[ "$output" == "TERMINAL completed $scoped/response.json" ]] || fail "run-scoped output: $output"
[[ -s "$scoped/job.txt" ]] || fail "run-scoped job id was not persisted"

output="$(run_case happy)"
happy="$(case_dir happy)"
[[ "$output" == "TERMINAL completed $happy/response.json" ]] || fail "happy output: $output"
node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$happy/response.json"
[[ -s "$happy/job.txt" ]] || fail "job id was not persisted"

output="$(run_case malformed)"
malformed="$(case_dir malformed)"
[[ "$output" == "TERMINAL malformed $malformed/result-raw.txt" ]] || fail "malformed output: $output"
grep -Fq 'worker returned prose' "$malformed/result-raw.txt" || fail "raw result not preserved"
[[ ! -e "$malformed/response.json" ]] || fail "malformed result created a response"

output="$(run_case killed)"
assert_contains "$output" "TERMINAL failed killed"

output="$(run_case long)"
assert_contains "$output" $'PENDING task-fixture-1\nRESUME node scripts/dispatch-worker.mjs --job \'task-fixture-1\''

TRACE="$TMP/resume.trace"
long="$(case_dir long)"
FAKE_TRACE="$TRACE" FAKE_CASE=long node "$SCRIPT" \
  --job task-fixture-1 \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$long/request.json" \
  --prompt "$long/prompt.txt" \
  --model gpt-5.6-sol \
  --effort high >/dev/null
grep -q '^status ' "$TRACE" || fail "resume did not wait"
! grep -q '^task ' "$TRACE" || fail "resume spawned a replacement job"

output="$(FAKE_CASE=long node "$SCRIPT" \
  --job 'task-fixture-1;echo-pwned' \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$long/request.json" \
  --prompt "$long/prompt.txt" \
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

work="$(case_dir crash)"
mkdir -p "$work"
printf '{}\n' > "$work/request.json"
printf 'bounded prompt\n' > "$work/prompt.txt"
output="$(FAKE_CASE=happy FAKE_JOB_FILE="$work/job.txt" node "$SCRIPT" \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$work/request.json" \
  --prompt "$work/prompt.txt" \
  --model gpt-5.6-sol \
  --effort high)"
assert_contains "$output" "TERMINAL completed"
check 'node scripts/dispatch-worker.mjs --job $(cat <turn-dir>/job.txt) ...<same flags>'
check 'If haiku returns no `TERMINAL` line'

work="$(case_dir runaway)"
mkdir -p "$work"
printf '{}\n' > "$work/request.json"
printf 'bounded prompt\n' > "$work/prompt.txt"
output="$(FAKE_CASE=runaway node "$SCRIPT" \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$work/request.json" \
  --prompt "$work/prompt.txt" \
  --model gpt-5.6-sol \
  --effort high \
  --max-wall-ms 1)"
[[ "$output" == "TERMINAL failed timeout task-fixture-1" ]] || fail "runaway output: $output"

work="$(case_dir no-created-at)"
mkdir -p "$work"
printf '{}\n' > "$work/request.json"
printf 'bounded prompt\n' > "$work/prompt.txt"
output="$(FAKE_CASE=no-created-at node "$SCRIPT" \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$work/request.json" \
  --prompt "$work/prompt.txt" \
  --model gpt-5.6-sol \
  --effort high)"
[[ "$output" == "TERMINAL failed no-createdAt task-fixture-1" ]] || fail "no-created-at output: $output"
[[ "$output" != *"PENDING "* ]] || fail "no-created-at emitted PENDING: $output"
[[ "$output" != *"RESUME "* ]] || fail "no-created-at emitted RESUME: $output"

output="$(FAKE_CASE=long node "$SCRIPT" \
  --provider codex \
  --plugin-root "$PLUGIN" \
  --request "$long/request.json" \
  --prompt "$long/prompt.txt" \
  --model gpt-5.6-sol \
  --effort high \
  --max-wall-ms 3600000)"
assert_contains "$output" "PENDING task-fixture-1"
assert_contains "$output" "'--max-wall-ms' '3600000'"

SEND_RECEIVE="$(sed -n '/^4\. \*\*Prepare and send/,/^6\. \*\*Validate/p' "$SKILL")"

check_step() {
  local needle="$1"
  grep -Fq -- "$needle" <<< "$SEND_RECEIVE" || fail "missing send/receive contract: $needle"
}
check_absent() {
  local needle="$1"
  ! grep -Fq -- "$needle" <<< "$SEND_RECEIVE" || fail "obsolete send/receive contract remains: $needle"
}

check_step 'Step 4b: Build the literal command string'
check_step 'node scripts/dispatch-worker.mjs \'
check_step '--request <turn-dir>/request.json \'
check_step '--prompt <turn-dir>/prompt.txt \'
check_step 'Receive one terminal line.'
check_absent 'Step 5: Receive one terminal line'
check_step 'For Codex RESCUE results, Antigravity RESCUE results, and claude worker results, require `TERMINAL <status> <path>`.'
check_step 'Codex `code_review_quality` and `security_review` bypass the `TERMINAL` receive entirely; their review-output adapter in `references/codex-worker-protocol.md` persists stdout verbatim to `<turn-dir>/review.md` and constructs `<turn-dir>/response.json` before Step 6 validation.'
check_step 'Pass that path unchanged to Step 6 validation.'
check_absent 'poll `/codex:status`'
check_absent 'run `/codex:result`'
check_absent 'poll `/antigravity:status'
check_absent 'run `/antigravity:result'

echo "PASS test-dispatch-worker"
