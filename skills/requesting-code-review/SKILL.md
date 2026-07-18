---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

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
**Dispatch:** `D14` performs the task review after each `D13` implementation and each `D16` fix: call `superpowers-orchestrator:dispatch-agent` with `role: tech_lead`, `task_type: code_review_quality`, `context.base_sha` set to the exact pre-task commit recorded before the original `D13` dispatch, the task brief, implementer/fix report, task diff package, and `author_agent` from `.superpowers/ledger.jsonl`; enforce provider diversity and require both spec-compliance and code-quality verdicts, sending Critical/Important findings to D16 and re-reviewing at D14 until clean. Missing `base_sha` is malformed and must not dispatch.
<!-- riso-tech:orchestrator-split END -->

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D15` runs only when a task diff touches security-sensitive surfaces (auth/authz, input parsing or validation, secrets or credentials, dependency changes, or network boundaries): additionally call `superpowers-orchestrator:dispatch-agent` with `role: security_engineer`, `task_type: security_review`, `context.base_sha` set to the exact pre-task commit recorded before the original `D13` dispatch, `context.security_focus` set to the complete touched security surfaces and required security checks, the same task artifacts, and the same provider-diversity rule against `author_agent`; send actionable findings to `D16` before the next D14 re-review. Missing `base_sha` or `security_focus` is malformed and must not dispatch.
<!-- riso-tech:orchestrator-split END -->

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D17` runs after every task has a clean D14/D15 gate: derive `MERGE_BASE` with `git merge-base <base-branch> HEAD`, then call `superpowers-orchestrator:dispatch-agent` with `role: tech_lead`, `task_type: code_review_quality`, `context.base_sha` set to that exact `MERGE_BASE`, the `MERGE_BASE..HEAD` whole-branch review package, plan/spec requirements, accumulated Minor findings, and branch `author_agent` data; enforce provider diversity, proceed to finishing only when the whole-branch review is clean, and otherwise send all findings to `D18` before re-dispatching D17. Missing `base_sha` is malformed and must not dispatch.
<!-- riso-tech:orchestrator-split END -->

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

Fill the template at [code-reviewer.md](code-reviewer.md); the D14 or D17 block above supplies its dispatch scope.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Exact pre-task commit recorded before D13, or `MERGE_BASE` for D17
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
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
    Important: Missing progress indicators
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

See template at: [code-reviewer.md](code-reviewer.md)
