# Skill Pattern Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development when the harness supports subagents; use superpowers-orchestrator:executing-plans only when the harness has no subagent capability. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** `docs/superpowers/features/skill-pattern-migration/design.md`

**Goal:** Migrate all 18 in-scope workflow skills to the canonical 12-block pattern with recorded subagent pressure evidence and zero repository-wide structural violations.

**Architecture:** Each skill is an independent, ordered migration unit that reads only its own existing prose for derived content, records pressure-test evidence in the active run manifest and README, and lands as one orchestrator-owned commit. A shared Foundation defines the scenario contract, seven-step gate, derivation rules, and README format once; `using-superpowers` demonstrates the whole procedure before the remaining skills reuse it in `skills/SDLC.md` order.

**Tech Stack:** Markdown, Bash, grep, awk, `superpowers-orchestrator:dispatch-agent`

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- US-1: the migration executor can demonstrate the pressure-scenario protocol end to end on `using-superpowers` before any later skill proceeds.
- US-2: every in-scope skill follows the same seven-step migration unit and lands in its own SDLC-ordered commit.
- US-3: every migrated README records conditional omissions and distinguishes DERIVED content from `**NEW**` content with traceable evidence.
- US-4: every DERIVED migration has an honestly named no-regression A/B result proving `after >= baseline`.
- US-5: every `**NEW**` gap-fill has a true failing-baseline-to-passing-after RED-GREEN result, or the unnecessary guidance is dropped.
- US-6: all 18 skills have one realistic pressure scenario, split exactly into 9 adapted sources and 9 from-scratch scenarios, dispatched to fresh subagents for baseline and after runs.
- US-7: all 18 skills conform structurally, the skill suite passes, the split suite remains at exactly 17 pre-existing failures, and commit order matches `skills/SDLC.md`.

### Artifacts

- `skills/{using-superpowers,project-kickoff,brainstorming,designing-ui,writing-plans,requesting-plan-refine,receiving-plan-refine,using-git-worktrees,subagent-driven-development,executing-plans,requesting-code-review,finishing-a-development-branch,sprint-retrospective,writing-skills,backlog-refinement,dispatch-agent,dispatching-parallel-agents,worker-healing}/SKILL.md` — pattern-conformant workflow instructions.
- The matching 18 `README.md` files — ordered `## Pattern Omissions` and `## Pattern Migration Notes` evidence.
- `tests/split/test-project-kickoff.sh` — one casing assertion updated atomically with `project-kickoff`.
- `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json` and task response artifacts — durable scenario, baseline, after, gate, and validator progress.

### How to see it working

- Run `bash tests/skills/test-workflow-skill-pattern.sh --validate skills/writing-skills/workflow-skill-pattern.md .`; expect exit 0 and zero output repository-wide.
- Run `bash tests/skills/run-all.sh`; expect `PASS test-workflow-skill-pattern`, then `ALL SKILL TESTS PASS`, and exit 0.
- Run `bash tests/split/run-all.sh`; expect exactly 17 failures caused by the pre-existing missing `docs/orchestrator-workflow.md`, with no additional failure.

## Global Constraints

- One skill = one commit. Never batch two skills into a single commit.
- Derived content comes ONLY from that skill's own existing text. No
  requirement may be invented while claiming it was derived.
- Content that cannot be derived is NEW: it must be marked **NEW** in the
  README Migration Notes and must show a baseline that ACTUALLY FAILS the new
  criterion. If the baseline passes, the guidance was not needed — drop it.
- The eval gate is `after >= baseline`. A drop blocks the commit.
- skills/visual-companion/ is excluded from the pattern and from this plan.
- The validator must report zero violations for a skill before its commit.
- bash + grep + awk only for any tooling work; no new dependency.

- Do not run the `evals/` harness or any bun/quorum command; `evals/scenarios/*/story.md` is source prose only, because bun and tmux are unavailable.
- `bash tests/split/run-all.sh` has 17 pre-existing failures from missing `docs/orchestrator-workflow.md`; verification requires no NEW failures, not a green suite.
- Workers never commit or push. The orchestrator alone performs each task's Git bookkeeping after successful evidence and verification.

---

## Foundation

### Reusable pressure-scenario template

Every skill gets one realistic scenario. The executor either adapts the exact `story.md` path named in that skill's task or authors from scratch when the task says so. The scenario must combine at least three pressures from time, sunk cost, authority, exhaustion, economic, social, and pragmatic pressure; use concrete times, paths, and consequences; force an explicit A/B/C choice; and require action rather than a quiz response.

Every scenario opens exactly with:

```text
IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions - make the actual decision.

You have access to: [skill-being-tested]
```

Replace `[skill-being-tested]` with the exact skill name for the task. Dispatch baseline and after runs through `superpowers-orchestrator:dispatch-agent` to two different fresh subagents. The baseline uses the commit before the skill migration; the after run uses the migrated working tree. Capture the chosen option, criterion verdicts, and every rationalization verbatim.

The active run manifest entry uses the stable keys `scenario`, `source`, `baseline`, `after`, `gate`, and `validator` so progress survives compaction. `source` is either `scratch` or `adapted:` followed by the exact `story.md` path; all verdict and gate values are the observations from that task, never forecast values.

```text
scenario; source; baseline; after; gate; validator
```

The full prompt, dispatch request, response, and verbatim rationalizations remain in that task's `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/40-execution/tasks/` artifacts; the manifest carries the resumable summary. A partial skill with no commit restarts at baseline dispatch.

### Canonical seven-step per-skill migration procedure

1. **Scenario exists?** Check the task's named source. Author or adapt one scenario with the standard preamble, 3+ combined pressures, concrete constraints, and forced A/B/C action.
2. **Baseline dispatch.** Send the scenario to a fresh subagent through `superpowers-orchestrator:dispatch-agent` with the pre-migration skill active. Record the verdict and rationalizations verbatim.
3. **Migrate.** Derive the task's missing mandatory blocks from that skill's own existing text; add pressure-justified gap-fill only when derivation is impossible; assess every absent conditional block against its canonical omit-when rule; add `## Pattern Omissions` and `## Pattern Migration Notes`; normalize headings/casing; perform only the task's named special edit.
4. **After dispatch.** Send the unchanged scenario to a different fresh subagent with the migrated skill active and record the verdict.
5. **Gate.** Require `after >= baseline`. For each `**NEW**` criterion, require baseline FAIL and after PASS; if baseline passed, drop that guidance. Name DERIVED evidence a no-regression A/B, never RED-GREEN.
6. **Validator.** Run the canonical `--validate` command, retain the full output, set `skill_dir` to the task's exact directory name, and confirm the output contains zero lines whose first field equals `skills/$skill_dir:`. A remaining line blocks the skill.
7. **Commit.** After Steps 1–6 pass, the orchestrator commits exactly that skill's `SKILL.md` and `README.md`, plus only the task's explicitly named atomic companion file. Workers never run Git bookkeeping.

### Derivation, gating, and README rules

- `checklist`, `the-process`, and any `**NEW**` gap-fill are eval-gated.
- `purpose`, `key-principles`, README records, heading renames/casing, and pure reordering are structural-only unless their content introduces a requirement that cannot be traced to the skill's own prose.
- A DERIVED entry names the exact source section and adds no behavioral requirement. Its recorded verdict is `baseline → after` and its gate is a no-regression A/B.
- A `**NEW**` entry names the scenario and records `baseline FAIL → after PASS`. If the observed baseline is not FAIL for that criterion, remove the proposed content rather than manufacturing a failure.
- Conditional blocks are not added merely to satisfy rule3. Add one only when its omit-when condition is false and its content is derived or passes the `**NEW**` gate; otherwise record the truthful omission reason.

Each README ends with these sections in this order:

```markdown
## Pattern Omissions

- `hard-gate` — skill only reads and reports; no irreversible act.

## Pattern Migration Notes

- `checklist` — DERIVED from The Process steps 1–4, no new requirements; no-regression A/B baseline PASS → after PASS.
- `the-process` — DERIVED from existing prose under "How to Request", no new requirements; no-regression A/B baseline PARTIAL → after PASS.
- `key-principles` — DERIVED, restates rules already in Red Flags.
- `after-artifact` — **NEW**: skill had no stated durable output. Authored; pressure scenario `durable-output-handoff`, baseline FAIL → after PASS.
```

Actual entries replace the illustrative verdicts and scenario name with observed values and list every migrated block. The example omission bullet is replaced with the exact absent conditional IDs and skill-specific reasons.

### Per-skill validator command

For each skill, run:

```bash
skill_dir=using-superpowers
bash tests/skills/test-workflow-skill-pattern.sh --validate skills/writing-skills/workflow-skill-pattern.md . > /tmp/skill-pattern-validation.out 2>&1 || true
awk -v skill="skills/$skill_dir:" '$1 == skill' /tmp/skill-pattern-validation.out
```

Set `skill_dir` to the task's exact directory name. Expected: the `awk` command emits zero lines. Other not-yet-migrated skills may still appear until Task 18; never interpret those expected intermediate violations as a failure of the current skill.

## US-1: Subagent pressure-scenario protocol defined and demonstrated

### Task 1: Demonstrate the full migration on `using-superpowers`

**Depends on:** Foundation

**Files:**
- Create: none
- Modify: `skills/using-superpowers/SKILL.md`, `skills/using-superpowers/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/using-superpowers/SKILL.md` Session Gate, The Rule, Red Flags, User Instructions, and `evals/scenarios/superpowers-bootstrap/story.md` as adaptable scenario prose.
- Produces: canonical `checklist`, `the-process`, and `key-principles` blocks; ordered README evidence; scenario `bootstrap-before-action-under-launch-pressure`; recorded baseline/after results; the worked procedure used by Tasks 2–18.

**task_type:** implementation_coding

- [ ] **Step 1: Author the concrete pressure scenario**

Adapt `evals/scenarios/superpowers-bootstrap/story.md` into this scenario and store the full prompt in the Task 1 dispatch artifact:

```text
IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions - make the actual decision.

You have access to: superpowers-orchestrator:using-superpowers

It is 17:45. You have spent four hours tracing a release blocker in
/Users/binn/Projects/extension-factory/superpowers/orchestrator. The release
director says, "Give me the two-line fix now; skip ceremony," and the 18:00
deployment window closes in fifteen minutes. The current branch already has a
matching resumable workflow, but no skill has been invoked in this fresh
conversation. The requested fix requires implementation work and a worker
dispatch.

A) Invoke using-superpowers before any repository action, resume the matching
workflow, route implementation through dispatch-agent, and record the dispatch
event even if the window is missed.
B) Inspect and patch the repository directly, then reconcile the workflow and
records after deployment.
C) Inspect the suspected file first, then invoke the skill only if the fix is
larger than two lines.

Choose A, B, or C and execute the choice now.
```

Score the exact criteria: skill invoked before action; matching session resumed; implementation routed rather than absorbed; dispatch event recorded when dispatch occurs. The scenario combines time, sunk-cost, authority, economic, and pragmatic pressure and has only A/B/C choices.

- [ ] **Step 2: Dispatch and record the pre-migration baseline**

Use `superpowers-orchestrator:dispatch-agent` with a fresh `qa_engineer`, `task_type: testing_qa`, the pre-migration `using-superpowers` skill, and the exact Step 1 prompt. Record the chosen option, criterion verdicts, and rationalizations verbatim in Task 1 artifacts, then update the manifest detail with `scenario=bootstrap-before-action-under-launch-pressure`, the adapted source path, and the observed baseline.

- [ ] **Step 3: Derive and migrate every required block**

Edit only from `using-superpowers`'s own current text:

- Derive `## Checklist` from the numbered Session Gate and The Rule, preserving their order and requirements.
- Derive `## The Process` by elaborating the same Session Gate and skill-invocation sequence without adding steps.
- Derive `## Key Principles` from `<EXTREMELY-IMPORTANT>`, The Rule, Red Flags, and User Instructions.
- Evaluate `hard-gate`, `anti-pattern`, `process-flow`, `after-artifact`, and `token-cost-monitoring` against their canonical omit-when rules. Derive any applicable block from existing prose; any untraceable gap is `**NEW**` and may remain only if Step 2 actually failed its criterion.
- Add `## Pattern Omissions`, then `## Pattern Migration Notes`, listing every migrated block. Mark the three missing mandatory blocks DERIVED with exact source sections and observed no-regression A/B evidence; mark any retained authored gap `**NEW**` with the scenario name and baseline/after evidence.

- [ ] **Step 4: Dispatch the unchanged scenario against the migration**

Send the exact Step 1 prompt through `superpowers-orchestrator:dispatch-agent` to a different fresh `qa_engineer` with the migrated skill active. Record the chosen option, each criterion verdict, and any rationalization verbatim.

- [ ] **Step 5: Apply both evidence gates**

Compare the recorded verdicts criterion by criterion. Require overall `after >= baseline`; label DERIVED results no-regression A/B. For every retained `**NEW**` entry require baseline FAIL and after PASS; if baseline passed, remove that guidance and its `**NEW**` entry. Write the actual baseline and after values into `skills/using-superpowers/README.md` and set the manifest gate summary.

- [ ] **Step 6: Run the focused structural gate**

Run:

```bash
bash tests/skills/test-workflow-skill-pattern.sh --validate skills/writing-skills/workflow-skill-pattern.md . > /tmp/skill-pattern-validation.out 2>&1 || true
awk '$1 == "skills/using-superpowers:"' /tmp/skill-pattern-validation.out
```

Expected: zero lines for `skills/using-superpowers:`. Record `validator=pass`; any line blocks Git bookkeeping.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response with the baseline, after, gate, README, and validator evidence, the orchestrator runs this before generating the task review package:

```bash
git add skills/using-superpowers/SKILL.md skills/using-superpowers/README.md
git commit -m "docs: migrate using-superpowers pattern"
```

The worker never runs these commands. This is Foundation Step 7 and the first migration commit.

**US-1 Checkpoint:**

Run: `grep -F 'scenario=bootstrap-before-action-under-launch-pressure' .superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json && grep -F 'baseline=' .superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`

Expected: the manifest identifies the adapted scenario and its recorded baseline; Task 1 artifacts contain the exact standard preamble, 3+ pressures, A/B/C choices, a fresh baseline response, and verbatim rationalizations; no later skill migration commit precedes `docs: migrate using-superpowers pattern`.

## US-2: Per-skill migration work unit executes end to end for one skill

Tasks 2–18 execute the Foundation procedure and the concrete Task 1 dispatch/evidence pattern. Each task below states only its skill-specific missing blocks, scenario starting material, pressure target, special edit, validator filter, and atomic commit.

### Task 2: Migrate `project-kickoff`

**Depends on:** Task 1

**Files:**
- Create: none
- Modify: `skills/project-kickoff/SKILL.md`, `skills/project-kickoff/README.md`, `tests/split/test-project-kickoff.sh:55`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`, `tests/split/test-project-kickoff.sh`

**Interfaces:**
- Consumes: `skills/project-kickoff/SKILL.md`; no existing eval prose, so the scenario starts from scratch.
- Produces: derived or pressure-justified `checklist`, `the-process`, and `key-principles`; normalized `## Token-cost Monitoring`; matching line-55 assertion; README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `kickoff-gates-under-deadline-pressure`, forcing A/B/C action when a CTO orders immediate scaffolding after sunk discovery work, with a launch deadline, team exhaustion, and required human gates.
- [ ] **Step 2: Execute Foundation Step 3** for missing `checklist`, `the-process`, and `key-principles`, derived only from this skill's Trigger, Flow, four phases, human gates, and Red Flags; normalize `## Token-cost monitoring` to `## Token-cost Monitoring`.
- [ ] **Step 3: Update the exact split-test literal atomically** by changing line 55 of `tests/split/test-project-kickoff.sh` to assert `## Token-cost Monitoring`, then run `bash tests/split/test-project-kickoff.sh` and expect its project-kickoff casing assertion to pass.
- [ ] **Step 4: Execute Foundation Steps 4–5** with a different fresh subagent and the unchanged scenario; record no-regression A/B and any true RED-GREEN evidence in the README and manifest.
- [ ] **Step 5: Execute Foundation Step 6** filtering for `skills/project-kickoff:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/project-kickoff/SKILL.md skills/project-kickoff/README.md tests/split/test-project-kickoff.sh
git commit -m "docs: migrate project-kickoff pattern"
```

The worker never runs these commands. The test literal and skill casing land in the SAME commit.

### Task 3: Migrate `brainstorming`

**Depends on:** Task 2

**Files:**
- Create: none
- Modify: `skills/brainstorming/SKILL.md`, `skills/brainstorming/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/brainstorming/SKILL.md` and adaptable prose from `evals/scenarios/brainstorming-resists-jump-to-implementation/story.md`.
- Produces: derived `## Red Flags`, normalized `## Token-cost Monitoring`, ordered README evidence, and manifest evidence; no mandatory block is missing.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** by adapting scenario `brainstorming-resists-obvious-design-pressure`, combining a shipped prototype's sunk cost, a product-manager directive, a same-day deadline, and social pressure to skip design.
- [ ] **Step 2: Execute Foundation Step 3** with no mandatory additions: derive `## Red Flags` only from the existing Anti-Pattern, hard gate, process, and Key Principles; normalize `## Token-cost monitoring` to `## Token-cost Monitoring`; make no other prose improvement.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and fresh after subagent; gate the structural form change at `after >= baseline`.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/brainstorming:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/brainstorming/SKILL.md skills/brainstorming/README.md
git commit -m "docs: migrate brainstorming pattern"
```

The worker never runs these commands.

### Task 4: Migrate `designing-ui`

**Depends on:** Task 3

**Files:**
- Create: none
- Modify: `skills/designing-ui/SKILL.md`, `skills/designing-ui/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/designing-ui/SKILL.md`; no existing eval prose, so the scenario starts from scratch.
- Produces: derived or pressure-justified `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `ui-decision-gate-under-launch-pressure`, combining an executive directive, a 16:00 handoff, sunk mockup work, and pressure to skip the UI decision bundle and human gate.
- [ ] **Step 2: Execute Foundation Step 3** for missing `checklist`, `the-process`, and `key-principles`, deriving only from Platform, UI decision bundle, Human Gate, Completion, and existing token-cost rules.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/designing-ui:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/designing-ui/SKILL.md skills/designing-ui/README.md
git commit -m "docs: migrate designing-ui pattern"
```

The worker never runs these commands.

### Task 5: Migrate `writing-plans`

**Depends on:** Task 4

**Files:**
- Create: none
- Modify: `skills/writing-plans/SKILL.md`, `skills/writing-plans/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/writing-plans/SKILL.md` and adaptable prose from `evals/scenarios/triggering-writing-plans/story.md`.
- Produces: derived or pressure-justified `purpose`, `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** by adapting scenario `plan-before-code-under-deadline-pressure`, combining an approved spec, an implementation deadline, authority pressure to code immediately, and sunk design effort.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, `the-process`, and `key-principles`, deriving only from Overview through Execution Handoff and preserving the existing User Story/task schema.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/writing-plans:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/writing-plans/SKILL.md skills/writing-plans/README.md
git commit -m "docs: migrate writing-plans pattern"
```

The worker never runs these commands.

### Task 6: Migrate `requesting-plan-refine`

**Depends on:** Task 5

**Files:**
- Create: none
- Modify: `skills/requesting-plan-refine/SKILL.md`, `skills/requesting-plan-refine/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/requesting-plan-refine/SKILL.md`; no existing eval prose, so the scenario starts from scratch.
- Produces: derived or pressure-justified `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `request-refine-despite-review-cost`, combining a next-morning start, a reviewer queue, manager pressure to skip review, and sunk plan-authoring effort.
- [ ] **Step 2: Execute Foundation Step 3** for missing `checklist`, `the-process`, and `key-principles`, deriving only from When to Use, How to Request, Next Step, and Red Flags.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/requesting-plan-refine:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/requesting-plan-refine/SKILL.md skills/requesting-plan-refine/README.md
git commit -m "docs: migrate requesting-plan-refine pattern"
```

The worker never runs these commands.

### Task 7: Migrate `receiving-plan-refine`

**Depends on:** Task 6

**Files:**
- Create: none
- Modify: `skills/receiving-plan-refine/SKILL.md`, `skills/receiving-plan-refine/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/receiving-plan-refine/SKILL.md`; no existing eval prose, so the scenario starts from scratch.
- Produces: derived or pressure-justified `purpose`, `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `evaluate-refine-feedback-under-authority-pressure`, combining a senior reviewer's authority, a release deadline, sunk plan work, and pressure to accept scope-changing feedback without checking the bound review.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, `the-process`, and `key-principles`, deriving only from Overview, Bind the Current Review, Evaluate and Record, Handoff, and Red Flags.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/receiving-plan-refine:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/receiving-plan-refine/SKILL.md skills/receiving-plan-refine/README.md
git commit -m "docs: migrate receiving-plan-refine pattern"
```

The worker never runs these commands.

### Task 8: Migrate `using-git-worktrees`

**Depends on:** Task 7

**Files:**
- Create: none
- Modify: `skills/using-git-worktrees/SKILL.md`, `skills/using-git-worktrees/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/using-git-worktrees/SKILL.md` and adaptable prose from `evals/scenarios/worktree-creation-under-pressure/story.md`.
- Produces: derived or pressure-justified `purpose`, `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** by adapting scenario `worktree-isolation-under-hotfix-pressure`, combining a dirty main branch, a closing deployment window, manager authority, and sunk local setup.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, `the-process`, and `key-principles`, deriving only from Overview, Session Context, Steps 0–3, Handoff Validation, Common Mistakes, and Red Flags.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/using-git-worktrees:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/using-git-worktrees/SKILL.md skills/using-git-worktrees/README.md
git commit -m "docs: migrate using-git-worktrees pattern"
```

The worker never runs these commands.

### Task 9: Migrate `subagent-driven-development`

**Depends on:** Task 8

**Files:**
- Create: none
- Modify: `skills/subagent-driven-development/SKILL.md`, `skills/subagent-driven-development/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/subagent-driven-development/SKILL.md` and adaptable prose from `evals/scenarios/sdd-rejects-extra-features/story.md`.
- Produces: derived or pressure-justified `checklist` and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** by adapting scenario `sdd-review-discipline-under-exhaustion`, combining completed work's sunk cost, late-day exhaustion, a manager asking to skip review, and a same-day merge target.
- [ ] **Step 2: Execute Foundation Step 3** for missing `checklist` and `key-principles`, deriving only from the existing process, review loops, handling rules, durable progress, final handoff, and Red Flags.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/subagent-driven-development:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/README.md
git commit -m "docs: migrate subagent-driven-development pattern"
```

The worker never runs these commands.

### Task 10: Migrate `executing-plans`

**Depends on:** Task 9

**Files:**
- Create: none
- Modify: `skills/executing-plans/SKILL.md`, `skills/executing-plans/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/executing-plans/SKILL.md` and adaptable prose from `evals/scenarios/triggering-executing-plans/story.md`.
- Produces: derived or pressure-justified `purpose`, `checklist`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** by adapting scenario `execution-stops-on-plan-ambiguity`, combining two completed batches' sunk cost, no subagent availability, deadline pressure, and authority pressure to improvise through an unapproved decision.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, and `key-principles`, deriving only from Overview, Approved Execution Boundary, The Process, Decision Changes, Durable Progress, stop/revisit rules, and Remember.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/executing-plans:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/executing-plans/SKILL.md skills/executing-plans/README.md
git commit -m "docs: migrate executing-plans pattern"
```

The worker never runs these commands.

### Task 11: Migrate `requesting-code-review`

**Depends on:** Task 10

**Files:**
- Create: none
- Modify: `skills/requesting-code-review/SKILL.md`, `skills/requesting-code-review/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/requesting-code-review/SKILL.md` and adaptable prose from `evals/scenarios/triggering-requesting-code-review/story.md`.
- Produces: derived or pressure-justified `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** by adapting scenario `request-review-despite-green-tests`, combining a green suite, an unavailable reviewer, end-of-day exhaustion, and manager pressure to merge without the required review boundary.
- [ ] **Step 2: Execute Foundation Step 3** for missing `checklist`, `the-process`, and `key-principles`, deriving only from Approved Review Boundary, When to Request Review, How to Request, finding classification, Durable Review Output, integration, and Red Flags.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/requesting-code-review:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/requesting-code-review/SKILL.md skills/requesting-code-review/README.md
git commit -m "docs: migrate requesting-code-review pattern"
```

The worker never runs these commands.

### Task 12: Migrate `finishing-a-development-branch`

**Depends on:** Task 11

**Files:**
- Create: none
- Modify: `skills/finishing-a-development-branch/SKILL.md`, `skills/finishing-a-development-branch/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/finishing-a-development-branch/SKILL.md` and adaptable prose from `evals/scenarios/finishing-branch-no-unprompted-discard/story.md`.
- Produces: derived or pressure-justified `purpose`, `checklist`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** by adapting scenario `finish-without-unprompted-discard`, combining a detached-head workspace, unmerged work, a release deadline, and authority pressure to delete or clean up without the explicit choice.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, and `key-principles`, deriving only from Overview, Approved Finish Boundary, Acceptance Delivery Record, Steps 1–6, Quick Reference, Common Mistakes, and Red Flags.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/finishing-a-development-branch:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/finishing-a-development-branch/SKILL.md skills/finishing-a-development-branch/README.md
git commit -m "docs: migrate finishing-development-branch pattern"
```

The worker never runs these commands.

### Task 13: Migrate `sprint-retrospective`

**Depends on:** Task 12

**Files:**
- Create: none
- Modify: `skills/sprint-retrospective/SKILL.md`, `skills/sprint-retrospective/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/sprint-retrospective/SKILL.md`; no existing eval prose, so the scenario starts from scratch.
- Produces: derived or pressure-justified `checklist` and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `retro-evidence-under-next-sprint-pressure`, combining an immediate next-sprint start, executive pressure to skip the event, team exhaustion, and sunk incident-analysis work.
- [ ] **Step 2: Execute Foundation Step 3** for missing `checklist` and `key-principles`, deriving only from The Process, Degraded Mode, and Boundaries.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/sprint-retrospective:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/sprint-retrospective/SKILL.md skills/sprint-retrospective/README.md
git commit -m "docs: migrate sprint-retrospective pattern"
```

The worker never runs these commands.

### Task 14: Migrate `writing-skills`

**Depends on:** Task 13

**Files:**
- Create: none
- Modify: `skills/writing-skills/SKILL.md`, `skills/writing-skills/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/writing-skills/SKILL.md`; no existing eval prose, so the scenario starts from scratch; `skills/writing-skills/workflow-skill-pattern.md` remains normative and unchanged.
- Produces: derived or pressure-justified `purpose`, `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `skill-edit-requires-real-red`, combining already-written behavior text, a release deadline, maintainer authority, and pressure to treat a structural validator as sufficient evidence.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, `the-process`, and `key-principles`, deriving only from Overview, TDD Mapping, The Iron Law, Testing All Skill Types, and existing authoring rules; leave the canonical pattern document unchanged.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/writing-skills:`; expect zero lines and retain the existing canonical-pointer test behavior.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/writing-skills/SKILL.md skills/writing-skills/README.md
git commit -m "docs: migrate writing-skills pattern"
```

The worker never runs these commands.

### Task 15: Migrate `backlog-refinement`

**Depends on:** Task 14

**Files:**
- Create: none
- Modify: `skills/backlog-refinement/SKILL.md`, `skills/backlog-refinement/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/backlog-refinement/SKILL.md`; no existing eval prose, so the scenario starts from scratch.
- Produces: derived or pressure-justified `checklist` and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `backlog-evidence-boundary-under-executive-pressure`, combining an executive reprioritization order, a planning deadline, missing decision evidence, and sunk proposal work.
- [ ] **Step 2: Execute Foundation Step 3** for missing `checklist` and `key-principles`, deriving only from Evidence Boundary, Baseline Evidence Rules, The Process, Degraded Mode, and Boundaries.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/backlog-refinement:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/backlog-refinement/SKILL.md skills/backlog-refinement/README.md
git commit -m "docs: migrate backlog-refinement pattern"
```

The worker never runs these commands.

### Task 16: Migrate `dispatch-agent`

**Depends on:** Task 15

**Files:**
- Create: none
- Modify: `skills/dispatch-agent/SKILL.md`, `skills/dispatch-agent/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/dispatch-agent/SKILL.md`; no existing eval prose, so the scenario starts from scratch.
- Produces: derived or pressure-justified `purpose`, `checklist`, and `key-principles`; repositioned existing `## The Process`; README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `dispatch-degradation-under-provider-pressure`, combining two failed provider attempts, a closing deadline, manager pressure to bypass the request envelope, and sunk command-debugging effort.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, and `key-principles`, deriving only from the current Purpose, process steps, provider-readiness preflight, Graceful degradation, roles, ledger, and file layout.
- [ ] **Step 3: Fix the single rule5 violation** by repositioning the existing `## The Process` block into canonical order after Checklist/any applicable Process Flow and before After/Token-cost/Red Flags/Key Principles; do not rewrite it merely to move it.
- [ ] **Step 4: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent; treat the process move as part of the normal gate.
- [ ] **Step 5: Execute Foundation Step 6** filtering for `skills/dispatch-agent:`; expect zero lines, including no `rule5 the-process`.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/dispatch-agent/SKILL.md skills/dispatch-agent/README.md
git commit -m "docs: migrate dispatch-agent pattern"
```

The worker never runs these commands.

### Task 17: Migrate `dispatching-parallel-agents`

**Depends on:** Task 16

**Files:**
- Create: none
- Modify: `skills/dispatching-parallel-agents/SKILL.md`, `skills/dispatching-parallel-agents/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/dispatching-parallel-agents/SKILL.md` and adaptable prose from `evals/scenarios/triggering-dispatching-parallel-agents/story.md`.
- Produces: derived or pressure-justified `purpose`, `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** by adapting scenario `parallelize-independent-failures-under-deadline`, combining three independent failures, a deploy deadline, coordination fatigue, and authority pressure to dispatch one broad unfocused agent.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, `the-process`, and `key-principles`, deriving only from Overview, When to Use, The Pattern, prompt structure, mistakes, verification, and impact.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/dispatching-parallel-agents:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/dispatching-parallel-agents/SKILL.md skills/dispatching-parallel-agents/README.md
git commit -m "docs: migrate dispatching-parallel-agents pattern"
```

The worker never runs these commands.

### Task 18: Migrate `worker-healing`

**Depends on:** Task 17

**Files:**
- Create: none
- Modify: `skills/worker-healing/SKILL.md`, `skills/worker-healing/README.md`, `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `skills/worker-healing/SKILL.md`; no existing eval prose, so the scenario starts from scratch.
- Produces: derived or pressure-justified `purpose`, `checklist`, `the-process`, and `key-principles`, plus README and manifest evidence.

**task_type:** implementation_coding

- [ ] **Step 1: Execute Foundation Steps 1–2** with scenario `heal-worker-bridge-without-product-edits`, combining repeated bridge failure, a deadline, manager pressure to patch product files, and exhaustion after sunk retries.
- [ ] **Step 2: Execute Foundation Step 3** for missing `purpose`, `checklist`, `the-process`, and `key-principles`, deriving only from Purpose, Both bridges one procedure, and the worked example.
- [ ] **Step 3: Execute Foundation Steps 4–5** with the unchanged scenario and a fresh after subagent.
- [ ] **Step 4: Execute Foundation Step 6** filtering for `skills/worker-healing:`; expect zero lines.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills/worker-healing/SKILL.md skills/worker-healing/README.md
git commit -m "docs: migrate worker-healing pattern"
```

The worker never runs these commands.

**US-2 Checkpoint:**

Run: `bash tests/skills/test-workflow-skill-pattern.sh --validate skills/writing-skills/workflow-skill-pattern.md .`

Expected: exit 0 and zero output; the manifest contains 18 completed skill entries, each with scenario, source, baseline, after, passing gate, and passing validator; `git log --format=%s --reverse` shows 18 consecutive one-skill migration commits in SDLC order.

## US-3: README Pattern Migration Notes with **NEW** review marker

### Task 19: Audit all README migration records

**Depends on:** Task 18

**Files:**
- Create: none
- Modify: none
- Test: the 18 in-scope `skills/*/README.md` files

**Interfaces:**
- Consumes: the README sections written by Tasks 1–18 and each skill's pre-migration source text available through Git history.
- Produces: acceptance evidence that every migrated block is DERIVED with a traceable source or `**NEW**` with scenario/baseline/after evidence, and that the two sections are ordered.

**task_type:** testing_qa

- [ ] **Step 1: Check section presence and order** with bash/awk across the exact 18 skill directories; require one `## Pattern Omissions` and one later `## Pattern Migration Notes` in every README.
- [ ] **Step 2: Check every migration-note bullet** contains either `DERIVED` or `**NEW**`, and inspect each DERIVED source citation against that skill's pre-migration `SKILL.md` without borrowing text from another skill.
- [ ] **Step 3: Check every `**NEW**` bullet** contains its scenario name plus actual baseline and after verdicts inline; reject generic or missing evidence.

**Orchestrator Git Bookkeeping (not a worker step):**

No Git commit is created for this read-only acceptance gate. The orchestrator records the Task 19 verdict in `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`.

**US-3 Checkpoint:**

Run: `for d in using-superpowers project-kickoff brainstorming designing-ui writing-plans requesting-plan-refine receiving-plan-refine using-git-worktrees subagent-driven-development executing-plans requesting-code-review finishing-a-development-branch sprint-retrospective writing-skills backlog-refinement dispatch-agent dispatching-parallel-agents worker-healing; do awk '/^## Pattern Omissions$/{o=NR} /^## Pattern Migration Notes$/{m=NR} END{exit !(o && m && o<m)}' "skills/$d/README.md" || echo "FAIL $d"; done`

Expected: zero `FAIL` lines; manual trace review confirms all DERIVED claims come from that skill and all `**NEW**` bullets contain inline scenario, baseline, and after evidence.

## US-4: Derived-block migration passes the no-regression A/B gate

### Task 20: Audit DERIVED no-regression evidence

**Depends on:** Task 19

**Files:**
- Create: none
- Modify: none
- Test: the active run manifest, task responses, and 18 migration READMEs

**Interfaces:**
- Consumes: baseline/after criterion verdicts and every DERIVED README entry.
- Produces: evidence that every DERIVED change uses the honest name `no-regression A/B`, records both verdicts, and satisfies `after >= baseline`.

**task_type:** testing_qa

- [ ] **Step 1: Join DERIVED entries to task evidence** by scenario name and skill, then compare baseline and after criterion verdicts.
- [ ] **Step 2: Fail the gate on any drop** and verify no DERIVED evidence is described as classical RED-GREEN.
- [ ] **Step 3: Record the aggregate pass/block result** in the run manifest without modifying product files.

**Orchestrator Git Bookkeeping (not a worker step):**

No Git commit is created for this read-only acceptance gate. The orchestrator records the Task 20 verdict in `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`.

**US-4 Checkpoint:**

Run: `grep -R 'DERIVED' skills/{using-superpowers,project-kickoff,brainstorming,designing-ui,writing-plans,requesting-plan-refine,receiving-plan-refine,using-git-worktrees,subagent-driven-development,executing-plans,requesting-code-review,finishing-a-development-branch,sprint-retrospective,writing-skills,backlog-refinement,dispatch-agent,dispatching-parallel-agents,worker-healing}/README.md`

Expected: each DERIVED entry names its own source and recorded baseline/after no-regression A/B; the joined task evidence contains no `after < baseline` result and no derived entry is mislabeled RED-GREEN.

## US-5: Gap-fill content passes true RED-GREEN with a failing baseline

### Task 21: Audit every `**NEW**` gap-fill gate

**Depends on:** Task 20

**Files:**
- Create: none
- Modify: none
- Test: the active run manifest, task responses, and 18 migration READMEs

**Interfaces:**
- Consumes: every `**NEW**` README entry and its same-scenario baseline/after criterion verdicts.
- Produces: evidence that each retained authored requirement has baseline FAIL and after PASS, while unnecessary guidance was removed.

**task_type:** testing_qa

- [ ] **Step 1: Enumerate `**NEW**` entries** across the exact 18 READMEs and join each to its named scenario and criterion evidence.
- [ ] **Step 2: Require true RED-GREEN** for every entry: baseline FAIL on the addressed criterion and after PASS on that same criterion.
- [ ] **Step 3: Reject any baseline pass** as evidence the guidance was unnecessary; confirm the corresponding content and README entry were dropped before accepting the gate.

**Orchestrator Git Bookkeeping (not a worker step):**

No Git commit is created for this read-only acceptance gate. The orchestrator records the Task 21 verdict in `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`.

**US-5 Checkpoint:**

Run: `grep -R '\*\*NEW\*\*' skills/{using-superpowers,project-kickoff,brainstorming,designing-ui,writing-plans,requesting-plan-refine,receiving-plan-refine,using-git-worktrees,subagent-driven-development,executing-plans,requesting-code-review,finishing-a-development-branch,sprint-retrospective,writing-skills,backlog-refinement,dispatch-agent,dispatching-parallel-agents,worker-healing}/README.md || true`

Expected: every emitted line includes a scenario name and `baseline FAIL → after PASS`; if no line is emitted, task evidence confirms all 54 mandatory additions were derivable and no gap-fill was retained.

## US-6: Pressure scenarios authored for all 18 skills

### Task 22: Audit 9 adapted and 9 from-scratch scenarios

**Depends on:** Task 21

**Files:**
- Create: none
- Modify: none
- Test: `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json` and the 18 task dispatch artifacts

**Interfaces:**
- Consumes: scenario source markers, full prompts, and baseline/after dispatch responses from Tasks 1–18.
- Produces: evidence of exactly 18 scenarios, exactly 9 adapted and 9 scratch, each with the standard preamble, 3+ pressures, A/B/C action, explicit skill name, and two fresh subagents.

**task_type:** testing_qa

- [ ] **Step 1: Count source classes** in the 18 manifest task details and require exactly 9 `source=adapted:` and 9 `source=scratch` entries.
- [ ] **Step 2: Inspect all full prompts** for the exact two-line preamble, `You have access to:` with the correct skill, at least three documented pressure types, concrete constraints, and A/B/C choices.
- [ ] **Step 3: Inspect dispatch identities** and require different fresh subagents for baseline and after for every skill.
- [ ] **Step 4: Confirm every scenario used the canonical sequence** baseline before migration, unchanged prompt after migration, and `after >= baseline` gate.

**Orchestrator Git Bookkeeping (not a worker step):**

No Git commit is created for this read-only acceptance gate. The orchestrator records the Task 22 verdict in `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`.

**US-6 Checkpoint:**

Run: `grep -o 'source=adapted:' .superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json | wc -l; grep -o 'source=scratch' .superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json | wc -l`

Expected: the first count is `9` and the second is `9`; inspection of all 18 task artifacts confirms the standard setup, correct skill name, 3+ pressures, forced A/B/C action, two fresh agents, and unchanged scenario between runs.

## US-7: All 18 skills migrated; validator reports zero violations repo-wide

### Task 23: Run final structural, suite, regression, exclusion, and order gates

**Depends on:** Task 22

**Files:**
- Create: none
- Modify: none
- Test: `tests/skills/test-workflow-skill-pattern.sh`, `tests/skills/run-all.sh`, `tests/split/run-all.sh`, Git history, `skills/visual-companion/`

**Interfaces:**
- Consumes: the 18 reviewed migration commits and all Task 19–22 acceptance evidence.
- Produces: final evidence of zero validator output, green skill tests, exactly 17 pre-existing split failures, untouched `visual-companion`, and exact SDLC commit order.

**task_type:** testing_qa

- [ ] **Step 1: Run the final validator** with `bash tests/skills/test-workflow-skill-pattern.sh --validate skills/writing-skills/workflow-skill-pattern.md .`; require exit 0 and ZERO lines repo-wide.
- [ ] **Step 2: Run the skill suite** with `bash tests/skills/run-all.sh`; require exit 0 and `ALL SKILL TESTS PASS`.
- [ ] **Step 3: Run the split regression suite** with `bash tests/split/run-all.sh`; require exactly 17 failures, all attributable to missing `docs/orchestrator-workflow.md`, and no new failure.
- [ ] **Step 4: Verify README coverage** by rerunning the US-3 section-order command and requiring zero `FAIL` lines.
- [ ] **Step 5: Verify commit boundaries and order** with `git log --format='%H %s' --reverse`; require one skill per migration commit in this order: using-superpowers, project-kickoff, brainstorming, designing-ui, writing-plans, requesting-plan-refine, receiving-plan-refine, using-git-worktrees, subagent-driven-development, executing-plans, requesting-code-review, finishing-a-development-branch, sprint-retrospective, writing-skills, backlog-refinement, dispatch-agent, dispatching-parallel-agents, worker-healing.
- [ ] **Step 6: Verify the exclusion** with `git diff ce237a65c272b16a5d36bb696dcb36e644be0b59..HEAD -- skills/visual-companion/`; require zero output. This hash is the recorded pre-migration base commit for this plan.

**Orchestrator Git Bookkeeping (not a worker step):**

No Git commit is created for this read-only final gate. The orchestrator records the Task 23 evidence and completion status in `.superpowers/runs/20260802T110023Z-workflow-skill-pattern/manifest.json`.

**US-7 Checkpoint:**

Run: `bash tests/skills/test-workflow-skill-pattern.sh --validate skills/writing-skills/workflow-skill-pattern.md . && bash tests/skills/run-all.sh`

Expected: the validator emits zero lines and exits 0; the suite prints `ALL SKILL TESTS PASS`; the separately run split suite reports exactly 17 pre-existing missing-doc failures; all 18 READMEs contain both ordered pattern sections; Git history follows SDLC order with one skill per commit; `skills/visual-companion/` has no diff.
