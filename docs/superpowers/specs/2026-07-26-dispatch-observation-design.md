---
title: Single Observation Path for Worker Dispatch
date: 2026-07-26
status: draft
---

# Single Observation Path for Worker Dispatch — Design Spec

## 1. Overview

The orchestrator dispatches workers to Codex and Antigravity through slash-command forwarders that return a queued job-id in approximately 15 seconds and immediately fire a `<task-notification>` with `status: completed`. That notification is a false done: the worker has barely started. An orchestrator that treats it as completion proceeds with no result. This spec defines a single, reliable observation path — a wrapper script plus a thin haiku forwarder subagent — that gives the orchestrator exactly one signal per dispatch: a `TERMINAL` line printed when the job reaches a definitive state, with the response file path embedded in it.

## 2. Context & Assumptions

The orchestrator dispatches Codex and Antigravity workers through `/codex:rescue` and `/antigravity:rescue` slash-command forwarders. Both forwarders run one Bash call with `--background` and return a queued job-id in approximately 15 seconds; the harness fires `status: completed` at that moment. The actual job takes significantly longer: on a live probe (task `probe-antigravity-wait`, ledger line 37), the forwarder returned at 14.9 seconds while the real job completed at 1 minute 6 seconds — approximately 80% of the wait is invisible to the orchestrator.

Both providers expose an identical CLI — `task [--background]`, `status [job-id] [--wait] [--timeout-ms <ms>]`, `result [job-id]`, `cancel [job-id]` — confirmed by reading the installed plugins at `~/.agents/cc-tu/plugins/cache/worker-plugin-cc/{codex,antigravity}/3.0.2/`. One wrapper script covers both providers.

Assumptions:

- The wait poll interval is 2000 ms; the default wait timeout is 240000 ms (`DEFAULT_STATUS_POLL_INTERVAL_MS` / `DEFAULT_STATUS_WAIT_TIMEOUT_MS`, codex-companion.mjs:71–72, antigravity-companion.mjs:56–57). The earliest observable state flip is therefore ≤2 s after a job changes.
- The Claude Code Bash tool caps at 600 s, so a job longer than approximately 9 minutes cannot be covered by a single blocking wait. The wait must be resumable.
- Job state lives at `~/.agents/cc-tu/plugins/data/codex-worker-plugin-cc/state/<workspace-hash>/jobs/<job-id>.json` with fields `id, status, phase, sessionId, workspaceRoot, result.output`. `isActiveJobStatus` = `queued|running`; everything else is terminal.
- The concurrent-task guard ("Task X is still running") is reached only on the `--resume` path (antigravity-companion.mjs:353). Dispatch-agent already mandates `--fresh`, so parallel dispatch is unaffected.
- `/codex:status`, `/codex:result`, `/antigravity:status`, `/antigravity:result` are all `disable-model-invocation: true`; the orchestrator cannot invoke them directly. Existing skill text and `docs/orchestrator-workflow.md:292` describe the receive path as those slash commands — that phrasing is aspirational, not executable. This design supersedes it.
- The human partner's stated goal is isolation, not token cost: worker execution must happen inside a Claude subagent, not in the orchestrator's main thread. Token cost of haiku is explicitly accepted.
- Claude workers already satisfy the observation contract via `superpowers-worker:report-task` writing `turn-N-response.json`. This design adds one line to their dispatch prompt; no other change to the claude worker path is required.

## 3. Scope

### Goals

- Replace the `/codex:rescue` and `/antigravity:rescue` forwarder path with a wrapper script (`scripts/dispatch-worker.mjs`) that spawns the companion, waits for job completion, and prints exactly one `TERMINAL` or `PENDING` line.
- Introduce a thin haiku forwarder subagent whose sole instruction is to run the script and, if it prints `PENDING`, re-run the `RESUME` command printed beneath it.
- Rewrite dispatch-agent Steps 4–5: Step 4 gains sub-steps 4a (read the provider's rescue doc), 4b (build the literal command string), and 4c (invoke the haiku subagent); Step 5's receive collapses to reading the path in the `TERMINAL` line.
- Write `turn-N-job.txt` immediately after the companion returns a job-id, before any waiting, so that a crash or killed session can recover by re-running with `--job <id>`.
- Bound the PENDING loop in the script — not in haiku's judgment — by comparing elapsed wall-clock time against a configurable maximum (default 60 minutes); emit `TERMINAL failed timeout <job-id>` when exceeded.
- Align the claude worker path: add one line to the claude dispatch prompt so it finishes by returning `TERMINAL <status> <path>`, making the orchestrator's receive logic identical across all three providers.

### Non-Goals

- Rewriting `commands/rescue.md` in the codex or antigravity plugins. The stale "Execution mode" section is documented here and worked around, not fixed; those plugins are separate repositories.
- Any change to the routing table, `model-lookup.sh`, or the degradation ladder.
- Replacing the claude worker path, which already satisfies the contract with a one-line addition.
- Modifying the provider readiness preflight (`/codex:setup`, `/antigravity:setup`), which is unchanged.
- Building a persistent poll loop or a second observation mechanism alongside the subagent notification.

## 4. User Stories

### US-1: Pre-dispatch rescue-doc read (Priority: P1)

As an orchestrator preparing to dispatch a Codex or Antigravity worker, I want to read the provider's rescue doc before building the command string, so that I use the correct flag surface, effort enum, model aliases, plugin root, and profile policy for that provider.

**Acceptance criteria:**

- GIVEN a dispatch to Codex or Antigravity is being prepared WHEN the orchestrator reaches Step 4a THEN it reads `<plugin-root>/<provider>/<ver>/commands/rescue.md` and extracts the flag surface, effort enum, model aliases, plugin root, and profile policy.
- GIVEN the rescue doc has been read for a provider in the current session WHEN another dispatch to the same provider is prepared THEN the cached read is used without re-reading the file.
- GIVEN the rescue doc contains an "Execution mode" section WHEN the orchestrator processes the doc THEN it ignores that section entirely and does not forward `--background` based on its guidance.
- GIVEN Codex is the target provider WHEN the effort string from `model-lookup.sh` is checked against the doc THEN only `none|minimal|low|medium|high|xhigh` are treated as legal values.
- GIVEN Antigravity is the target provider WHEN the effort string is checked THEN only `low|medium|high` are treated as legal values.

### US-2: dispatch-worker.mjs wrapper and stdout contract (Priority: P1)

As an orchestrator running a Codex or Antigravity dispatch, I want a Node.js wrapper script to own the spawn-wait-classify-extract cycle and print exactly one structured line, so that haiku never composes flags or parses JSON and the orchestrator's receive logic is deterministic.

**Acceptance criteria:**

- GIVEN a valid request file, prompt file, provider, plugin root, model, and effort WHEN the script is invoked THEN it spawns the companion with `task --background`, captures the job-id, and writes `turn-N-job.txt` before initiating any wait.
- GIVEN the job reaches a terminal state within the Bash tool's 600 s cap WHEN the script's wait completes THEN it prints exactly one line beginning `TERMINAL completed <path-to-turn-N-response.json>`, `TERMINAL malformed <path-to-turn-N-result-raw.txt>`, or `TERMINAL failed <status> <reason>`, and exits 0.
- GIVEN the job is still active when the `--timeout-ms 570000` wait expires WHEN the script evaluates the result THEN it prints `PENDING <job-id>` followed by `RESUME node scripts/dispatch-worker.mjs --job <job-id> ...<same flags>` and exits 0.
- GIVEN the script exits with `TERMINAL` or `PENDING` WHEN the exit code is checked THEN it is always 0, because a non-zero exit surfaces to haiku as a tool error and invites improvisation.
- GIVEN a `--job <job-id>` flag is passed WHEN the script starts THEN it skips the `task --background` spawn and goes directly to `status --wait` using the provided job-id.
- GIVEN the companion returns a status not in `queued|running` WHEN the script classifies the result THEN it treats it as terminal, so that a future status added by a plugin version is never polled forever.

### US-3: Haiku forwarder subagent (Priority: P1)

As an orchestrator that must keep worker execution isolated from its main thread, I want a thin haiku subagent with a four-line instruction set, so that it executes the given command and repeats on `PENDING` without composing any flags or reading any files.

**Acceptance criteria:**

- GIVEN a literal command string is provided to the haiku subagent WHEN the subagent runs THEN it executes that command using its Bash tool and returns immediately.
- GIVEN the script output begins with `TERMINAL` WHEN the haiku subagent reads the output THEN it returns that line verbatim to the orchestrator and stops.
- GIVEN the script output begins with `PENDING` WHEN the haiku subagent reads the output THEN it runs the `RESUME` command printed on the next line and repeats the check.
- GIVEN any script output WHEN the haiku subagent processes it THEN it does not read files, summarize content, or run any other command beyond those specified.

### US-4: Crash safety via turn-N-job.txt (Priority: P1)

As an orchestrator running a long-lived dispatch, I want the job-id written to disk immediately after spawn and before any waiting, so that a killed haiku session, a dead orchestrator, or a resumed conversation never loses a running job.

**Acceptance criteria:**

- GIVEN the companion returns a job-id from `task --background` WHEN the script records it THEN `turn-N-job.txt` is written to `.superpowers/<task>/` before the first `status --wait` call begins.
- GIVEN a session is killed or interrupted after job-id is written WHEN the orchestrator or a human resumes THEN recovery is `node scripts/dispatch-worker.mjs --job $(cat turn-N-job.txt) ...<same flags>` with no job loss.
- GIVEN haiku dies without printing a `TERMINAL` line WHEN the orchestrator detects the missing line THEN it reads `turn-N-job.txt` and re-runs with `--job`, preserving the running job.

### US-5: Script-bounded PENDING loop (Priority: P1)

As an orchestrator that cannot rely on haiku's judgment to decide when to give up, I want the script to enforce a maximum wall-clock limit before emitting `TERMINAL failed timeout`, so that a runaway job never loops haiku until the session dies.

**Acceptance criteria:**

- GIVEN the script has emitted `PENDING` and haiku has issued the `RESUME` command WHEN the resumed script checks the job and finds it still `queued|running` THEN it compares elapsed wall-clock time from the job's `createdAt` against the maximum (default 60 minutes).
- GIVEN elapsed time exceeds the maximum WHEN the script evaluates the result THEN it emits `TERMINAL failed timeout <job-id>` instead of another `PENDING`.
- GIVEN the maximum is not exceeded WHEN the job is still active THEN the script emits `PENDING` and `RESUME` as normal.
- GIVEN the `--max-wall-ms` flag is passed WHEN the script starts THEN it uses that value instead of the 60-minute default.

### US-6: Dispatch-agent Steps 4–5 rewrite (Priority: P1)

As an orchestrator following the dispatch-agent skill, I want Steps 4 and 5 updated to reflect the new path — with 4a/4b/4c sub-steps and a collapsed receive — so that the skill text matches the executable behavior and no agent re-enters the old forwarder path.

**Acceptance criteria:**

- GIVEN the updated dispatch-agent skill WHEN Step 4 is reached THEN it specifies three sequential sub-steps: 4a (read rescue doc, cache per provider), 4b (build the literal command string), and 4c (invoke haiku with the script command).
- GIVEN Step 4a WHEN the orchestrator executes it THEN it reads `<plugin-root>/<provider>/<ver>/commands/rescue.md` and never invokes `/codex:rescue` or `/antigravity:rescue`, which would re-enter the forwarder path being replaced.
- GIVEN the updated Step 5 receive WHEN haiku returns its `TERMINAL` line THEN the orchestrator reads the file path from that line and passes it to Step 6 validation, with no `/codex:status`, `/antigravity:status`, `/codex:result`, or `/antigravity:result` call.
- GIVEN the updated skill WHEN the `riso-tech:orchestrator-split` markers are checked THEN the `tests/split/` suite passes without modification.

### US-7: Claude worker TERMINAL alignment (Priority: P2)

As an orchestrator receiving results from claude workers, I want the receive logic to be identical across all three providers (Codex, Antigravity, claude), so that one observation path handles every dispatch and the skill has no provider-specific receive branches.

**Acceptance criteria:**

- GIVEN a claude worker dispatch WHEN the dispatch prompt is updated THEN it includes one additional line: finish by returning `TERMINAL <status> <path-to-turn-N-response.json>`.
- GIVEN a claude worker that has written `turn-N-response.json` via `superpowers-worker:report-task` WHEN it finishes THEN it prints `TERMINAL completed .superpowers/<task>/turn-N-response.json` as its final output.
- GIVEN the orchestrator's Step 5 receive WHEN applied to a claude worker result THEN it reads the `TERMINAL` line and passes the embedded path to Step 6 validation — the same logic used for Codex and Antigravity.

## 5. Approach

The chosen approach is **A — wrapper script plus a thin haiku forwarder subagent**. The human partner's stated goal is isolation, not token cost: worker execution must happen inside a Claude subagent rather than in the orchestrator's main thread. Token cost of haiku is explicitly accepted.

Division of responsibility is strict: the orchestrator owns *what* to run (reads the provider's rescue doc, resolves flags, writes the request and prompt files, builds one literal command string); the script owns *how* to run it (spawn, wait, classify, extract, persist); and haiku owns *nothing* — it executes a given string and follows a printed follow-up command. That split is what makes haiku viable in this slot.

### Alternatives considered

| Option | Why rejected |
|--------|--------------|
| B — haiku returns the full `result` payload verbatim; orchestrator writes the response file | The entire worker output transits haiku's return into the orchestrator's main context, undoing the isolation that is the whole point. |
| C — no wrapper script; haiku composes the three companion calls from instructions | Haiku improvising `--background` / `--timeout-ms` / job-id handling is precisely the failure mode; a wrong bridge flag is what the `worker-healing` skill already exists to clean up. |
| Main-thread `Bash run_in_background` instead of a subagent (~0 tokens) | Cheapest, but runs the worker in the orchestrator's own thread. Explicitly rejected by the human partner: the point is that the worker runs in a subagent. |
| Persistent `Monitor` poll loop over the shared job-state dir | Would be a second observation mechanism alongside the subagent notification. The requirement is exactly one way to observe. |

## 6. Design

### Architecture

Dispatch-agent Step 4 gains three sub-steps. The orchestrator drives 4a and 4b; haiku drives 4c via the script:

```
◆ DISPATCH-AGENT step 4
│
├─ 4a. ○ Read <plugin-root>/<provider>/<ver>/commands/rescue.md
│       extract: flag surface, effort enum, model aliases,
│                plugin root, profile policy
│       ignore:  the "Execution mode" section
│       cache:   once per provider per session
│
├─ 4b. ○ Build the literal command string
│
└─ 4c. ◆ Agent(model: haiku) — one literal command, four-line instruction
        │
        └─ scripts/dispatch-worker.mjs
             task --background        -> job-id  (persist immediately)
             status <id> --wait --timeout-ms 570000
             result <id> -> turn-N-response.json
             print TERMINAL <...>  |  PENDING <id> + RESUME <cmd>
```

Sub-step 4a is a read, never an invoke. Invoking `/codex:rescue` or `/antigravity:rescue` re-enters the forwarder path being replaced.

### Components & Interfaces

**New — `scripts/dispatch-worker.mjs`** (Node.js, matching the existing `scripts/validate-message.mjs`; extracting a JSON envelope out of `result` stdout is Node work):

```
node scripts/dispatch-worker.mjs \
  --provider    <codex|antigravity> \
  --plugin-root <path resolved in step 4a> \
  --request     .superpowers/<task>/turn-<N>-request.json \
  --prompt      .superpowers/<task>/turn-<N>-prompt.txt \
  --model <model> --effort <effort> [--profile <name>] \
  [--job <job-id>]        # resume leg only
```

The orchestrator writes `turn-N-prompt.txt` (rescue contract + envelope) because persona / discipline / work-contract selection is protocol-owned by `codex-worker-protocol.md`. The script never picks a contract; it reads that file verbatim.

Stdout contract — exactly one of three forms, always exit 0:

```
TERMINAL completed  .superpowers/<task>/turn-<N>-response.json
TERMINAL malformed  .superpowers/<task>/turn-<N>-result-raw.txt
TERMINAL failed     <status> <reason>

PENDING <job-id>
RESUME  node scripts/dispatch-worker.mjs --job <job-id> ...<same flags>
```

`--plugin-root` doubles as the test seam: pointing it at a fixture directory holding a scripted fake `scripts/<provider>-companion.mjs` gives full state-machine coverage with no `agy` or `codex` installed.

**New — haiku forwarder subagent.** Its entire instruction:

```
Run the command given below. Then:
- Output begins TERMINAL -> return that line verbatim. Stop.
- Output begins PENDING  -> run the RESUME command printed beneath it. Repeat.
Return nothing else. Do not read files, summarize, or run any other command.

COMMAND:
<literal string built in step 4b>
```

**Changed — `dispatch-agent` Steps 4–5.** Step 4 gains 4a/4b/4c. Step 5's receive collapses: no `/codex:status`, no `/antigravity:status`, no `/codex:result`, no `/antigravity:result`, no orchestrator poll loop. Receive becomes "read the path in the `TERMINAL` line, then Step 6 validate as today."

**Aligned — claude workers.** No wrapper; the worker is the subagent, and `superpowers-worker:report-task` already writes `turn-N-response.json`. One line added to the claude dispatch prompt: finish by returning `TERMINAL <status> <path>`. The orchestrator's receive logic is then identical across all three providers.

### Data Model & Flow

Files written per dispatch turn:

```
.superpowers/<task>/
  turn-N-request.json      orchestrator writes  (protocol envelope)
  turn-N-prompt.txt        orchestrator writes  (rescue contract + envelope)
  turn-N-job.txt           script writes        (job-id, immediately after spawn)
  turn-N-response.json     script writes        (extracted envelope)
  turn-N-result-raw.txt    script writes        (malformed case only)
```

`turn-N-job.txt` is the crash-safety anchor, written the instant the companion returns a job-id and before any waiting. Same principle the protocol already uses for turn numbers: state lives in the folder, so a dead haiku, a killed session, or a resumed conversation never loses a running job. Recovery is `--job $(cat turn-N-job.txt)`.

### Error Handling

| Script says | Meaning | Existing path |
|-------------|---------|---------------|
| `TERMINAL completed` | envelope extracted | Step 6 validate → 7 ledger → 8 route |
| `TERMINAL malformed` | worker returned prose | reissue once with format reminder; second failure → `blocked` |
| `TERMINAL failed` | bridge failure | degradation ladder: walk `recommended_models[]` to next ready agent |
| *no TERMINAL line* | haiku died | read `turn-N-job.txt`, re-run with `--job`; work is not lost |

The `failed` / `malformed` split matters. A killed job is a bridge failure and must walk the ladder; prose-instead-of-JSON is a worker failure and must reissue to the same provider. Collapsing them either burns the ladder on a formatting slip or retries a dead bridge.

Provider readiness preflight is unchanged: `/codex:setup` and `/antigravity:setup` still run before the first dispatch per provider per session, and a not-ready provider still degrades before any of this runs.

### Edge Cases

- **PENDING loop bounded by the script:** The script compares elapsed wall-clock time against the job's `createdAt`; past a maximum (default 60 minutes, flag-overridable via `--max-wall-ms`) it emits `TERMINAL failed timeout <job-id>` instead of another `PENDING`. Haiku cannot loop forever because it is never handed a `PENDING` it could loop on.
- **Codex effort enum vs. Antigravity effort enum:** Codex accepts `none|minimal|low|medium|high|xhigh`; Antigravity accepts `low|medium|high`. The effort string from `model-lookup.sh` is validated against the provider's own rescue doc (step 4a). Only the provider's doc is authoritative; the script does not hardcode enums.
- **Codex-only model alias:** `spark` resolves to `gpt-5.3-codex-spark` per the Codex rescue doc. The orchestrator reads this mapping in step 4a; the script passes the resolved model name verbatim.
- **`--profile` flag:** Pins an account from `~/.agents/profiles.json`. The script passes it through when provided; it never invents a profile name.
- **Bash 600 s cap:** `--timeout-ms 570000` (570 s) leaves a 30 s margin before the Bash tool's hard cap. The job-id is already in `turn-N-job.txt`, so the script can emit `PENDING` safely within the cap.
- **`riso-tech:orchestrator-split` markers:** Steps 4–5 of `dispatch-agent/SKILL.md` sit inside those markers. The `tests/split/` suite validates the markers; changing them without updating that test breaks the suite.
- **Parallel dispatch:** Because the concurrent-task guard is reached only on `--resume` and dispatch-agent mandates `--fresh`, multiple simultaneous dispatches to different providers are unaffected by this design.

## 7. Testing Strategy

The `--plugin-root` flag doubles as the test seam: pointing it at a fixture directory holding a scripted fake `scripts/<provider>-companion.mjs` gives full state-machine coverage with no `agy` or `codex` installed. That keeps the tests CI-safe, matching the rest of `tests/`.

The house pattern is plain bash with `set -euo pipefail`, a `fail()` helper, discovered by a `run-tests.sh` that loops `test-*.sh` (see `tests/antigravity/run-tests.sh` and `tests/antigravity/test-antigravity-tools.sh`).

**`tests/dispatch-worker/test-dispatch-worker.sh`** — six cases covering US-2, US-4, and US-5:

| Case | Stub emits | Expect |
|------|------------|--------|
| happy | prose + fenced JSON envelope | `TERMINAL completed`; `turn-N-response.json` parses |
| malformed | prose, no fenced JSON | `TERMINAL malformed`; raw preserved; no response.json |
| bridge death | `status: killed` | `TERMINAL failed` (→ ladder), *not* malformed |
| long job | `status: running` at wait timeout | `PENDING` plus a `RESUME` line that runs verbatim |
| runaway | `running`, `createdAt` past max | `TERMINAL failed timeout`, *not* another PENDING |
| crash safety | any | `turn-N-job.txt` exists before the first wait returns |

Cases 3 (bridge death) and 5 (runaway) are the two silent-failure modes that matter most: a killed job misclassified as malformed retries a dead bridge forever; a runaway that keeps emitting `PENDING` loops haiku until the session dies. Both look like "still running" from outside — the same shape as the original bug.

**US-1 (pre-dispatch read) verification:** Inspection of the updated `dispatch-agent/SKILL.md` confirms that step 4a specifies a file read, not an invocation of `/codex:rescue` or `/antigravity:rescue`.

**US-3 (haiku subagent) verification:** The four-line instruction is included verbatim in the dispatch-agent skill and reviewed to confirm it contains no flag-composition logic.

**US-6 (Steps 4–5 rewrite) verification:** The `tests/split/` suite is run after the skill edit to confirm `riso-tech:orchestrator-split` markers are intact.

**US-7 (claude TERMINAL alignment) verification:** The claude dispatch prompt diff is reviewed to confirm exactly one new line was added and that it uses the correct `TERMINAL <status> <path>` form.

**One live smoke test** (by hand, not in CI): re-dispatch the session's probe (`documentation_knowledge_transfer` → antigravity → the three-line `probe-note.md`) through the new path and confirm the orchestrator's only observation is a single `TERMINAL completed` line. Baseline for comparison: forwarder false-done at 14.9 s, real job completion at 1 m 06 s.

## 8. Success Criteria

- SC-1: After the changes ship, the orchestrator's only observation for a completed Codex or Antigravity job is a single `TERMINAL completed <path>` line; no `/codex:status`, `/antigravity:status`, `/codex:result`, or `/antigravity:result` call appears in the dispatch-agent execution trace.
- SC-2: `turn-N-job.txt` exists in `.superpowers/<task>/` before the companion's first `status --wait` call returns — observable in the file-write order logged by the script.
- SC-3: The live smoke test confirms the orchestrator receives `TERMINAL completed` after the real job duration, not at the 14.9 s false-done mark recorded during the probe on 2026-07-26 (ledger line 37, task `probe-antigravity-wait`; forwarder returned at 14.9 s, 17,082 tokens, output `Queued task-ms1c9f00-aw2pxw: Antigravity Task.`; actual completion at 1 m 06 s).
- SC-4: The `tests/dispatch-worker/test-dispatch-worker.sh` suite passes all six cases with no `agy` or `codex` installed, confirming CI-safe coverage via the `--plugin-root` test seam.
- SC-5: A bridge-death stub (`status: killed`) produces `TERMINAL failed`, not `TERMINAL malformed`; a runaway stub (elapsed past max) produces `TERMINAL failed timeout`, not a second `PENDING` — both verified by the automated test cases 3 and 5.
- SC-6: The `tests/split/` suite passes after the `dispatch-agent/SKILL.md` edit, confirming `riso-tech:orchestrator-split` markers are intact.
- SC-7: A claude worker dispatch produces a `TERMINAL completed` line as its final output, and the orchestrator's Step 5 receive handles it with the same code path used for Codex and Antigravity.
