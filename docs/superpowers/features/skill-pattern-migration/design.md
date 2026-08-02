---
title: Skill Pattern Migration
date: 2026-08-02
status: draft
---

# Skill Pattern Migration — Design Spec

## 1. Overview

Sub-project A defined a canonical structural pattern for workflow skills and
delivered the normative document, the structural validator, and the test runner.
Running the validator against the real repository revealed that the 18
in-scope skills require substantially more than verbatim text moves to conform:
54 rule1 violations mean that mandatory blocks simply do not exist in those
skills and must be authored from scratch. This sub-project (B) performs the
full migration of all 18 in-scope skills, one per commit in `skills/SDLC.md`
order, with eval-harness gating for every block whose authoring constitutes
behavior-shaping content. The outcome is a repository where the structural
validator reports zero violations for all in-scope skills and where every
newly-authored block has been pressure-tested against a recorded scenario.

## 2. Context & Assumptions

### What sub-project A delivered (already merged)

- `skills/writing-skills/workflow-skill-pattern.md` — normative document with a
  12-block table fenced by `<!-- blocks:start -->` / `<!-- blocks:end -->`, an
  exclusion list fenced by `<!-- exclude:start -->` / `<!-- exclude:end -->`,
  the six validator rules, and the `## Pattern Omissions` README format.
- `tests/skills/test-workflow-skill-pattern.sh` — data-driven structural
  validator.
- `tests/skills/run-all.sh` — aggregate runner.
- `skills/writing-skills/SKILL.md` — competing template section replaced by a
  pointer.

Sub-project A explicitly deferred the migration of the 18 in-scope skills to
sub-project B. This spec is sub-project B.

### The problem that reshaped sub-project B

Sub-project A's spec assumed migration would be "verbatim text moves — blocks
reordered and renamed, wording not rewritten" and used exactly that assumption
to justify skipping the Iron Law's RED-GREEN pressure testing.

Running the validator against the real repository disproves that assumption:

| Rule | Count | What it takes to fix |
|---|---|---|
| rule3 | 87 | Write a README omission reason — mechanical |
| rule1 | 54 | Author a mandatory block that does not exist |
| rule5 | 1 | Reorder `dispatch-agent`'s `## The Process` |

The 54 rule1 violations by missing block:

| Missing mandatory block | Skills affected |
|---|---|
| `key-principles` | 17 |
| `checklist` | 17 |
| `the-process` | 11 |
| `purpose` | 9 |

Authoring a `## Checklist` for 17 skills is creating behavior-shaping content —
exactly what `CLAUDE.md` requires adversarial pressure testing and before/after
eval evidence for, and what `writing-skills`' Iron Law covers ("applies to NEW
skills AND EDITS to existing skills"). Sub-project A's Iron-Law exemption does
not survive this evidence.

### Eval harness facts (verified)

Harness: `evals/` (cloned `superpowers-evals`), 79 scenarios, drives real tmux
sessions of Claude Code / Codex and judges compliance with an LLM verifier.

Commands:

```
bun install
bun run check
bun run quorum check
bun run quorum run scenarios/<name> --coding-agent claude --credential sonnet
bun run quorum show <run-dir>
```

Scenario structure — a directory under `evals/scenarios/<name>/` containing:

- `story.md` — frontmatter (`id`, `title`, `status`, `tags`, `quorum_tier`) +
  roleplay instructions + an `## Acceptance Criteria` section.
- `setup.sh` — fixture creation, uses setup-helpers.
- `checks.sh` — `pre()` and `post()` functions using `check-transcript`
  assertions (e.g. `check-transcript skill-called <skill>`,
  `check-transcript skill-before-implementation-tool <skill> Write`).

Tiers observed: `sentinel`, `full`, `adhoc`.

### Known environment facts

- `bash tests/split/run-all.sh` has 17 pre-existing failures on this branch
  from a missing `docs/orchestrator-workflow.md`. Verified by stashing: 17
  before, 17 after. Not caused by this work.
- The one rule5 violation is `skills/dispatch-agent: rule5 the-process`.
- Migrating `project-kickoff` must also update
  `tests/split/test-project-kickoff.sh` line 55, which asserts the literal
  lowercase `## Token-cost monitoring`, in the same commit — otherwise
  `tests/split/run-all.sh` gains a new failure.

### Existing eval coverage per in-scope skill

| Scenarios | Skills |
|---|---|
| Has coverage | `brainstorming` (18), `subagent-driven-development` (19), `finishing-a-development-branch` (5), `using-superpowers` (3), `writing-plans` (2), `using-git-worktrees` (2), `requesting-code-review` (2), `executing-plans` (1), `dispatching-parallel-agents` (1) |
| Zero coverage | `project-kickoff`, `designing-ui`, `requesting-plan-refine`, `receiving-plan-refine`, `sprint-retrospective`, `writing-skills`, `backlog-refinement`, `dispatch-agent`, `worker-healing` |

9 of 18 skills have no scenario. Approximately 9 new scenarios must be
authored. `skills/SDLC.md` order puts `project-kickoff` (zero scenarios) at
position 2, so scenario authoring begins almost immediately rather than after a
warm-up.

### Scale

18 commits, ~9 authored scenarios, ~28+ eval-gated blocks, minimum 2 harness
runs per eval-gated skill. This is substantially larger than sub-project A.
Eval runs are wall-clock expensive because they drive real sessions. Durable
progress lives in the run manifest so work survives compaction and resumes at
the first incomplete skill.

## 3. Scope

### Goals

- Migrate all 18 in-scope workflow skills to the canonical structural pattern,
  one skill per commit in `skills/SDLC.md` order.
- Gate every behavior-shaping block with an eval scenario — either by using an
  existing scenario or by authoring one as part of the migration commit.
- Populate the `## Pattern Omissions` README section for every absent
  conditional block.
- Populate the `## Pattern Migration Notes` README section for every migrated
  block, using the `**NEW**` review marker for authored (not derived) content.
- Pass the structural validator with zero violations repo-wide after the final
  commit.
- Verify the eval harness runs in this environment as a foundation check before
  the first skill migration begins.

### Non-Goals

- Editing anything under `skills/`, `tests/`, or `evals/` as part of this
  spec document. This spec describes what the migration will do; it does not
  perform the migration.
- Migrating `skills/visual-companion/` (excluded per sub-project A decision
  D10 — no README, not listed in `SDLC.md`).
- Weakening the Mandatory tiers of the pattern. The four currently-missing
  mandatory block types (`key-principles`, `checklist`, `the-process`,
  `purpose`) remain Mandatory; this migration authors them rather than demoting
  them to Conditional.
- Rewriting or quality-improving blocks that are already present and
  conforming. Only blocks that need to be added, derived, or gap-filled are
  touched; existing conforming blocks are relocated only if rule5 requires it.
- Committing or pushing any changes (constraints of this spec task).

## 4. User Stories

### US-1: Eval harness foundation verified and gating (Priority: P1)

As the migration executor, I want to confirm the eval harness runs successfully
in this environment before any skill migration begins, so that a broken harness
environment does not cause 18 commits of structural-only work to silently
bypass the Iron Law.

**Acceptance criteria:**

- GIVEN the `evals/` directory exists WHEN `bun install` is run there THEN it
  exits zero with no unresolved packages.
- GIVEN `bun install` succeeded WHEN `bun run quorum check` is run THEN it
  exits zero, confirming the harness configuration is valid.
- GIVEN `bun run quorum check` passed WHEN one throwaway scenario is run with
  `bun run quorum run` THEN the harness successfully drives a tmux session and
  produces a run directory with a result.
- GIVEN the harness cannot complete any of the above steps WHEN the gate fires
  THEN sub-project B stops at that point rather than silently degrading to
  structural-only migration.

### US-2: Per-skill migration work unit executes end to end for one skill (Priority: P1)

As the migration executor, I want a repeatable 7-step work unit for each skill
so that every skill's migration commit is produced by the same defined process
and the eval gate is never skipped.

**Acceptance criteria:**

- GIVEN a skill to be migrated WHEN step 1 is run THEN the existence of an
  eval scenario for that skill is checked; if none exists, `story.md`,
  `setup.sh`, and `checks.sh` are authored and the scenario is verified to
  run before proceeding.
- GIVEN an eval scenario exists for the skill WHEN step 2 is run THEN a
  baseline harness run is executed on the commit *before* this migration and
  its verdict is recorded.
- GIVEN the baseline is recorded WHEN step 3 is run THEN derived blocks,
  gap-fill content, `## Pattern Omissions`, `## Pattern Migration Notes`,
  heading renames, and casing corrections are applied (plus the block reorder
  for `dispatch-agent`).
- GIVEN step 3 is complete WHEN step 4 is run THEN the same scenario is run
  again with the same credential and its verdict is recorded.
- GIVEN the after-run verdict is recorded WHEN step 5 is run THEN `after >=
  baseline` is confirmed; if the commit introduces `**NEW**` gap-fill content
  then `baseline` must actually have failed the new criterion — otherwise the
  gate is not satisfied.
- GIVEN step 5 passes WHEN step 6 is run THEN the structural validator reports
  zero violations for that skill.
- GIVEN steps 1–6 all pass WHEN step 7 is run THEN the migration commit for
  that skill is created.

### US-3: README Pattern Migration Notes with **NEW** review marker (Priority: P1)

As a reviewer of 18 migration commits, I want each skill's README to carry a
`## Pattern Migration Notes` section that distinguishes derived blocks from
authored ones, so that reviewing a commit requires reading only the `**NEW**`
entries in depth rather than every block.

**Acceptance criteria:**

- GIVEN any migrated skill's README WHEN `## Pattern Migration Notes` is read
  THEN every block that was migrated appears as a bullet with either `DERIVED`
  (no new requirements added) or `**NEW**` (authored; no prior statement existed
  or a gap was filled).
- GIVEN a bullet is marked `DERIVED` WHEN the source prose is checked THEN the
  block can be traced back to specific existing text in the skill with no net
  new behavioral requirement.
- GIVEN a bullet is marked `**NEW**` WHEN the README entry is read THEN it
  contains the eval scenario name, the baseline verdict, and the after verdict
  inline.
- GIVEN both `## Pattern Omissions` and `## Pattern Migration Notes` are present
  WHEN the README is read THEN the sections appear in that order and neither
  section is absent.

The verbatim two-section format each migrated skill's README must carry:

```markdown
## Pattern Omissions

- `hard-gate` — skill only reads and reports; no irreversible act.

## Pattern Migration Notes

- `checklist` — DERIVED from The Process steps 1–4, no new requirements.
- `the-process` — DERIVED from existing prose under "How to Request".
- `key-principles` — DERIVED, restates rules already in Red Flags.
- `after-artifact` — **NEW**: skill had no stated durable output. Authored;
  eval scenario `<name>`, baseline <result> → after <result>.
```

`**NEW**` is the human's review marker. Derived entries assert no behavior
change; `**NEW**` entries carry their eval evidence inline. This makes
reviewing 18 commits tractable: read Migration Notes first, dig only into
`**NEW**` entries.

### US-4: Derived-block migration passes the no-regression A/B gate (Priority: P1)

As the migration executor, I want derived blocks to pass a no-regression A/B
gate rather than a classical RED-GREEN gate, and for the spec to name this
distinction plainly, so that the eval evidence is honest rather than
overclaiming.

**Acceptance criteria:**

- GIVEN a block is marked `DERIVED` in the Migration Notes WHEN the A/B gate
  is run THEN `after >= baseline` is confirmed; a regression (after < baseline)
  fails the gate.
- GIVEN the gate passes WHEN the commit is made THEN the Migration Notes entry
  records the before and after verdicts.
- GIVEN the gate is described WHEN the spec or any commit message refers to it
  THEN it is named a "no-regression A/B" rather than "RED-GREEN", because the
  skill already existed and already passed; the baseline is not expected to fail.

**Honest naming correction (record as given, do not soften):** For derived
blocks this is a no-regression A/B, not classical RED-GREEN. Classical RED
means "the agent fails without the skill"; here the skill already exists and
already passes. Only `**NEW**` gap-fill content gets true RED-GREEN — its
baseline must actually fail the new criterion, otherwise the added guidance
was not needed. The spec says this plainly rather than overclaiming RED-GREEN
across the board.

### US-5: Gap-fill content passes true RED-GREEN with a failing baseline (Priority: P2)

As the migration executor, I want authored gap-fill content to be verified by a
true RED-GREEN cycle — baseline must fail before the content is added — so that
every `**NEW**` block can be demonstrated to have been necessary.

**Acceptance criteria:**

- GIVEN a block is marked `**NEW**` in the Migration Notes WHEN the baseline
  harness run is examined THEN the scenario's verdict for the criterion that
  the new block addresses is recorded as failing.
- GIVEN the baseline fails WHEN the migration (including the new block) is
  applied and the after-run is executed THEN the after verdict passes the same
  criterion.
- GIVEN `after` passes WHEN the commit is made THEN the `**NEW**` Migration
  Notes entry records both verdicts inline as evidence.
- GIVEN a `**NEW**` block where the baseline did not actually fail WHEN this
  is discovered during the gate check THEN the new content must be revised or
  reclassified — adding guidance that produced no measurable improvement
  violates the Iron Law.

### US-6: Eval scenarios authored for the 9 uncovered skills (Priority: P2)

As the migration executor, I want each of the 9 skills that currently have no
eval scenario to gain a scenario as part of their migration commit, so that
no skill ships behavior-shaping content without gate evidence.

**Acceptance criteria:**

- GIVEN a skill with zero existing scenarios WHEN its migration commit is
  prepared THEN a scenario directory is authored under `evals/scenarios/<name>/`
  with `story.md`, `setup.sh`, and `checks.sh` following the tier and
  structure observed in existing scenarios.
- GIVEN the authored scenario WHEN `bun run quorum run scenarios/<name>` is
  executed THEN it runs to completion and produces a verdict.
- GIVEN the scenario runs WHEN it is used as the migration gate THEN the same
  7-step work unit applies: baseline before the migration, after after the
  migration, gate on `after >= baseline`.
- GIVEN the scenario is authored WHEN `story.md` frontmatter is read THEN
  `id`, `title`, `status`, and `quorum_tier` are all present with non-empty
  values.

The 9 skills requiring scenario authoring: `project-kickoff`, `designing-ui`,
`requesting-plan-refine`, `receiving-plan-refine`, `sprint-retrospective`,
`writing-skills`, `backlog-refinement`, `dispatch-agent`, `worker-healing`.

### US-7: All 18 skills migrated; validator reports zero violations repo-wide (Priority: P2)

As the repository maintainer, I want the structural validator to report zero
violations across all 18 in-scope skills after the final migration commit, so
that the pattern is fully enforced rather than partially enforced.

**Acceptance criteria:**

- GIVEN all 18 migration commits have been applied WHEN `bash
  tests/skills/run-all.sh` is run THEN it prints `ALL SKILL TESTS PASS` and
  exits zero.
- GIVEN the validator exits zero WHEN each migrated skill's README is checked
  THEN every skill has both `## Pattern Omissions` and `## Pattern Migration
  Notes` sections present.
- GIVEN the migration is complete WHEN `bash tests/split/run-all.sh` is run
  THEN the failure count is identical to the pre-migration count (17
  pre-existing failures from the missing `docs/orchestrator-workflow.md`,
  unrelated to this work); no new failures have been introduced.
- GIVEN the migration order followed `skills/SDLC.md` WHEN the commits are
  examined THEN `using-superpowers` is first, the five SDLC phases (A–G, S)
  are in order, and `dispatch-agent`, `dispatching-parallel-agents`, and
  `worker-healing` are last.

## 5. Approach

The chosen approach is **full migration with evals**. All 18 in-scope skills
are migrated to the canonical structural pattern with the eval harness gating
every block whose authoring constitutes behavior-shaping content. Migration
proceeds one skill per commit in `skills/SDLC.md` order. Derived blocks pass a
no-regression A/B gate; authored (`**NEW**`) blocks require a true RED-GREEN
cycle where the baseline must actually fail the new criterion.

### Alternatives considered

| Option | Why rejected |
|--------|--------------|
| Mechanical pass only (87 README records + 1 reorder + renames), deferring all 54 authored blocks to a later sub-project C | Ships value sooner and keeps the Iron Law intact, but leaves the pattern unenforced for the majority of violations and defers the hard problem rather than solving it |
| Full migration with NO evals, relying on the structural validator alone | Fastest route to a green validator, but knowingly violates writing-skills' Iron Law and CLAUDE.md's bar for behavior-shaping content |
| Revisit the pattern: demote Checklist / Key Principles / The Process from Mandatory to Conditional so existing skills pass by recording an omission | Cheapest, but weakens the pattern the human approved in sub-project A and partly defeats its purpose |
| Structural-only for the 9 uncovered skills, evals only where scenarios already exist | Half the skills would ship behavior-shaping content with no eval — option 3 wearing option 2's clothes |

## 6. Design

### Architecture

```
evals/scenarios/<name>/   NEW (×9) — one scenario dir per currently-uncovered skill
  story.md
  setup.sh
  checks.sh

skills/<each>/README.md   EDIT (×18) — ## Pattern Omissions + ## Pattern Migration Notes

skills/<each>/SKILL.md    EDIT (×18) — add missing mandatory blocks, derive/gap-fill,
                                       rename/recase headings, reorder (dispatch-agent only)
```

No files under `tests/` are edited by this sub-project except that the
`project-kickoff` migration commit must atomically update
`tests/split/test-project-kickoff.sh` line 55 (the `## Token-cost monitoring`
lowercase literal) to match the normalized casing, preventing a new
`run-all.sh` failure.

### Components & Interfaces

#### Per-skill migration work unit (7 steps — verbatim)

1. **Scenario exists?** no → author `story.md` + `setup.sh` + `checks.sh`,
   verify it runs.
2. **Baseline run** on the commit BEFORE this migration → record verdict.
3. **Migrate** derived blocks + gap-fill + README Omissions + Migration Notes
   + heading renames/casing (+ reorder for `dispatch-agent`).
4. **After run** same scenario, same credential.
5. **Gate** `after >= baseline`; NEW content must show baseline actually
   failing.
6. **Validator** that skill produces zero violations.
7. **Commit**.

#### Migration order (skills/SDLC.md order, 18 skills)

```
0  using-superpowers
A  project-kickoff
B  brainstorming, designing-ui
C  writing-plans, requesting-plan-refine, receiving-plan-refine
D  using-git-worktrees, subagent-driven-development, executing-plans, requesting-code-review
E  finishing-a-development-branch
F  sprint-retrospective, writing-skills
G  backlog-refinement
S  dispatch-agent, dispatching-parallel-agents, worker-healing
(visual-companion excluded per sub-project A decision D10)
```

#### Eval scope — which blocks are eval-gated

Approximately 28+ eval-gated blocks across at most 18 skills:

| Block | Skills affected | Gate |
|---|---|---|
| `## Checklist` | 17 | EVAL-GATED |
| `## The Process` | 11 | EVAL-GATED |
| Gap-fill content | Count unknown until derivation | EVAL-GATED |
| `## Key Principles` | 17 | Structural validation ONLY (restates rules already present elsewhere in the same skill) |
| `## Purpose` (paragraph) | 9 | Structural validation ONLY (restates rules already present elsewhere in the same skill) |
| README records, heading renames, casing, reordering | All | NOT eval-gated |

#### README two-section format

Each migrated skill's README carries two sections. Verbatim format:

```markdown
## Pattern Omissions

- `hard-gate` — skill only reads and reports; no irreversible act.

## Pattern Migration Notes

- `checklist` — DERIVED from The Process steps 1–4, no new requirements.
- `the-process` — DERIVED from existing prose under "How to Request".
- `key-principles` — DERIVED, restates rules already in Red Flags.
- `after-artifact` — **NEW**: skill had no stated durable output. Authored;
  eval scenario `<name>`, baseline <result> → after <result>.
```

`**NEW**` is the human's review marker. Derived entries assert no behavior
change; `**NEW**` entries carry their eval evidence inline. This makes
reviewing 18 commits tractable: read Migration Notes first, dig only into
`**NEW**` entries.

#### Content source

Content for migrated blocks is **derived** from each skill's existing text.
Where derivation exposes a real gap (a skill with no stated process at all),
the missing guidance is authored — and that authored guidance is new behavior
requiring its own eval.

### Data Model & Flow

The run manifest (the `evals/` run directory produced by
`bun run quorum run`) is the durable progress record. If the session is
compacted or interrupted, the next executor reads the manifest to find the
first incomplete skill and resumes there. The 18-commit sequence is the unit
of durable progress; a partial skill (steps 1–6 done, step 7 not yet
committed) must be restarted from step 2.

### Error Handling

**Harness fails to run (US-1 gate):** sub-project B stops. The harness
environment must be confirmed before any migration work begins. Silently
degrading to structural-only is not an acceptable fallback.

**Baseline lower than expected:** record as-is; the gate is
`after >= baseline`, not `after >= some target`. A baseline that already
passes does not disqualify a derived block; it means no regression was
introduced.

**NEW baseline does not fail:** the authored content must be revised or
reclassified. Content that produces no measurable improvement violates the
Iron Law (writing-skills: "applies to NEW skills AND EDITS to existing
skills").

**Validator still red after migration (step 6):** the commit is not made
until the validator is green. The skill is reworked until zero violations.

**`project-kickoff` migration:** the `tests/split/test-project-kickoff.sh`
line 55 update must be in the same commit. If it is omitted, `run-all.sh`
gains a new failure, violating the constraint that pre-existing failures
must not increase.

### Edge Cases

**Residual risk — "derived therefore no behavior change" is a judgment call
per block. Record this, do not soften it:** A Checklist derived from prose
still concentrates and reorders that prose, and `writing-skills` itself warns
that form changes behavior. The no-regression A/B is what catches that
judgment being wrong — which is precisely why the gate is `after >= baseline`,
not merely "after passes".

**`dispatch-agent` rule5 reorder:** the single rule5 violation requires
reordering `## The Process` within `dispatch-agent`. This structural change is
also eval-gated (the block is Mandatory) and counts against the skill's
normal 7-step work unit.

**Skills at SDLC phase S (`dispatch-agent`, `dispatching-parallel-agents`,
`worker-healing`):** all three have zero eval coverage. Three of the nine
authored scenarios are concentrated here. Phase S is last in SDLC order,
giving earlier migrations to warm up the scenario-authoring process.

## 7. Testing Strategy

**Structural gate (per-skill, every commit):** `bash tests/skills/run-all.sh`
after each migration commit. The skill just migrated must contribute zero
violations. The validator is not run once at the end; it is run after every
commit.

**Eval gate (per eval-gated block, every commit):** `bun run quorum run
scenarios/<name> --coding-agent claude --credential sonnet` twice per skill —
once before (baseline), once after. Gate: `after >= baseline`. For `**NEW**`
content: baseline must fail the new criterion.

**Regression (before the final commit):** `bash tests/split/run-all.sh` must
show exactly 17 failures — the pre-existing count from the missing
`docs/orchestrator-workflow.md`. Any count above 17 indicates this work
introduced a new failure.

**Harness foundation (before skill 0):** `bun install`, `bun run quorum check`
green, one throwaway run confirming the harness drives a session. If any of
these steps fails, sub-project B stops here.

Each US maps to its verification command:

| US | Verification |
|---|---|
| US-1 | `bun install && bun run quorum check && bun run quorum run <throwaway>` |
| US-2 | 7-step work unit executed for each of 18 skills |
| US-3 | Each README contains both sections with correct format |
| US-4 | `after >= baseline` confirmed for every DERIVED block |
| US-5 | Baseline fails, after passes, evidence recorded inline |
| US-6 | 9 scenario dirs exist and run successfully |
| US-7 | `bash tests/skills/run-all.sh` exits zero; `bash tests/split/run-all.sh` shows exactly 17 failures |

## 8. Success Criteria

- SC-1: `bash tests/skills/run-all.sh` prints `ALL SKILL TESTS PASS` and
  exits zero after the final migration commit.
- SC-2: `bash tests/split/run-all.sh` shows exactly the same failure count
  (17) as before this work began — no new failures introduced.
- SC-3: Every migrated skill's README contains both `## Pattern Omissions` and
  `## Pattern Migration Notes` sections.
- SC-4: Every `**NEW**` Migration Notes entry records its eval scenario name,
  baseline verdict, and after verdict inline.
- SC-5: Every `**NEW**` block's baseline run produced a failing verdict for the
  criterion the new block addresses (true RED-GREEN, not no-regression A/B).
- SC-6: The eval harness foundation check passes — `bun install`, `bun run
  quorum check`, and one throwaway run all exit successfully — before any
  skill migration commit is made.
- SC-7: The migration order follows `skills/SDLC.md` exactly: `using-superpowers`
  first, then phases A → G → S, `visual-companion` excluded throughout.
- SC-8: `skills/visual-companion/` is not touched at any point in this
  sub-project.
