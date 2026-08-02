---
name: writing-plans
description: Use when a specification or requirements define a multi-step implementation before code changes begin
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document the exact files, interfaces, behavior, tests, commands, and expected results for bite-sized tasks without writing implementation or test source code. DRY. YAGNI. TDD. Orchestrator-owned task commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

The token-cost boundary starts when this skill is announced. Before any other planning action, capture the exact cumulative orchestrator counter scope and baseline when the harness exposes them. **Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace** by `workspace.type` and `workspace.target`; require exactly one session entry and preserve all others. A missing or duplicate match returns to the Session Gate.

Read all approved upstream records present in that selected entry: `project_kickoff`, `brainstorming`, and `designing_ui`. A project-scaffold plan requires a complete `project_kickoff` bundle; a feature plan requires a complete `brainstorming` bundle; a UI plan also requires a complete `designing_ui` bundle. Complete means `workflow_id` plus every field required by that upstream skill's handoff contract. Verify the handed-off design artifacts match those records. Do not infer missing approvals from an artifact or read decisions from another session.

Reuse `writing_plans.workflow_id` and its run directory on resume. Otherwise reuse the calling workflow ID, or initialize one for a direct invocation, and write it to `writing_plans.workflow_id` in the selected entry. A partial `writing_plans` record never counts as approved.

Every D10 request and downstream handoff must include: “Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.”

**Context:** If working in an isolated worktree, it should have been created via the `superpowers-orchestrator:using-git-worktrees` skill during brainstorming; continue writing the plan in that same workspace.

**Git ownership:** Implementation workers never commit or push; they edit files, run tests, and report. The orchestrator owns Git bookkeeping after each successful worker response or successful inline task execution with passing tests.

**Save plans to:** `docs/superpowers/features/<feature-slug>/plan.md`
- (User preferences for plan location override this default)

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D10` dispatches plan authoring through `superpowers-orchestrator:dispatch-agent` with `role: tech_lead` and `task_type: sprint_planning`; from the selected session's approved decisions and matching spec, the worker writes the plan and HTML companion, using `skills/writing-plans/templates/plan-template.md` for the plan and `skills/writing-plans/templates/plan-companion-template.html` for the HTML; remove the sample plan block, replace `{{TITLE}}` and `{{CONTENT}}` with the plan title and complete rendered plan, rendering checkboxes as a readable checklist and regenerating the companion whenever the plan changes, then return both plus the seven-field final build decision for the orchestrator's Self-Review; write them inline only if the harness has no subagent capability at all.
<!-- riso-tech:orchestrator-split END -->

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Final Build Decision

Derive one concrete bundle from the approved upstream records and plan:

- `scope` — behavior this plan delivers
- `exclusions` — behavior this plan deliberately does not deliver
- `ordering` — ordered Foundation/User Story/task sequence and dependencies
- `files` — exact create/modify paths and each responsibility
- `interfaces` — exact interface names, inputs, outputs, and consumers
- `tests` — exact test paths, cases, inputs, assertions, and failing commands
- `verification` — exact commands or user flows and observable expected results

The plan and HTML companion must express this bundle without contradicting upstream decisions. D10 returns the proposed bundle but never writes the manifest; the orchestrator records it only after human approval.

## Organize Tasks Under User Stories

Group the plan's Tasks under **User Story (US)** headings. Each US is one
**complete vertical slice** — a single service/feature that works end-to-end
(data + logic + UI it needs), not a technical layer.

- One US = one feature. Don't mix several features into one US.
- Never slice by layer: `US-1 data types`, `US-2 logic`, `US-3 UI` is wrong —
  none is usable alone. Slice by feature instead.
- A US contains its Tasks; the Tasks keep their bite-sized TDD steps.

Use `## US-N: [feature name]` headings, with that US's `### Task N` entries
nested beneath. An optional refine pass (`superpowers-orchestrator:requesting-plan-refine`) can audit
this slicing after the plan is written, so getting the US boundaries roughly
right here saves a round trip.

<!-- riso-tech:orchestrator-split START -->
- US IDs MUST reuse the spec's User Story IDs — the plan's `US-1` implements
  the spec's `US-1`; do not renumber. Every spec US gets a plan section.
- Close every US section with a `**US-N Checkpoint:**` block: the exact
  command or user action demonstrating that story end-to-end, with expected
  observable output covering each GIVEN/WHEN/THEN acceptance criterion from
  the spec (see `templates/plan-template.md`).
<!-- riso-tech:orchestrator-split END -->

## Foundation Section (Optional)

If some work blocks MORE THAN ONE user story (project scaffold, shared
schema, shared data layer), put it in a `## Foundation` section before the
first US, using the same task format. Setup needed by a single story stays
folded into that story's tasks, per Task Right-Sizing. Omit the section
entirely when nothing qualifies — it is not a setup dumping ground.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Define the failing test behavior" - step
- "Run it to make sure it fails" - step
- "Implement the specified behavior" - step
- "Run the tests and make sure they pass" - step

Each task ends with a labeled orchestrator-only Git bookkeeping block. It preserves the exact paths and commit message without making commit work part of the worker's steps.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development when the harness supports subagents; use superpowers-orchestrator:executing-plans only when the harness has no subagent capability. Steps use checkbox (`- [ ]`) syntax for tracking.

<!-- riso-tech:orchestrator-split START -->
**Spec:** `docs/superpowers/features/<feature-slug>/design.md`
<!-- riso-tech:orchestrator-split END -->

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

<!-- riso-tech:orchestrator-split START -->
## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- [One bullet per User Story — what a user can concretely do once it ships. Prefix with the story ID: "US-1: users can …"]

### Artifacts

- [Key files/modules/APIs created or changed, and the role of each]

### How to see it working

- [Exact command or user flow + observable output demonstrating the whole feature end-to-end — distinct from the per-US checkpoints]
<!-- riso-tech:orchestrator-split END -->

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

`skills/writing-plans/templates/plan-template.md` is the single source of
truth for the exact task schema. Copy its complete `Task N` block for every
task; do not recreate or simplify it. Every task MUST carry a valid
`task_type` from `sdlc-model-routing.json` so
`superpowers-orchestrator:dispatch-agent` can resolve its model/provider.
After a successful worker response or successful inline task execution with
passing tests, the orchestrator performs the template's Git bookkeeping before
review; the worker never commits.

## No Placeholders

Every step must contain the exact decision an engineer needs without source code. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" without exact cases, inputs, assertions, and commands
- "Similar to Task N" instead of restating the exact task contract
- Implementation steps without exact targets, behavior, rules, and interfaces
- References to types, functions, or methods not defined in any task
- Source-code snippets or fenced implementation/test code

**Plans must not contain implementation or test source-code blocks.** Source code belongs to execution, where the implementer can inspect the live repository, write a failing test, and produce the minimal implementation. Shell commands and expected terminal output remain required planning evidence.

## Remember
- Exact file paths always
- Exact interfaces, behavior, test cases, and assertions in prose
- Exact commands with expected output
- No implementation or test source code
- DRY, YAGNI, TDD, orchestrator-owned task commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

<!-- riso-tech:orchestrator-split START -->
**task_type self-review check:** every task has a `task_type` whose value is one of the 16 in `sdlc-model-routing.json`. Flag any task missing a valid `task_type` and fix it.
<!-- riso-tech:orchestrator-split END -->

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

<!-- riso-tech:orchestrator-split START -->
**4. Template check:** Does the plan follow `skills/writing-plans/templates/plan-template.md`? `**Spec:**` line, Expected Outcome section, `**Depends on:**` on every task, a Checkpoint closing every US section.

**5. Traceability check:** Every spec `US-n` has a matching plan `US-n` section; every US Checkpoint covers that story's GIVEN/WHEN/THEN acceptance criteria; every "Working behavior" bullet in Expected Outcome traces to a US.
<!-- riso-tech:orchestrator-split END -->

**6. Decision check:** The plan and HTML companion express the proposed `scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`; they contain no implementation or test source code and do not contradict the selected session's upstream approvals.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Human Gate — Final build decision

After self-review, present `scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification` together. The human must explicitly approve or revise all seven; “looks fine, execute” is not approval unless the complete bundle was presented in that turn. Scope, ordering, files, tests, and verification must be non-empty. Exclusions and interfaces may be empty only when the human explicitly approves none.

Write the approved bundle under `writing_plans` in the selected main-manifest session, preserving `workflow_id`, all upstream records, and every other session. **Do not offer Refine or Execute until this approval is recorded.** If any approved value changes later, return to this gate, update only the selected session, regenerate and self-review both plan artifacts, and obtain approval again before continuing.

## Token-cost monitoring

Use `.superpowers/runs/<workflow-id>/writing-plans-token-cost.jsonl` for both sources. After every D10 provider attempt, append and validate one worker record, retaining retries, revisions, blocked results, and fallbacks:

```json
{"source":"worker","task":"D10","turn":1,"attempt":1,"agent":"codex","model":"<exact-model>","input_tokens":123,"output_tokens":45,"unavailable_reason":null}
```

`turn` is the D10 request-envelope turn. `attempt` starts at 1 and increments for every same-turn provider call, including same-provider retries and fallbacks; a revision or blocked reroute uses the next turn with attempt 1.

After each harness-reported main-orchestrator invocation becomes observable, append and validate one orchestrator record before the next action; on resume continue at the highest recorded turn plus one:

```json
{"source":"orchestrator","task":"orchestrator","turn":1,"attempt":1,"agent":"claude","model":"<exact-model>","input_tokens":456,"output_tokens":78,"unavailable_reason":null}
```

Copy exact per-invocation metadata. For comparable cumulative counters, use only monotonic snapshot deltas; after a reset, record nulls with the reason and retain the new baseline. Otherwise set unavailable counts to `null` with `unavailable_reason`. **Do not estimate missing token counts** or treat them as zero. Ordinary non-model tool calls are included in orchestrator usage and get no separate record.

Before rendering either downstream handoff, append its orchestrator record with null counts and reason `usage becomes visible only after this turn completes`. Report worker, orchestrator, and combined measured totals, unavailable reasons, and coverage as measured records / total records for each source and combined. A measured record has both token counts; also report input-field and output-field coverage independently so a partial record is visible. Never label a partial subtotal complete.

## Execution Handoff

Before either handoff, reread the selected session entry from `main:docs/superpower/manifest.json`. Require `writing_plans.workflow_id` and all seven approved fields, verify both plan artifacts match them and the upstream records, and include the token-cost report plus workspace-aware manifest instruction. Return to the Human Gate on any mismatch.

<!-- riso-tech:orchestrator-split START -->
**User Review Gate:**
After the final build decision is approved and recorded, ask the user to choose:

> "Plan complete and saved to `docs/superpowers/features/<feature-slug>/plan.md`. Two options:
>
> 1. Refine — get an independent review pass (gaps, ambiguity, User Story slicing) before execution
>
> 2. Execute — go straight to execution
>
> Which would you like?"

**If Refine chosen:**
- Invoke exactly once. **REQUIRED SUB-SKILL:** Use `superpowers-orchestrator:requesting-plan-refine`

**If Execute chosen**, select by harness capability, not user preference:
<!-- riso-tech:orchestrator-split END -->

**When the harness supports subagents:**
- Invoke exactly once. **REQUIRED SUB-SKILL:** Use superpowers-orchestrator:subagent-driven-development
- Fresh subagent per task + two-stage review

**Only when the harness has no subagent capability:**
- Invoke exactly once. **REQUIRED SUB-SKILL:** Use superpowers-orchestrator:executing-plans
- Batch execution with checkpoints for review
