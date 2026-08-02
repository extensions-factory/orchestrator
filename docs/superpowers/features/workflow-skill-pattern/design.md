---
title: Workflow Skill Structural Pattern
date: 2026-08-02
status: draft
---

# Workflow Skill Structural Pattern — Design Spec

## 1. Overview

The 19 skills in `skills/` share no consistent internal structure. Heading vocabulary forks five ways, only 3 of 19 carry a process-flow diagram, only one carries a numbered checklist, and sizes range from 32 to 693 lines. There is no mechanical check to prevent or detect this drift. This feature defines a canonical structural pattern for workflow skills, documents it in a single normative file, and enforces it with a structural validator script. The outcome is that any agent or human can enter any skill at the fidelity they need — checklist, control-flow diagram, or prose elaboration — and reach the same steps. The validator makes pattern conformance a CI gate, not a social convention.

## 2. Context & Assumptions

`skills/brainstorming/SKILL.md` already embodies the three-fidelity ladder this pattern formalises: a Checklist (trackable contract), a Process Flow digraph (control flow with gates and loops), and The Process prose (elaboration). All other in-scope skills lack at least one of the three. The repo's Iron Law ("no skill edit without a failing test first") applies; the validator exists to satisfy it for the migration phase (sub-project B, a later spec) without demanding 19 RED-GREEN cycles for verbatim text moves.

`skills/writing-skills/SKILL.md:97` already has a generic "## SKILL.md Structure" section that will be superseded; the pattern doc is the new single source of truth for that content. `skills/visual-companion/` has no README.md, is not listed in `skills/SDLC.md`, and is excluded per human decision (D10). The implementation language is bash + grep, matching the convention in `tests/split/*.sh`. No new tooling, no new dependencies, no new file formats are introduced.

All design decisions below were approved by the human partner in a brainstorming session. This spec records those decisions; it does not propose alternatives.

## 3. Scope

### Goals

- Define and document one canonical structural pattern for all in-scope workflow skills.
- Provide a normative 12-block table with IDs, validator markers, tiers, and omit-when conditions.
- Specify the `## Pattern Omissions` README section format for conditional block omissions.
- Enforce the pattern with a structural validator script that reads the block table directly from the pattern doc.
- Replace the generic `## SKILL.md Structure` section in `writing-skills/SKILL.md` with a pointer to the new pattern doc.
- Add a self-check fixture that proves rule 6 (zero-rows → loud FAIL) cannot be silently disabled.
- Wire the new `tests/skills/run-all.sh` in the same style as `tests/split/run-all.sh`.

### Non-Goals

- **Sub-project B (follow-on, separate spec):** migrating the 18 in-scope skills to the pattern, one per commit, in SDLC.md order. Migration is deliberately out of scope here; this spec covers pattern definition and tooling only.
- Rewriting, re-ordering, or quality-improving any block content during migration (the Iron Law boundary: verbatim text moves only in sub-project B).
- Adding a pattern for `skills/visual-companion/` (excluded per D10 until it gains a README and SDLC.md entry).
- Enforcing block prose quality (the validator checks presence and order, not content quality; that is the honest ceiling of the mechanical approach).

## 4. User Stories

### US-1: Pattern doc with normative fenced block table and exclusion fences (Priority: P1)

As a skill author or validator script, I want a single normative file that defines every required block by ID, validator marker, tier, and omit-when condition — with the block table fenced so a parser can extract it and with excluded skills fenced so the list is visible and machine-readable.

**Acceptance criteria:**

- GIVEN `skills/writing-skills/workflow-skill-pattern.md` exists WHEN the file is read THEN it contains a block table between `<!-- blocks:start -->` and `<!-- blocks:end -->` fences with exactly 12 rows matching the approved table verbatim (ids, markers, tiers, omit-when).
- GIVEN the pattern doc exists WHEN it is read THEN `skills/visual-companion/` appears between `<!-- exclude:start -->` and `<!-- exclude:end -->` fences, and no other exclusion list exists anywhere else in the repo.
- GIVEN the pattern doc exists WHEN it is read THEN no block identity is defined anywhere except in this file (validator holds zero block knowledge of its own).
- GIVEN the pattern doc exists WHEN `writing-skills/SKILL.md` is read THEN the old `## SKILL.md Structure` section is replaced by a short pointer to this file (decision D1).

### US-2: Structural validator script that parses the doc and checks all in-scope skills (Priority: P1)

As the CI gate, I want a bash script that reads the block table from the pattern doc, checks every in-scope `skills/*/SKILL.md` against all six rules, and exits non-zero with one line per violation.

**Acceptance criteria:**

- GIVEN `tests/skills/test-workflow-skill-pattern.sh` exists WHEN it is run against the repo THEN it applies the six validator rules from the pattern doc to every in-scope `skills/*/SKILL.md` (all skills except those in the exclude fences).
- GIVEN a skill is missing a mandatory block WHEN the validator runs THEN it emits `skills/<name>: rule1 <block-id>` and exits non-zero.
- GIVEN a conditional block is absent and the skill's README lists it WHEN the validator runs THEN the skill passes that block check (rule 2).
- GIVEN a conditional block is absent and the skill's README does not list it (or has no README) WHEN the validator runs THEN it emits `skills/<name>: rule3 <block-id>` and exits non-zero.
- GIVEN a conditional block is present but the README lists it as omitted WHEN the validator runs THEN it emits `skills/<name>: rule4 <block-id>` and exits non-zero (stale record).
- GIVEN blocks are present but out of table order WHEN the validator runs THEN it emits `skills/<name>: rule5 <block-id>` and exits non-zero.
- GIVEN a skill has all required blocks in correct order WHEN the validator runs THEN that skill produces no violation lines and does not affect the exit code.

### US-3: README "## Pattern Omissions" section format specified and enforced by rules 2–4 (Priority: P1)

As a skill author, I want a documented and machine-enforced format for recording why a conditional block is absent, so that omission reasons are always explicit and never silently stale.

**Acceptance criteria:**

- GIVEN the pattern doc exists WHEN it is read THEN it specifies the exact `## Pattern Omissions` section format (heading, bullet list of `\`<id>\` — <reason>` entries).
- GIVEN a skill's README contains `## Pattern Omissions` with a valid `\`<id>\`` entry WHEN the validator runs THEN that conditional block's absence is accepted (rule 2).
- GIVEN a skill's README `## Pattern Omissions` lists an id that the skill now actually contains WHEN the validator runs THEN the validator emits `skills/<name>: rule4 <block-id>` (stale record, rule 4).
- GIVEN a conditional block is absent and no README exists for the skill WHEN the validator runs THEN the validator emits `skills/<name>: rule3 <block-id>` and exits non-zero.

### US-4: writing-skills/SKILL.md generic structure section replaced by a pointer (Priority: P2)

As a skill author consulting `writing-skills/SKILL.md`, I want the generic "## SKILL.md Structure" section to point to the normative pattern doc rather than contain a competing template, so there is only one source of truth.

**Acceptance criteria:**

- GIVEN `writing-skills/SKILL.md` is read WHEN searching for `## SKILL.md Structure` THEN the section body contains only a short pointer sentence referencing `workflow-skill-pattern.md` and does not define any block list or block format of its own.
- GIVEN the pattern doc exists and `writing-skills/SKILL.md` has been updated WHEN the validator runs THEN `writing-skills/SKILL.md` itself is validated against the pattern (it is not exempt).

### US-5: Validator self-check fixture proving rule 6 fails loudly (Priority: P2)

As the test suite, I want a fixture that strips the block table from the pattern doc and asserts the validator exits non-zero, so that a doc edit that accidentally breaks the table cannot silently make the validator a no-op.

**Acceptance criteria:**

- GIVEN `tests/skills/test-workflow-skill-pattern.sh` exists WHEN it is run with a fixture input that has an empty or missing block table THEN it exits non-zero and prints a loud failure message (rule 6).
- GIVEN the real pattern doc has a valid block table WHEN the self-check runs THEN the self-check passes and does not affect other skill checks.
- GIVEN the block table in the pattern doc is parseable WHEN the validator runs THEN it processes at least 12 rows; fewer rows is a parse error that triggers rule 6.

### US-6: tests/skills/run-all.sh wired in tests/split/run-all.sh style (Priority: P2)

As a developer, I want a `tests/skills/run-all.sh` runner that discovers and runs all `test-*.sh` files in `tests/skills/`, matching the existing `tests/split/run-all.sh` convention, so skill tests can be run with a single command.

**Acceptance criteria:**

- GIVEN `tests/skills/run-all.sh` exists WHEN it is run THEN it executes all `test-*.sh` files found in the same directory in glob order.
- GIVEN any `test-*.sh` exits non-zero WHEN `run-all.sh` runs THEN `run-all.sh` exits non-zero after running all tests (not short-circuit).
- GIVEN all `test-*.sh` files pass WHEN `run-all.sh` runs THEN it prints `ALL SKILL TESTS PASS` and exits zero.
- GIVEN `tests/split/run-all.sh` exists WHEN both runners are examined THEN `tests/skills/run-all.sh` follows the same structural idiom (`set -euo pipefail`, glob loop, accumulated `fail`, summary message).

## 5. Approach

The chosen approach is a **doc-parsing validator**: the validator script reads the block table directly out of `skills/writing-skills/workflow-skill-pattern.md` using awk, then checks each in-scope `skills/*/SKILL.md` against the parsed rows. The exclusion list is read from the same doc (between `<!-- exclude:start -->` and `<!-- exclude:end -->` fences). The validator holds zero block knowledge of its own — the pattern doc is the single, sole definition of block identity. This is what makes doc and validator structurally unable to drift apart: if the doc is broken, rule 6 fires immediately.

### Alternatives considered

| Option | Why rejected |
|--------|--------------|
| Hardcoded block list in the validator plus a reconciliation test asserting the doc table matches | Ships the pattern with a drift problem baked in — a third file is needed to keep two sources honest, which is the very drift this feature exists to prevent. |
| Sidecar `workflow-blocks.tsv` data file, doc as pure prose | Introduces a file format nothing else in the repo uses, for no gain over parsing the table that has to be written anyway; prose can still drift from the data file. |
| Manual conformance checklist, no script | Zero tooling, but 19 skills drift again with nothing to catch it; `writing-skills/SKILL.md` itself says mechanical constraints enforceable with regex/validation should be automated. |
| Validator plus pressure-testing every migration commit | Honours the Iron Law most strictly but costs 19 RED-GREEN cycles for changes that move text verbatim without altering behaviour. |

## 6. Design

### Architecture

```
skills/writing-skills/
  workflow-skill-pattern.md        NEW  — normative block table + exclusion fences + prose per block
  SKILL.md                         EDIT — ## SKILL.md Structure replaced by a pointer (D1)

tests/skills/
  test-workflow-skill-pattern.sh   NEW  — parses the block table, validates skills/*/SKILL.md
  run-all.sh                       NEW  — same style as tests/split/run-all.sh

skills/<each>/README.md            EDIT (sub-project B) — ## Pattern Omissions section added
```

Control flow: the validator reads the block table out of `workflow-skill-pattern.md` with awk (between `<!-- blocks:start -->` / `<!-- blocks:end -->` fences), reads the exclusion list (between `<!-- exclude:start -->` / `<!-- exclude:end -->` fences), then for each non-excluded `skills/*/SKILL.md` applies the six rules in order. A conditional block miss passes only if that skill's `README.md` "## Pattern Omissions" section names the block id. The validator emits one line per violation and exits non-zero on any violation.

### Components & Interfaces

**`skills/writing-skills/workflow-skill-pattern.md`**

The normative document. Contains:
- A prose introduction explaining the three-fidelity ladder.
- The 12-block table, fenced between `<!-- blocks:start -->` and `<!-- blocks:end -->`.
- Per-block prose elaboration of intent and content expectations.
- The `## Pattern Omissions` README section format specification.
- The six validator rules.
- The exclusion list fenced between `<!-- exclude:start -->` and `<!-- exclude:end -->`.

The awk extractor targets the pipe-delimited table inside the `blocks` fence. Each data row yields: `id`, `validator_marker`, `tier` (Mandatory / Conditional), and `omit_when`.

**`tests/skills/test-workflow-skill-pattern.sh`**

Bash script. Entry point. Responsibilities:
1. Parse the block table from the pattern doc (awk, no external tools).
2. Assert at least 12 rows were parsed (rule 6 — exits loudly if fewer).
3. Read the exclusion list from the pattern doc.
4. For each non-excluded `skills/*/SKILL.md`:
   a. Apply rule 1: mandatory block absent → FAIL.
   b. Apply rule 2: conditional absent + README lists id → pass.
   c. Apply rule 3: conditional absent + README does not list id → FAIL.
   d. Apply rule 4: conditional present + README lists id → FAIL (stale record).
   e. Apply rule 5: present blocks out of table order → FAIL.
5. Self-check fixture (rule 6): strip the block table, run parser, assert non-zero exit.
6. Emit `skills/<name>: rule<N> <block-id>` for each violation. Exit non-zero if any violations.

**`tests/skills/run-all.sh`**

Mirrors `tests/split/run-all.sh`. Discovers `tests/skills/test-*.sh` by glob, runs each, accumulates failures, prints summary, exits with accumulated code.

**`writing-skills/SKILL.md` (edit)**

The `## SKILL.md Structure` section body is replaced with a single pointer sentence: "See `skills/writing-skills/workflow-skill-pattern.md` for the canonical block structure all workflow skills must follow." No block list or block format is retained in the SKILL.md itself.

### Data Model & Flow

The 12-block table is the canonical data model. Columns:

| # | id | Block | Validator marker | Tier | Omit when |
|---|---|---|---|---|---|
| 1 | frontmatter | Frontmatter | `name:` + `description:` inside a `---` fence | Mandatory | — |
| 2 | title | Title | `^# ` verb phrase | Mandatory | — |
| 3 | purpose | Purpose | non-heading paragraph directly after the title | Mandatory | — |
| 4 | hard-gate | Hard gate | `<HARD-GATE>` | Conditional | no irreversible act precedes an approval |
| 5 | anti-pattern | Anti-pattern | `## Anti-Pattern: "` | Conditional | baseline testing surfaced no dominant rationalization |
| 6 | checklist | Checklist | `## Checklist` | Mandatory | — |
| 7 | process-flow | Process flow | `## Process Flow` plus a ` ```dot ` fence | Conditional | workflow strictly linear — no gates, no loops back |
| 8 | the-process | The process | `## The Process` | Mandatory | — |
| 9 | after-artifact | After the artifact | `## After ` | Conditional | skill produces no durable artifact |
| 10 | token-cost-monitoring | Token-cost monitoring | `## Token-cost Monitoring` | Conditional | skill never invokes a model nor dispatches |
| 11 | red-flags | Red flags | `## Red Flags` | Conditional | skill enforces no discipline an agent could rationalize past |
| 12 | key-principles | Key principles | `## Key Principles` | Mandatory | — |

**Mandatory** = cannot be omitted; a file lacking these is not a workflow skill.
**Conditional** = may be omitted with a README reason.
The ids are the join key between pattern doc, `SKILL.md`, and `README.md`.
The table sits between `<!-- blocks:start -->` and `<!-- blocks:end -->` fences so the doc can carry other tables without confusing the parser.

**README omission format (verbatim):**

```markdown
## Pattern Omissions

- `hard-gate` — skill only reads and reports; no irreversible act.
- `token-cost-monitoring` — never invokes a model nor dispatches.
```

### Error Handling

The six validator rules govern all outcome paths:

| Rule | Condition | Result |
|---|---|---|
| 1 | Mandatory block absent | FAIL — no omission possible |
| 2 | Conditional absent, README lists its id | pass |
| 3 | Conditional absent, README does not list it (or no README) | FAIL |
| 4 | Conditional PRESENT but README lists it as omitted | FAIL — stale record |
| 5 | Present blocks out of table order | FAIL |
| 6 | Block table unparseable or zero rows | FAIL loudly, never pass-by-default |

Rule 4 keeps the omission record honest as skills evolve. Rule 6 is what stops the single-source-of-truth design from silently degrading into a no-op check. Output format: one line per violation, `skills/<name>: <rule> <block-id>`, exit non-zero.

### Edge Cases

- **`skills/visual-companion/`**: excluded from validation via the pattern doc's `<!-- exclude:start -->` / `<!-- exclude:end -->` fences. The exclusion list is visible in the pattern doc, not hidden in the script (D10).
- **Short skills** (`skills/worker-healing/SKILL.md` at 59 lines): will legitimately omit most conditional blocks. The README must record each omission explicitly; the validator accepts this.
- **Exemplar non-conformance**: `skills/brainstorming/SKILL.md` itself currently lacks `## Red Flags` and uses lowercase `## Token-cost monitoring`. It is migrated in sub-project B like every other skill. No special exemption is granted.
- **Casing collision**: `## Token-cost Monitoring` (Title Case, D9) is the normalised heading. `tests/split/test-project-kickoff.sh:55` currently asserts the lowercase literal. The commit that migrates `project-kickoff` must update that test line atomically; otherwise `tests/split/run-all.sh` goes red.
- **No README exists**: treated as "README does not list the id" for all conditional blocks → rule 3 fires for each absent conditional.

## 7. Testing Strategy

**Structure tests (`tests/skills/test-workflow-skill-pattern.sh`)** — the ongoing gate. Run over all in-scope `skills/*/SKILL.md`. After sub-project B, every skill passes every rule. During sub-project B, the validator must be green after each individual skill migration commit (not only at the end of the migration series).

**Self-check fixture (rule 6)** — built into `test-workflow-skill-pattern.sh`. Creates a temporary stripped block table (zero data rows) and passes it to the parser. Asserts the validator exits non-zero and prints a loud failure message. Without this fixture, a doc edit that breaks the table fence could silently make every check pass-by-default, which is the exact failure mode the single-source-of-truth design is meant to prevent.

**Regression (`tests/split/run-all.sh`)** — must remain green throughout sub-project A (this spec) and throughout sub-project B (migration). No change to `tests/split/*.sh` is permitted by this spec; any required test-line update (e.g. the `## Token-cost monitoring` literal at line 55 of `test-project-kickoff.sh`) belongs in the sub-project B commit that migrates that skill.

Verification command for this spec's acceptance: `bash tests/skills/run-all.sh` (once US-6 is implemented) and `bash tests/split/run-all.sh` (regression).

## 8. Success Criteria

- SC-1: `skills/writing-skills/workflow-skill-pattern.md` exists, contains the 12-block table between `<!-- blocks:start -->` / `<!-- blocks:end -->` fences, the exclusion list between `<!-- exclude:start -->` / `<!-- exclude:end -->` fences, the six validator rules, and the `## Pattern Omissions` README format — all verbatim per this spec.
- SC-2: `tests/skills/test-workflow-skill-pattern.sh` exists, exits zero when run against the repo, and emits zero violation lines for any skill that has all mandatory blocks and valid omission records for any absent conditional blocks.
- SC-3: `tests/skills/test-workflow-skill-pattern.sh` exits non-zero and prints a loud failure message when given a block table with zero data rows (rule 6 self-check).
- SC-4: `tests/skills/run-all.sh` exists, runs `test-workflow-skill-pattern.sh` via glob, accumulates failure codes, and prints `ALL SKILL TESTS PASS` on success — matching the `tests/split/run-all.sh` structural idiom.
- SC-5: `skills/writing-skills/SKILL.md`'s `## SKILL.md Structure` section body contains only a pointer to `workflow-skill-pattern.md` and no competing block list.
- SC-6: `tests/split/run-all.sh` exits zero after all sub-project A changes are applied (no regression to any existing test).
- SC-7: No block identity is defined in any file other than `workflow-skill-pattern.md`; the validator script contains no hardcoded block ids or markers.
- SC-8: The validator output format is exactly `skills/<name>: <rule> <block-id>` (one line per violation); no other output format is emitted.
