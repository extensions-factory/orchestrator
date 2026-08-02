---
name: executing-plans
description: Use when executing a written implementation plan in a separate session whose harness has no subagent capability
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (Claude Code, Codex CLI, Codex App, and Copilot CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use superpowers-orchestrator:subagent-driven-development instead of this skill.

## Approved Execution Boundary

The token-cost boundary starts when this skill is announced. Capture the exact cumulative orchestrator counter scope and baseline when the harness exposes them.

**Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace** by `workspace.type` and `workspace.target`; require exactly one session entry and preserve every other session entry. Require `writing_plans.workflow_id` plus approved `scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`. For feature work also require `brainstorming.scope`, `brainstorming.exclusions`, and `brainstorming.acceptance_criteria`.

Use `writing_plans.workflow_id` as the active run. Accept only the exact plan path and content hash handed off by Writing Plans or Receiving Plan Refine, resolve it inside the current worktree, and verify it against the selected records. Capture the exact approved decision snapshot, workspace key, plan path/hash, and optional design path/hash. Ambient run IDs and another session's artifacts never override them.

On start or resume, reread the selected main-manifest entry and rehash the plan. A mismatch is blocked with reason `stale_input`; do not edit, commit, or mark a task complete.

## The Process

### Step 1: Load and Review Plan
1. Establish the Approved Execution Boundary
2. Read the approved plan file
3. Review critically - identify any questions or concerns about the plan
4. If concerns: Raise them with your human partner before starting
5. If no concerns: Create todos for the plan items and proceed

### Step 2: Execute Tasks

For each task:
1. Revalidate the boundary and mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Revalidate the boundary before Git bookkeeping
4. Run verifications as specified
5. Revalidate the boundary after verification, then commit and mark as completed

Before each task, before Git bookkeeping, after verification, and before the finishing handoff, reread the selected main-manifest entry and rehash the plan. Any mismatch returns `stale_input` and blocks bookkeeping, completion, and later tasks.

### Step 3: Complete Development

After all tasks complete and verified:
- Revalidate the approved boundary and durable checkpoints
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers-orchestrator:finishing-a-development-branch
- Pass the workspace key, workflow ID, decision-record path and snapshot, plan/design paths and hashes, progress file, verification evidence, and token-cost report
- Follow that skill to verify tests, present options, execute choice

## Decision Changes Stop Execution

Judge a proposed edit by its actual effect, not its label. If it changes any approved Brainstorming or Writing Plans field, record a `decision_change_proposal` with affected fields, exact current values, proposed values, evidence, and originating task.

For a decision proposal, do not edit code, the plan, or the manifest and do not commit. Route product scope, exclusions, or acceptance-criteria changes to the Brainstorming Human Gate. Route ordering, files, interfaces, tests, verification, or other build-only changes to Writing Plans' Final build decision gate. When both change, Brainstorming resolves first and Writing Plans regenerates afterward.

Human rejection resumes against the unchanged snapshot. Human approval is not permission to patch inline: the owning gate updates the selected main-manifest entry and regenerates/reapproves affected design and plan artifacts. Capture the new hashes and revalidate every completed task against the new decisions and plan, resuming at the earliest affected task.

## Durable Progress

Append task checkpoints to `.superpowers/runs/<workflow-id>/executing-plans-progress.jsonl` with task ID, status, decision/plan hashes, pre/post commit SHAs, verification evidence, and detail.

Git history and the current worktree are authoritative. Accept a completed checkpoint only when its workflow/hashes match, its commit is reachable from `HEAD`, and its verification evidence belongs to the same run. On disagreement, resume at the earliest unverified task; never trust or create another `manifest.json`.

## Token-cost Monitoring

Use `.superpowers/runs/<workflow-id>/executing-plans-token-cost.jsonl`. This mode dispatches no workers, so worker usage is not applicable. After each harness-reported main-orchestrator invocation becomes observable, append and validate one record before the next action:

```json
{"source":"orchestrator","task":"orchestrator","turn":1,"attempt":1,"agent":"claude","model":"<exact-model>","input_tokens":456,"output_tokens":78,"unavailable_reason":null}
```

Copy exact per-invocation metadata. Use monotonic cumulative-counter deltas only; after a reset, record affected counts as `null` with the reason and retain the new baseline. Otherwise keep unavailable fields `null` with a reason. **Do not estimate missing token counts** or treat them as zero. Ordinary tools get no separate record.

Before the finishing handoff, append its orchestrator record with both counts `null` and reason `usage becomes visible only after this turn completes`. Do not copy nested Finishing a Development Branch usage into this file; that skill owns its invocations. Report worker as not applicable, orchestrator and combined measured totals, unavailable reasons, full-record coverage as measured records / total records, and independent input/output field coverage. Never call a partial subtotal complete.

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

<!-- riso-tech:orchestrator-split START -->
**Inline-only degraded mode.** Only when the harness has no subagent capability at all may a separate session run tasks inline with `superpowers-orchestrator:executing-plans`. A separate session does not bypass dispatch: when the harness supports subagents, provider unavailable/not-ready/failure stays inside `superpowers-orchestrator:dispatch-agent`, which walks `recommended_models[]` in rank order and ends with the always-available Claude subagent; then use `superpowers-orchestrator:subagent-driven-development`.
<!-- riso-tech:orchestrator-split END -->

**Required workflow skills:**
- **superpowers-orchestrator:using-git-worktrees** - Ensures the isolated workspace: verifies the current one, resumes the brainstorming-created one, or creates it when none exists; Step 0/0.5 prevent duplicate creation.
- **superpowers-orchestrator:writing-plans** - Creates the plan this skill executes
- **superpowers-orchestrator:finishing-a-development-branch** - Complete development after all tasks
