---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## Approved Review Boundary

The token-cost boundary starts when this skill is announced. Capture the exact cumulative orchestrator counter scope and baseline when the harness exposes them.

**Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace** by `workspace.type` and `workspace.target`; require exactly one session entry and preserve every other session entry. Require `writing_plans.workflow_id` plus approved `scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`. For feature work also require `brainstorming.scope`, `brainstorming.exclusions`, and `brainstorming.acceptance_criteria`.

Use `writing_plans.workflow_id` as the active run. Accept the exact approved decision snapshot and exact plan path and content hash handed off by the caller, plus the optional design path/hash. Ambient run IDs and another session's artifacts never override them.

Every D14, D15, and D17 request includes `DECISION_RECORD=main:docs/superpower/manifest.json`, workspace key, workflow ID, decision snapshot, plan path/hash, review scope and base/head SHAs, artifact paths, and this instruction: “Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.” The reviewer compares the selected record and current plan hash before review; a mismatch returns a blocked response with reason `stale_input` and no findings.

Before and after every review dispatch, reread the selected main-manifest entry and rehash the plan. Stale input blocks accepting findings, dispatching fixes, or returning a clean verdict.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D14` performs the task review after each `D13` implementation and each `D16` fix: call `superpowers-orchestrator:dispatch-agent` with `role: tech_lead`, `task_type: code_review_quality`, `context.base_sha` set to the exact pre-task commit recorded before the original `D13` dispatch, the approved review boundary, task brief, implementer/fix report, task diff package, and `author_agent` from the active run's `ledger.jsonl`; enforce provider diversity and require both spec-compliance and code-quality verdicts plus the finding classification contract below. Send only Critical/Important implementation defects or decision deviations to D16 and re-review at D14 until clean; route decision-change proposals to their human gate. Missing `base_sha` is malformed and must not dispatch.
<!-- riso-tech:orchestrator-split END -->

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D15` runs only when a task diff touches security-sensitive surfaces (auth/authz, input parsing or validation, secrets or credentials, dependency changes, or network boundaries): additionally call `superpowers-orchestrator:dispatch-agent` with `role: security_engineer`, `task_type: security_review`, `context.base_sha` set to the exact pre-task commit recorded before the original `D13` dispatch, `context.security_focus` set to the complete touched security surfaces and required security checks, the approved review boundary, same task artifacts, and same provider-diversity rule against `author_agent`; classify every finding and send only Critical/Important implementation defects or decision deviations to `D16` before the next D14 re-review. Route decision-change proposals to their human gate. Missing `base_sha` or `security_focus` is malformed and must not dispatch.
<!-- riso-tech:orchestrator-split END -->

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D17` runs after every task has a clean D14/D15 gate: derive `MERGE_BASE` with `git merge-base <base-branch> HEAD`, then call `superpowers-orchestrator:dispatch-agent` with `role: tech_lead`, `task_type: code_review_quality`, `context.base_sha` set to that exact `MERGE_BASE`, the approved review boundary, `MERGE_BASE..HEAD` whole-branch review package, plan/spec requirements, accumulated Minor findings, and branch `author_agent` data; enforce provider diversity and the finding classification contract. Proceed to finishing only when implementation and decision verdicts are clean; otherwise send implementation defects and decision deviations to `D18` and decision-change proposals to their human gate before re-dispatching D17. Missing `base_sha` is malformed and must not dispatch.
<!-- riso-tech:orchestrator-split END -->

## Classify Findings Before Routing

Judge a finding by its actual effect, not its severity or label:

- `implementation_defect`: the code fails an approved requirement or introduces a correctness, quality, or security defect without changing an approved value. Route `implementation_fix`.
- `decision_deviation`: the code differs from an approved value and must be aligned to that value. Route `align_implementation`.
- `decision_change_proposal`: the suggested correction would change an approved value, even when presented as a Critical/Important fix or improvement. Route `human_decision_required`.

Each finding contains type, severity, decision field names, exact approved value, observed or proposed value, evidence, and route. Return two verdicts: implementation `clean | fixes_required` and decision `none | human_decision_required`. A pending decision proposal is never a clean overall gate.

Only implementation defects and decision deviations go to D16/D18. D14/D15/D17 remain read-only. Route product scope, exclusions, or acceptance-criteria proposals to the Brainstorming Human Gate; route ordering, files, interfaces, tests, verification, or other build-only proposals to Writing Plans' Final build decision gate. When both change, Brainstorming resolves first and Writing Plans regenerates afterward.

Human rejection preserves the approved snapshot and resolves the proposal; rerun the review against it. Human approval is not permission to patch inline: the owning gate updates the selected main-manifest entry and regenerates/reapproves affected design and plan artifacts. The caller captures new hashes and must revalidate every completed task from the earliest affected task before review resumes.

## Durable Review Output

Keep each request, `review.md`, response, base/head range, decision/plan hashes, and adjudicated finding routes in the active run's existing review turn directory and `ledger.jsonl`. Git history and the current worktree remain implementation authority; review evidence never replaces them or another manifest.

## Token-cost Monitoring

Use `.superpowers/runs/<workflow-id>/requesting-code-review-token-cost.jsonl`. This skill owns every provider call for D14, D15, and D17, including retries, fallbacks, blocked results, re-reviews, and resumed reviews:

```json
{"source":"worker","task":"D14","review_scope":"task-1","turn":1,"attempt":1,"agent":"codex","model":"<exact-model>","input_tokens":123,"output_tokens":45,"unavailable_reason":null}
```

`turn` identifies one request envelope, approved snapshot, and base/head range. Provider retries and fallbacks increment `attempt`; a changed request, re-review range, or resumed review starts the next turn at attempt 1.

After each harness-reported main-orchestrator invocation becomes observable, append and validate one orchestrator record before the next review action:

```json
{"source":"orchestrator","task":"orchestrator","turn":1,"attempt":1,"agent":"claude","model":"<exact-model>","input_tokens":456,"output_tokens":78,"unavailable_reason":null}
```

Copy exact per-invocation metadata. Use monotonic cumulative-counter deltas only; after a reset, record affected counts as `null` with the reason and retain the new baseline. Otherwise keep unavailable fields `null` with a reason. **Do not estimate missing token counts** or treat them as zero. Ordinary tools get no separate record.

Do not copy this skill's usage into the caller execution ledger; Subagent-Driven Development or another caller resumes its own metering after control returns. Before the return handoff, append its orchestrator record with both counts `null` and reason `usage becomes visible only after this turn completes`. Report worker, orchestrator, and combined measured totals, unavailable reasons, full-record coverage as measured records / total records, and independent input/output field coverage. Never call a partial subtotal complete.

**1. Use the exact review range:**

For D14/D15 task reviews, record the exact pre-task SHA before dispatching D13 and reuse it unchanged for every review and fix cycle:

```bash
BASE_SHA=$(git rev-parse HEAD)  # Run before the D13 implementation dispatch
HEAD_SHA=$(git rev-parse HEAD)  # Run after the orchestrator commits D13/D16 changes
```

Keep `BASE_SHA` unchanged across D16 fix cycles; recompute only `HEAD_SHA` after each orchestrator commit.

For the D17 whole-branch review, derive the branch point directly:

```bash
MERGE_BASE=$(git merge-base <base-branch> HEAD)
HEAD_SHA=$(git rev-parse HEAD)
```

Do not reconstruct a task's base after implementation from commit messages or history position.

**2. Prepare the reviewer prompt:**

Fill the template at [code-reviewer.md](prompts/code-reviewer.md); the D14 or D17 block above supplies its dispatch scope.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Exact pre-task commit recorded before D13, or `MERGE_BASE` for D17
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**
- Fix Critical implementation issues immediately
- Fix Important implementation issues before proceeding
- Route decision-change proposals to their owning human gate
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Before dispatching Task 2: Add verification function]

BASE_SHA=$(git rev-parse HEAD)

[Task 2 worker completes; orchestrator commits the validated changes]

You: Let me request code review before proceeding.

HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing required date validation
    Type: implementation_defect
    Decision fields: brainstorming.acceptance_criteria
    Route: implementation_fix
    Minor: Magic number (100) for reporting interval
  Assessment: Changes required

You: [Dispatch D16 fix subagent with the Important finding; record the Minor for D17]
[Worker fixes issues and reports passing tests]
[Orchestrator commits the validated fix and regenerates the task review package]
[Dispatch D14 re-review with the original BASE_SHA and updated HEAD_SHA]
[D14 returns clean]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**
- Review after each task or at natural checkpoints
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](prompts/code-reviewer.md)
