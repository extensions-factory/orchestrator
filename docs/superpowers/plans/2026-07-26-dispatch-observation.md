# Single Observation Path for Worker Dispatch Implementation Plan

<!-- riso-tech:orchestrator-split START -->
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development when the harness supports subagents; use superpowers-orchestrator:executing-plans only when the harness has no subagent capability. Steps use checkbox (`- [ ]`) syntax for tracking.
<!-- riso-tech:orchestrator-split END -->

**Spec:** `docs/superpowers/specs/2026-07-26-dispatch-observation-design.md`

**Goal:** Replace false-done Codex and Antigravity forwarder notifications with one resumable observation path that returns a definitive `TERMINAL` line containing the worker response path.

**Architecture:** The orchestrator reads and caches each provider's rescue contract, writes the request and prompt files, and builds one literal command. `scripts/dispatch-worker.mjs` owns spawn, wait, classification, extraction, persistence, and wall-clock bounds; a four-line haiku forwarder only executes the command and repeats a script-provided `RESUME` command after `PENDING`. Claude workers retain their existing response-file path and add the same final `TERMINAL` contract.

**Tech Stack:** Node.js standard library, plain Bash contract tests, fixture companion scripts selected through `--plugin-root`, Markdown skill instructions, and the existing `scripts/validate-message.mjs` response validator.

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- US-1: the orchestrator reads and caches the target provider's rescue doc, validates provider-specific effort values, and ignores its stale "Execution mode" section before dispatch.
- US-2: one wrapper spawns Codex or Antigravity in the background, persists the job id, waits, classifies every non-active status as terminal, extracts valid envelopes, preserves malformed output, and emits only `TERMINAL` or `PENDING`/`RESUME`.
- US-3: a haiku subagent executes only the literal wrapper command and any script-provided `RESUME` command, returning the final `TERMINAL` line verbatim.
- US-4: an interrupted dispatch recovers from `.superpowers/<task>/turn-N-job.txt` without creating a replacement job.
- US-5: the wrapper stops an active job's resume loop after the configurable wall-clock maximum, defaulting to 60 minutes.
- US-6: dispatch-agent Steps 4–5 use sub-steps 4a/4b/4c and receive the response path from the `TERMINAL` line without invoking provider status or result slash commands.
- US-7: Claude workers finish with the same `TERMINAL completed .superpowers/<task>/turn-N-response.json` observation used by Codex and Antigravity.

### Artifacts

- `scripts/dispatch-worker.mjs` — provider-neutral spawn, wait, classify, extract, persist, resume, and timeout wrapper.
- `tests/dispatch-worker/run-tests.sh` — plain Bash discovery runner.
- `tests/dispatch-worker/test-dispatch-worker.sh` — CI-safe wrapper and skill contract tests using a fake companion under a fixture `--plugin-root`.
- `skills/dispatch-agent/SKILL.md` — rescue-doc read, literal-command construction, haiku forwarder definition, crash recovery, collapsed receive, and Claude `TERMINAL` alignment.

### How to see it working

- Run `bash tests/dispatch-worker/run-tests.sh`; expected output ends with `PASS test-dispatch-worker` and `=== All dispatch-worker tests passed ===` without requiring `agy` or `codex`.
- Run `bash tests/split/run-all.sh`; expected output is `ALL ORCHESTRATOR SPLIT TESTS PASS`, confirming the `riso-tech:orchestrator-split` markers remain valid.
- Re-dispatch the documented `documentation_knowledge_transfer` Antigravity probe through the wrapper; expected observation is one `TERMINAL completed .superpowers/<task>/turn-N-response.json` after the real worker finishes, not the 14.9-second queued notification.

### Risks

- Companion stdout must be classified without letting haiku parse it; fixture cases pin completed, malformed, killed, active, future terminal, and runaway behavior.
- The Claude Code Bash tool caps at 600 seconds; `--timeout-ms 570000` leaves a 30-second margin and requires resumable waits.
- A crash between spawn and wait can lose the only recovery handle unless `turn-N-job.txt` is written before the first `status --wait`.
- Static skill tests prove the required instructions and forbidden slash-command absence, while the live smoke test remains the end-to-end model-compliance check.

## Global Constraints

- The wrapper supports only `codex` and `antigravity`; both use the companion CLI `task [--background]`, `status [job-id] [--wait] [--timeout-ms <ms>]`, `result [job-id]`, and `cancel [job-id]`.
- The status wait uses `--timeout-ms 570000`; the active statuses are exactly `queued|running`, and every other status is terminal.
- The default maximum wall-clock duration is 60 minutes and `--max-wall-ms` overrides it.
- The provider rescue doc is authoritative for flags, effort values, model aliases, plugin root, and profile policy, except that its "Execution mode" section is ignored.
- Codex legal effort values are `none|minimal|low|medium|high|xhigh`; Antigravity legal effort values are `low|medium|high`.
- The wrapper always exits 0 after emitting `TERMINAL` or `PENDING`, because a non-zero exit appears to haiku as a tool error.
- The stdout tokens are spelled exactly `TERMINAL`, `PENDING`, and `RESUME`.
- Per-turn files are spelled exactly `turn-N-job.txt`, `turn-N-prompt.txt`, `turn-N-response.json`, and `turn-N-result-raw.txt`.
- `turn-N-job.txt` is written immediately after spawn returns a job id and before the first wait.
- Tests use Node.js and Bash only, follow `set -euo pipefail` plus a `fail()` helper, require neither `agy` nor `codex`, and point `--plugin-root` at a fixture fake companion.
- Provider readiness preflight, routing data, `model-lookup.sh`, the degradation ladder, review command families, and the companion plugins remain unchanged.
- Repository edits target `skills/dispatch-agent/SKILL.md`, never a cached plugin copy.
- No external dependency is added.

**Out of scope (do not implement):**

- Rewriting Codex or Antigravity `commands/rescue.md`.
- Adding a persistent poll loop or a second observation mechanism.
- Replacing the Claude worker path.
- Changing provider readiness preflight, routing, model lookup, or the degradation ladder.

---

## US-1: Pre-dispatch rescue-doc read

### Task 1: Add the rescue-doc contract and test harness

**Depends on:** none

**Files:**
- Create: `tests/dispatch-worker/run-tests.sh`
- Create: `tests/dispatch-worker/test-dispatch-worker.sh`
- Modify: `skills/dispatch-agent/SKILL.md`
- Test: `tests/dispatch-worker/test-dispatch-worker.sh`

**Interfaces:**
- Consumes: `<plugin-root>/<provider>/<ver>/commands/rescue.md`; provider name `codex|antigravity`; the effort string from `model-lookup.sh`; the doc's flag surface, effort enum, model aliases, plugin root, and profile policy.
- Produces: session cache keyed by provider; validated effort; resolved model and optional profile; a rule that discards the complete "Execution mode" section and never derives `--background` from it.

**task_type:** implementation_coding

- [ ] **Step 1: Write the failing skill contract test**

Create `tests/dispatch-worker/run-tests.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== dispatch-worker tests ==="
for test_file in "$SCRIPT_DIR"/test-*.sh; do
  echo
  echo ">>> $test_file"
  bash "$test_file"
done
echo
echo "=== All dispatch-worker tests passed ==="
```

Create `tests/dispatch-worker/test-dispatch-worker.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/dispatch-agent/SKILL.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
check() {
  local needle="$1"
  grep -Fq -- "$needle" "$SKILL" || fail "missing skill contract: $needle"
}

check 'Step 4a: Read the provider rescue doc'
check '<plugin-root>/<provider>/<ver>/commands/rescue.md'
check 'flag surface, effort enum, model aliases, plugin root, and profile policy'
check 'Cache this read once per provider per session.'
check 'Ignore the entire "Execution mode" section.'
check '`none|minimal|low|medium|high|xhigh`'
check '`low|medium|high`'

echo "PASS test-dispatch-worker"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 1 with `FAIL: missing skill contract: Step 4a: Read the provider rescue doc`.

- [ ] **Step 3: Add the minimal Step 4a instructions**

In `skills/dispatch-agent/SKILL.md`, insert this exact block immediately before the current Step 4:

```markdown
### Step 4a: Read the provider rescue doc

For a Codex or Antigravity rescue dispatch, read `<plugin-root>/<provider>/<ver>/commands/rescue.md` before building the command. Extract the flag surface, effort enum, model aliases, plugin root, and profile policy. Cache this read once per provider per session.

Ignore the entire "Execution mode" section. It instructs the slash-command forwarder and must not determine whether the companion receives `--background`.

Validate the effort from `model-lookup.sh` against the provider doc: Codex accepts only `none|minimal|low|medium|high|xhigh`; Antigravity accepts only `low|medium|high`. Pass a resolved model alias verbatim, and pass `--profile` only when an existing profile was explicitly selected; never invent a profile.
```

- [ ] **Step 4: Run the focused contract test**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 0 with `PASS test-dispatch-worker`.

<!-- riso-tech:orchestrator-split START -->
**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/dispatch-worker/run-tests.sh tests/dispatch-worker/test-dispatch-worker.sh skills/dispatch-agent/SKILL.md
git commit -m "feat: read provider rescue contract"
```

The worker never runs these commands.
<!-- riso-tech:orchestrator-split END -->

**US-1 Checkpoint:**

- Action: Prepare a Codex rescue dispatch. Expected: Step 4a reads `<plugin-root>/codex/<ver>/commands/rescue.md`, extracts the five named contract fields, and accepts only `none|minimal|low|medium|high|xhigh`.
- Action: Prepare a second Codex dispatch in the same session. Expected: the provider-keyed cached read is used and the file is not read again.
- Action: Include an "Execution mode" section in the rescue doc. Expected: Step 4a ignores the complete section and does not use it to remove or add `--background`.
- Action: Prepare an Antigravity rescue dispatch. Expected: Step 4a reads `<plugin-root>/antigravity/<ver>/commands/rescue.md` and accepts only `low|medium|high`.
- Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`. Expected: `PASS test-dispatch-worker` confirms all required read, cache, ignore, and effort-enum instructions.

## US-2: dispatch-worker.mjs wrapper and stdout contract

### Task 2: Implement the provider-neutral wrapper

**Depends on:** Task 1

**Files:**
- Create: `scripts/dispatch-worker.mjs`
- Modify: `tests/dispatch-worker/test-dispatch-worker.sh`
- Test: `tests/dispatch-worker/test-dispatch-worker.sh`

**Interfaces:**
- Consumes: `main(argv: string[]): void`; flags `--provider <codex|antigravity>`, `--plugin-root <path>`, `--request <turn-N-request.json>`, `--prompt <turn-N-prompt.txt>`, `--model <model>`, `--effort <effort>`, optional `--profile <name>`, and optional `--job <job-id>`; companion entry point `<plugin-root>/scripts/<provider>-companion.mjs`.
- Produces: `TERMINAL completed <turn-N-response.json>`, `TERMINAL malformed <turn-N-result-raw.txt>`, `TERMINAL failed <status> <reason>`, or `PENDING <job-id>` plus `RESUME node scripts/dispatch-worker.mjs --job <job-id> ...<same flags>`; always process exit 0.

**task_type:** implementation_coding

- [ ] **Step 1: Extend the test with failing wrapper cases**

Replace `tests/dispatch-worker/test-dispatch-worker.sh` with:

```bash
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
import { appendFileSync } from "node:fs";

const [command, ...args] = process.argv.slice(2);
if (process.env.FAKE_TRACE) appendFileSync(process.env.FAKE_TRACE, `${command} ${args.join(" ")}\n`);
if (command === "task") {
  console.log("Queued task-fixture-1: Codex Task.");
} else if (command === "status") {
  const mode = process.env.FAKE_CASE;
  const status = mode === "long" ? "running" : mode === "killed" ? "killed" : mode === "future" ? "archived" : "completed";
  console.log(JSON.stringify({id: "task-fixture-1", status, phase: status}));
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
assert_contains "$output" $'PENDING task-fixture-1\nRESUME node scripts/dispatch-worker.mjs --job task-fixture-1'

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

output="$(run_case future)"
assert_contains "$output" "TERMINAL failed archived"

echo "PASS test-dispatch-worker"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit non-zero because `scripts/dispatch-worker.mjs` does not exist.

- [ ] **Step 3: Write the minimal wrapper**

Create `scripts/dispatch-worker.mjs` with:

```javascript
#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ACTIVE = new Set(["queued", "running"]);
const WAIT_TIMEOUT_MS = "570000";

function parseArgs(argv) {
  const values = {};
  for (let i = 0; i < argv.length; i += 2) {
    const flag = argv[i];
    if (!flag?.startsWith("--") || argv[i + 1] === undefined) throw new Error(`invalid argument: ${flag ?? ""}`);
    values[flag.slice(2)] = argv[i + 1];
  }
  for (const key of ["provider", "plugin-root", "request", "prompt", "model", "effort"])
    if (!values[key]) throw new Error(`missing --${key}`);
  if (!["codex", "antigravity"].includes(values.provider)) throw new Error(`unsupported provider ${values.provider}`);
  return values;
}

function runCompanion(companion, args) {
  const result = spawnSync(process.execPath, [companion, ...args], {encoding: "utf8"});
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error((result.stderr || result.stdout || `companion exit ${result.status}`).trim());
  return result.stdout.trim();
}

function jobIdFrom(stdout) {
  const match = stdout.match(/\btask-[A-Za-z0-9-]+\b/);
  if (!match) throw new Error("companion returned no job id");
  return match[0];
}

function statusFrom(stdout) {
  const start = stdout.indexOf("{");
  const end = stdout.lastIndexOf("}");
  if (start >= 0 && end > start) {
    const value = JSON.parse(stdout.slice(start, end + 1));
    if (typeof value.status === "string") return value;
  }
  const match = stdout.match(/\bstatus\s*[:=]\s*([A-Za-z0-9_-]+)/i);
  if (!match) throw new Error("companion returned no status");
  return {status: match[1]};
}

function responseEnvelope(stdout) {
  for (const match of stdout.matchAll(/```(?:json)?\s*([\s\S]*?)```/gi)) {
    try {
      const value = JSON.parse(match[1]);
      if (value && typeof value === "object" && !Array.isArray(value)) return value;
    } catch {}
  }
  try {
    const value = JSON.parse(stdout);
    if (value && typeof value === "object" && !Array.isArray(value)) return value;
  } catch {}
  return null;
}

function shellQuote(value) {
  return `'${String(value).replaceAll("'", `'\\''`)}'`;
}

function resumeLine(values, jobId) {
  const flags = [
    "--provider", values.provider,
    "--plugin-root", values["plugin-root"],
    "--request", values.request,
    "--prompt", values.prompt,
    "--model", values.model,
    "--effort", values.effort,
  ];
  if (values.profile) flags.push("--profile", values.profile);
  return `RESUME node scripts/dispatch-worker.mjs --job ${shellQuote(jobId)} ${flags.map(shellQuote).join(" ")}`;
}

export function main(argv) {
  try {
    const values = parseArgs(argv);
    const companion = join(resolve(values["plugin-root"]), "scripts", `${values.provider}-companion.mjs`);
    const requestName = values.request.match(/turn-(\d+)-request\.json$/);
    if (!requestName) throw new Error("--request must end in turn-N-request.json");
    const turn = requestName[1];
    const taskDir = dirname(resolve(values.request));
    const displayDir = dirname(values.request);
    const jobPath = join(taskDir, `turn-${turn}-job.txt`);
    const responsePath = join(taskDir, `turn-${turn}-response.json`);
    const rawPath = join(taskDir, `turn-${turn}-result-raw.txt`);
    const displayResponse = join(displayDir, `turn-${turn}-response.json`);
    const displayRaw = join(displayDir, `turn-${turn}-result-raw.txt`);

    let jobId = values.job;
    if (!jobId) {
      const prompt = readFileSync(values.prompt, "utf8");
      const taskArgs = ["task", "--background", "--fresh", "--write", "--model", values.model, "--effort", values.effort];
      if (values.profile) taskArgs.push("--profile", values.profile);
      taskArgs.push(prompt);
      jobId = jobIdFrom(runCompanion(companion, taskArgs));
      writeFileSync(jobPath, `${jobId}\n`);
    }

    const state = statusFrom(runCompanion(companion, ["status", jobId, "--wait", "--timeout-ms", WAIT_TIMEOUT_MS]));
    if (ACTIVE.has(state.status)) {
      console.log(`PENDING ${jobId}\n${resumeLine(values, jobId)}`);
      return;
    }
    if (state.status !== "completed") {
      console.log(`TERMINAL failed ${state.status} ${String(state.phase ?? "companion-status").replace(/\s+/g, "-")}`);
      return;
    }

    const result = runCompanion(companion, ["result", jobId]);
    const envelope = responseEnvelope(result);
    if (!envelope) {
      writeFileSync(rawPath, `${result}\n`);
      console.log(`TERMINAL malformed ${displayRaw}`);
      return;
    }
    writeFileSync(responsePath, `${JSON.stringify(envelope, null, 2)}\n`);
    console.log(`TERMINAL completed ${displayResponse}`);
  } catch (error) {
    console.log(`TERMINAL failed wrapper ${String(error.message ?? error).replace(/\s+/g, "-")}`);
  }
}

const invoked = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) main(process.argv.slice(2));
```

- [ ] **Step 4: Run the wrapper contract test**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 0 with `PASS test-dispatch-worker`; the fake companion covers completed extraction, malformed preservation, killed classification, `PENDING`/`RESUME`, `--job` spawn bypass, future terminal classification, job persistence, and exit-0 behavior.

<!-- riso-tech:orchestrator-split START -->
**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add scripts/dispatch-worker.mjs tests/dispatch-worker/test-dispatch-worker.sh
git commit -m "feat: add dispatch worker wrapper"
```

The worker never runs these commands.
<!-- riso-tech:orchestrator-split END -->

**US-2 Checkpoint:**

- Run: `FAKE_CASE=happy bash tests/dispatch-worker/test-dispatch-worker.sh`. Expected: the fixture task call includes `task --background`, `turn-1-job.txt` exists before waiting, stdout contains only `TERMINAL completed <path-to-turn-1-response.json>`, and the response parses as JSON.
- Action: Run the malformed and killed fixture cases. Expected: malformed prose produces `TERMINAL malformed <path-to-turn-1-result-raw.txt>` with raw output preserved; killed produces `TERMINAL failed killed <reason>`.
- Action: Run the active fixture case. Expected: stdout is exactly a `PENDING <job-id>` line followed by a `RESUME node scripts/dispatch-worker.mjs --job <job-id> ...<same flags>` line, with exit 0.
- Action: Execute the printed `RESUME` command. Expected: it calls `status <job-id> --wait --timeout-ms 570000` and no `task` command.
- Action: Return fixture status `archived`. Expected: the wrapper treats it as terminal and emits `TERMINAL failed archived <reason>` rather than polling again.
- Action: Inspect every fixture process status. Expected: every `TERMINAL` and `PENDING` case exits 0.

## US-3: Haiku forwarder subagent

### Task 3: Define the four-line haiku forwarder

**Depends on:** Task 2

**Files:**
- Modify: `tests/dispatch-worker/test-dispatch-worker.sh`
- Modify: `skills/dispatch-agent/SKILL.md`
- Test: `tests/dispatch-worker/test-dispatch-worker.sh`

**Interfaces:**
- Consumes: one literal `COMMAND:` string built by the orchestrator; wrapper stdout beginning with `TERMINAL` or `PENDING`; the next-line `RESUME` command.
- Produces: the `TERMINAL` line verbatim; no composed flags, file reads, summaries, or commands other than the literal command and printed `RESUME`.

**task_type:** implementation_coding

- [ ] **Step 1: Add the failing forwarder contract checks**

Insert these complete checks before the final `echo` in `tests/dispatch-worker/test-dispatch-worker.sh`:

```bash
check 'Step 4c: Invoke the haiku forwarder'
check 'Run the command given below. Then:'
check 'Output begins TERMINAL -> return that line verbatim. Stop.'
check 'Output begins PENDING  -> run the RESUME command printed beneath it. Repeat.'
check 'Return nothing else. Do not read files, summarize, or run any other command.'
check 'COMMAND:'
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 1 with `FAIL: missing skill contract: Step 4c: Invoke the haiku forwarder`.

- [ ] **Step 3: Add the exact forwarder definition**

Insert this exact block in the rescue-dispatch portion of Step 4 in `skills/dispatch-agent/SKILL.md`:

```markdown
### Step 4c: Invoke the haiku forwarder

Spawn an Agent with `model: haiku` and give it only this instruction, replacing the final line with the literal command from Step 4b:

```text
Run the command given below. Then:
- Output begins TERMINAL -> return that line verbatim. Stop.
- Output begins PENDING  -> run the RESUME command printed beneath it. Repeat.
Return nothing else. Do not read files, summarize, or run any other command.

COMMAND:
<literal command string>
```
```

- [ ] **Step 4: Run the focused contract test**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 0 with `PASS test-dispatch-worker`, including all six exact haiku forwarder strings.

<!-- riso-tech:orchestrator-split START -->
**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/dispatch-worker/test-dispatch-worker.sh skills/dispatch-agent/SKILL.md
git commit -m "feat: add haiku dispatch forwarder"
```

The worker never runs these commands.
<!-- riso-tech:orchestrator-split END -->

**US-3 Checkpoint:**

- Action: Give haiku a literal wrapper command whose fixture returns `TERMINAL completed <path>`. Expected: haiku executes the command once, returns that line verbatim, and stops.
- Action: Give haiku a command whose first fixture result is `PENDING` plus `RESUME` and whose resumed result is `TERMINAL`. Expected: haiku executes only the literal command and printed `RESUME`, then returns the terminal line verbatim.
- Action: Audit the haiku transcript. Expected: there are no file reads, summaries, flag composition steps, or commands beyond the supplied command and printed resume command.
- Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`. Expected: `PASS test-dispatch-worker` confirms the four-line forwarder definition.

## US-4: Crash safety via turn-N-job.txt

### Task 4: Prove write-before-wait and document recovery

**Depends on:** Task 3

**Files:**
- Modify: `tests/dispatch-worker/test-dispatch-worker.sh`
- Modify: `skills/dispatch-agent/SKILL.md`
- Test: `tests/dispatch-worker/test-dispatch-worker.sh`

**Interfaces:**
- Consumes: the spawned job id; `.superpowers/<task>/turn-N-job.txt`; original provider, plugin root, request, prompt, model, effort, optional profile, and optional wall-clock flags.
- Produces: a job-id file written before `status --wait`; recovery command `node scripts/dispatch-worker.mjs --job $(cat turn-N-job.txt) ...<same flags>`; no replacement task spawn.

**task_type:** implementation_coding

- [ ] **Step 1: Add the failing write-order and recovery checks**

Extend the fake companion's imports and `status` branch in `tests/dispatch-worker/test-dispatch-worker.sh` with this complete code:

```javascript
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
  const status = mode === "long" ? "running" : mode === "killed" ? "killed" : mode === "future" ? "archived" : "completed";
  console.log(JSON.stringify({id: "task-fixture-1", status, phase: status}));
} else if (command === "result") {
  if (process.env.FAKE_CASE === "malformed") console.log("worker returned prose");
  else console.log('worker prose\n```json\n{"message_type":"deliver","output":{"status":"done"}}\n```');
}
```

Insert these complete checks before the final `echo`:

```bash
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: the write-order fixture passes, then the test exits 1 with `FAIL: missing skill contract: node scripts/dispatch-worker.mjs --job $(cat turn-N-job.txt) ...<same flags>`.

- [ ] **Step 3: Add the recovery rule**

Add this exact paragraph to the new Step 5 receive instructions in `skills/dispatch-agent/SKILL.md`:

```markdown
If haiku returns no `TERMINAL` line, read `.superpowers/<task>/turn-N-job.txt` and recover with `node scripts/dispatch-worker.mjs --job $(cat turn-N-job.txt) ...<same flags>`. Reuse every original flag and do not spawn a replacement job.
```

- [ ] **Step 4: Run the focused contract test**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 0 with `PASS test-dispatch-worker`; the fake status command observes `turn-1-job.txt` before wait and the skill contains the exact recovery action.

<!-- riso-tech:orchestrator-split START -->
**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/dispatch-worker/test-dispatch-worker.sh skills/dispatch-agent/SKILL.md
git commit -m "feat: preserve dispatch jobs across crashes"
```

The worker never runs these commands.
<!-- riso-tech:orchestrator-split END -->

**US-4 Checkpoint:**

- Action: Run the fake companion with `FAKE_JOB_FILE` pointing at `turn-1-job.txt`. Expected: the status command finds the file before its first wait and the file contains the spawned job id.
- Action: Interrupt the forwarder after the job file appears, then run `node scripts/dispatch-worker.mjs --job $(cat turn-N-job.txt) ...<same flags>`. Expected: the wrapper skips `task --background`, resumes `status --wait`, and preserves the running job.
- Action: Simulate haiku returning without a `TERMINAL` line. Expected: Step 5 reads `turn-N-job.txt`, invokes the same `--job` recovery command, and does not create a replacement job.

## US-5: Script-bounded PENDING loop

### Task 5: Add the wall-clock ceiling

**Depends on:** Task 4

**Files:**
- Modify: `scripts/dispatch-worker.mjs`
- Modify: `tests/dispatch-worker/test-dispatch-worker.sh`
- Test: `tests/dispatch-worker/test-dispatch-worker.sh`

**Interfaces:**
- Consumes: optional `--max-wall-ms <positive integer>`; active status `queued|running`; the job state's `createdAt`.
- Produces: `TERMINAL failed timeout <job-id>` when `Date.now() - Date.parse(createdAt) >= maxWallMs`; otherwise the existing `PENDING` plus `RESUME`, with the same `--max-wall-ms` preserved.

**task_type:** implementation_coding

- [ ] **Step 1: Add the failing runaway cases**

Replace the fake companion's status selection with this complete block:

```javascript
const mode = process.env.FAKE_CASE;
const status =
  mode === "long" || mode === "runaway" ? "running" :
  mode === "killed" ? "killed" :
  mode === "future" ? "archived" :
  "completed";
const createdAt = mode === "runaway" ? "1970-01-01T00:00:00.000Z" : new Date().toISOString();
console.log(JSON.stringify({id: "task-fixture-1", status, phase: status, createdAt}));
```

Insert these complete checks before the final `echo`:

```bash
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 1 with runaway output beginning `PENDING task-fixture-1` instead of `TERMINAL failed timeout task-fixture-1`.

- [ ] **Step 3: Add the bounded active-state logic**

In `scripts/dispatch-worker.mjs`, add this constant and helper:

```javascript
const DEFAULT_MAX_WALL_MS = 60 * 60 * 1000;

function maxWallMs(values) {
  if (values["max-wall-ms"] === undefined) return DEFAULT_MAX_WALL_MS;
  const parsed = Number(values["max-wall-ms"]);
  if (!Number.isInteger(parsed) || parsed <= 0) throw new Error("--max-wall-ms must be a positive integer");
  return parsed;
}
```

Replace `resumeLine` with this complete function:

```javascript
function resumeLine(values, jobId) {
  const flags = [
    "--provider", values.provider,
    "--plugin-root", values["plugin-root"],
    "--request", values.request,
    "--prompt", values.prompt,
    "--model", values.model,
    "--effort", values.effort,
  ];
  if (values.profile) flags.push("--profile", values.profile);
  if (values["max-wall-ms"]) flags.push("--max-wall-ms", values["max-wall-ms"]);
  return `RESUME node scripts/dispatch-worker.mjs --job ${shellQuote(jobId)} ${flags.map(shellQuote).join(" ")}`;
}
```

Replace the active-status branch with this complete branch:

```javascript
if (ACTIVE.has(state.status)) {
  const createdAt = Date.parse(state.createdAt);
  if (Number.isFinite(createdAt) && Date.now() - createdAt >= maxWallMs(values)) {
    console.log(`TERMINAL failed timeout ${jobId}`);
    return;
  }
  console.log(`PENDING ${jobId}\n${resumeLine(values, jobId)}`);
  return;
}
```

- [ ] **Step 4: Run the wrapper contract test**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 0 with `PASS test-dispatch-worker`; the old active job emits `TERMINAL failed timeout task-fixture-1`, the recent active job emits `PENDING`, and its `RESUME` line preserves `--max-wall-ms 3600000`.

<!-- riso-tech:orchestrator-split START -->
**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add scripts/dispatch-worker.mjs tests/dispatch-worker/test-dispatch-worker.sh
git commit -m "feat: bound dispatch worker wait time"
```

The worker never runs these commands.
<!-- riso-tech:orchestrator-split END -->

**US-5 Checkpoint:**

- Action: Resume an active fixture whose `createdAt` is recent. Expected: the wrapper compares elapsed wall time to 60 minutes and emits `PENDING` plus `RESUME`.
- Action: Resume an active fixture whose `createdAt` is more than 60 minutes old. Expected: stdout is `TERMINAL failed timeout <job-id>` and contains no second `PENDING`.
- Action: Invoke the old active fixture with `--max-wall-ms 1`. Expected: the override is used and stdout is `TERMINAL failed timeout <job-id>`.
- Action: Invoke a recent active fixture with `--max-wall-ms 3600000`. Expected: stdout remains `PENDING` plus a `RESUME` command containing the same `--max-wall-ms 3600000`.

## US-6: Dispatch-agent Steps 4–5 rewrite

### Task 6: Replace the forwarder send and receive path

**Depends on:** Task 1, Task 2, Task 3, Task 4, and Task 5

**Files:**
- Modify: `tests/dispatch-worker/test-dispatch-worker.sh`
- Modify: `skills/dispatch-agent/SKILL.md`
- Test: `tests/dispatch-worker/test-dispatch-worker.sh`
- Test: `tests/split/run-all.sh`

**Interfaces:**
- Consumes: Step 4a's cached rescue-doc data; `.superpowers/<task>/turn-N-request.json`; `.superpowers/<task>/turn-N-prompt.txt`; model, effort, optional profile, and wrapper flags; haiku's final `TERMINAL` line.
- Produces: Step 4b literal `node scripts/dispatch-worker.mjs ...` command; Step 4c haiku invocation; Step 5 response path passed unchanged to `node scripts/validate-message.mjs <path>`; no rescue, status, or result slash-command invocation.

**task_type:** implementation_coding

- [ ] **Step 1: Add the failing Steps 4–5 contract checks**

Insert this complete section extractor, function, and calls before the final `echo` in `tests/dispatch-worker/test-dispatch-worker.sh`:

```bash
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
check_step '--request .superpowers/<task>/turn-N-request.json \'
check_step '--prompt .superpowers/<task>/turn-N-prompt.txt \'
check_step 'Step 5: Receive one terminal line'
check_step 'Pass that path unchanged to Step 6 validation.'
check_absent 'poll `/codex:status`'
check_absent 'run `/codex:result`'
check_absent 'poll `/antigravity:status'
check_absent 'run `/antigravity:result'
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 1 with `FAIL: missing send/receive contract: Step 4b: Build the literal command string`.

- [ ] **Step 3: Rewrite Steps 4–5 with the single observation path**

In `skills/dispatch-agent/SKILL.md`, replace the existing Steps 4–5 rescue send/receive text with this exact block, leaving the Codex foreground review/security adapter intact:

````markdown
4. **Prepare and send** through one of the paths below.

### Step 4a: Read the provider rescue doc

For a Codex or Antigravity rescue dispatch, read `<plugin-root>/<provider>/<ver>/commands/rescue.md` before building the command. Extract the flag surface, effort enum, model aliases, plugin root, and profile policy. Cache this read once per provider per session.

Ignore the entire "Execution mode" section. It instructs the slash-command forwarder and must not determine whether the companion receives `--background`.

Validate the effort from `model-lookup.sh` against the provider doc: Codex accepts only `none|minimal|low|medium|high|xhigh`; Antigravity accepts only `low|medium|high`. Pass a resolved model alias verbatim, and pass `--profile` only when an existing profile was explicitly selected; never invent a profile.

### Step 4b: Build the literal command string

For Codex or Antigravity rescue work, write the filled rescue contract plus the unchanged request envelope to `.superpowers/<task>/turn-N-prompt.txt`, then build:

```text
node scripts/dispatch-worker.mjs \
  --provider <codex|antigravity> \
  --plugin-root <plugin-root> \
  --request .superpowers/<task>/turn-N-request.json \
  --prompt .superpowers/<task>/turn-N-prompt.txt \
  --model <model> \
  --effort <effort> \
  [--profile <existing-profile>]
```

Do not invoke `/codex:rescue` or `/antigravity:rescue`; those commands re-enter the forwarder path being replaced.

For a claude worker, use the Agent tool with `permissionMode: bypassPermissions`, prompt = `"ROLE: subagent\n" + <request JSON> + "\nFinish by returning TERMINAL <status> <path-to-turn-N-response.json>."`. The request contract remains the authority boundary.

Codex `code_review_quality` and `security_review` remain foreground commands with their existing review-output adapter; they do not use the rescue wrapper.

### Step 4c: Invoke the haiku forwarder

For the literal Codex or Antigravity rescue command, spawn an Agent with `model: haiku` and give it only:

```text
Run the command given below. Then:
- Output begins TERMINAL -> return that line verbatim. Stop.
- Output begins PENDING  -> run the RESUME command printed beneath it. Repeat.
Return nothing else. Do not read files, summarize, or run any other command.

COMMAND:
<literal command string>
```

5. **Receive one terminal line.**

For Codex, Antigravity, and claude worker results, require `TERMINAL <status> <path>`. Read the embedded path from that line. Pass that path unchanged to Step 6 validation.

`TERMINAL malformed <path-to-turn-N-result-raw.txt>` reissues once to the same provider with a format reminder; a second malformed result becomes `blocked`. `TERMINAL failed <status> <reason>` follows the existing degradation ladder.

If haiku returns no `TERMINAL` line, read `.superpowers/<task>/turn-N-job.txt` and recover with `node scripts/dispatch-worker.mjs --job $(cat turn-N-job.txt) ...<same flags>`. Reuse every original flag and do not spawn a replacement job.
````

- [ ] **Step 4: Run focused and marker verification**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh && bash tests/split/run-all.sh`

Expected: the focused test prints `PASS test-dispatch-worker`, the aggregate suite prints `ALL ORCHESTRATOR SPLIT TESTS PASS`, and both commands exit 0.

<!-- riso-tech:orchestrator-split START -->
**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/dispatch-worker/test-dispatch-worker.sh skills/dispatch-agent/SKILL.md
git commit -m "feat: use one dispatch observation path"
```

The worker never runs these commands.
<!-- riso-tech:orchestrator-split END -->

**US-6 Checkpoint:**

- Action: Follow updated Step 4. Expected: it executes 4a rescue-doc read/cache, 4b literal wrapper command construction, and 4c haiku invocation in that order.
- Action: Inspect Step 4a during Codex and Antigravity rescue work. Expected: it reads `<plugin-root>/<provider>/<ver>/commands/rescue.md` and never invokes `/codex:rescue` or `/antigravity:rescue`.
- Action: Return `TERMINAL completed .superpowers/<task>/turn-N-response.json` from haiku. Expected: Step 5 reads that path and passes it unchanged to Step 6, with no `/codex:status`, `/antigravity:status`, `/codex:result`, or `/antigravity:result` call.
- Run: `bash tests/split/run-all.sh`. Expected: `ALL ORCHESTRATOR SPLIT TESTS PASS` with no marker modification required.

## US-7: Claude worker TERMINAL alignment

### Task 7: Align Claude final output with the terminal contract

**Depends on:** Task 6

**Files:**
- Modify: `tests/dispatch-worker/test-dispatch-worker.sh`
- Modify: `skills/dispatch-agent/SKILL.md`
- Test: `tests/dispatch-worker/test-dispatch-worker.sh`

**Interfaces:**
- Consumes: the existing Claude Agent prompt and `superpowers-worker:report-task` output at `.superpowers/<task>/turn-N-response.json`.
- Produces: final worker output `TERMINAL completed .superpowers/<task>/turn-N-response.json`; the same Step 5 path extraction and Step 6 validation used by wrapped providers.

**task_type:** implementation_coding

- [ ] **Step 1: Add the failing Claude alignment check**

Insert this complete check before the final `echo` in `tests/dispatch-worker/test-dispatch-worker.sh`:

```bash
check 'Finish by returning `TERMINAL <status> <path-to-turn-N-response.json>`.'
check 'TERMINAL completed .superpowers/<task>/turn-N-response.json'
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `bash tests/dispatch-worker/test-dispatch-worker.sh`

Expected: exit 1 with `FAIL: missing skill contract: Finish by returning \`TERMINAL <status> <path-to-turn-N-response.json>\`.`.

- [ ] **Step 3: Add the single Claude prompt line**

In the Claude dispatch paragraph of `skills/dispatch-agent/SKILL.md`, place this exact sentence after the Agent prompt construction:

```markdown
Finish by returning `TERMINAL <status> <path-to-turn-N-response.json>`. After `superpowers-worker:report-task` writes the response, successful Claude output is `TERMINAL completed .superpowers/<task>/turn-N-response.json`.
```

- [ ] **Step 4: Run all dispatch and marker checks**

Run: `bash tests/dispatch-worker/run-tests.sh && bash tests/split/run-all.sh`

Expected: the dispatch suite ends with `PASS test-dispatch-worker` and `=== All dispatch-worker tests passed ===`, the split suite prints `ALL ORCHESTRATOR SPLIT TESTS PASS`, and both commands exit 0.

<!-- riso-tech:orchestrator-split START -->
**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/dispatch-worker/test-dispatch-worker.sh skills/dispatch-agent/SKILL.md
git commit -m "feat: align claude terminal output"
```

The worker never runs these commands.
<!-- riso-tech:orchestrator-split END -->

**US-7 Checkpoint:**

- Action: Dispatch a Claude worker with the updated prompt. Expected: the prompt includes exactly one additional requirement to finish with `TERMINAL <status> <path-to-turn-N-response.json>`.
- Action: Let `superpowers-worker:report-task` write the successful response. Expected: the worker's final output is `TERMINAL completed .superpowers/<task>/turn-N-response.json`.
- Action: Feed that line to Step 5. Expected: Step 5 extracts the response path and passes it unchanged to Step 6 validation, using the same receive logic as Codex and Antigravity.
