---
name: receiving-plan-refine
description: Use when independent plan-review findings are ready to evaluate before execution
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

# Receiving Plan Refine

## Overview

Verify review findings, apply only corrections that preserve the approved build decision, and send proposed decision changes back to their owning human gate.

**Core principle:** Reviewer authority never overrides human-approved decisions.

**Announce at start:** "I'm using the receiving-plan-refine skill to evaluate the refine findings."

The token-cost boundary starts when this skill is announced. Capture the exact cumulative orchestrator counter scope and baseline when the harness exposes them.

## Bind the Current Review

**Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace** by `workspace.type` and `workspace.target`. Require exactly one session entry plus `writing_plans.workflow_id` and approved `scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`. Use that workflow ID, not conflicting ambient state. This skill never edits the manifest and must preserve every session entry.

Accept only the exact handed-off plan, spec, and findings paths, approved `writing_plans` snapshot, plan/spec hashes, workspace key, and workflow ID from `superpowers-orchestrator:requesting-plan-refine`. Resolve plan/spec inside the current workspace and findings at `.superpowers/runs/<workflow-id>/30-plan/plan-refine/findings-<turn>.md`; recover author/reviewer provenance from that active run's ledger.

Before reading findings, compare the selected `writing_plans` object with the handed-off snapshot and compare the current hashes with the handed-off hashes before reading findings. Hash the findings file before reading it and store that input hash in the resolution. On resume, an existing resolution for this turn replaces only the original plan hash with its last completed after-plan hash; when exactly one trailing entry is `applying`, also allow its verified intended result so the checkpoint can advance to `applied`. Its decision snapshot, spec hash, and workspace key must still match the handoff, and its findings hash must match the resolution's input hash. Any other decision mismatch returns to Writing Plans' Final build decision gate; any other artifact mismatch retains stale evidence and invokes `superpowers-orchestrator:requesting-plan-refine` once for a fresh turn.

Every downstream handoff must include: “Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.”

<!-- riso-tech:orchestrator-split START -->
**Inline validation:** evaluating plan-refine findings is a VALIDATE-equivalent judgment call the orchestrator makes itself and is never dispatched.
<!-- riso-tech:orchestrator-split END -->

## Evaluate and Record

Write `.superpowers/runs/<workflow-id>/30-plan/plan-refine/resolution-<turn>.md`; never overwrite another turn. Initialize it with the handoff identities and `status: in_progress`. Record every finding's location, reported type/route, verified evidence, affected decision fields, disposition (`applying`, `applied`, `declined`, or `human_decision_required`), reason, and plan hashes.

Before each plan edit, durably record `applying`, the before-plan hash, and the exact intended correction. After the edit, verify it and record `applied` plus the after-plan hash. On resume, a matching before hash means the edit is pending; a matching verified result completes the checkpoint; any other state is stale and stops processing. This write-ahead order prevents an untracked receiver edit.

For every finding, verify the claim against the plan, optional spec, codebase, and complete approved decision record. Determine the proposed edit's actual effect regardless of its reported type or route:

- A valid `plan_defect` with route `plan_fix` may be applied only when the resulting plan still matches every approved field.
- A valid `decision_deviation` with route `align_plan` may be corrected only toward the exact approved value.
- Any edit that would make the plan differ from an approved value or require changing one is `human_decision_required`, including a mislabelled `decision_change_proposal`. Record the current and proposed values; do not apply it.
- Decline an invalid finding with concrete evidence. Never silently omit one.

Apply approval-preserving corrections to `plan.md`. If it changes, record HTML regeneration as pending, regenerate `plan.html` using the Writing Plans conventions, then self-review both artifacts for source-free instructions, internal consistency, and exact agreement with all approved fields. Record the final plan hash, HTML hash, regeneration status, and `status: ready`. On resume, pending HTML regeneration reruns from the checkpointed plan. This skill never edits the manifest.

If any `human_decision_required` item remains, do not offer Refine or Execute. Invoke `superpowers-orchestrator:writing-plans` exactly once at Writing Plans' Final build decision gate with the selected workspace/workflow, complete current decision record, proposed values and affected fields, artifact paths, resolution path, provenance, and token-cost report.

## Token-cost Monitoring

Use `.superpowers/runs/<workflow-id>/receiving-plan-refine-token-cost.jsonl`:

```json
{"source":"orchestrator","task":"orchestrator","turn":1,"attempt":1,"agent":"claude","model":"<exact-model>","input_tokens":456,"output_tokens":78,"unavailable_reason":null}
```

After each harness-reported main-orchestrator invocation becomes observable, append and validate one record before the next action; on resume continue after the highest recorded turn. Copy exact per-invocation metadata. Use monotonic cumulative-counter deltas only; after a reset, record affected counts as `null` with the reason and retain the new baseline. Otherwise keep unavailable fields `null` with a reason. **Do not estimate missing token counts** or treat them as zero.

This phase dispatches no workers. Do not copy D11 worker or Requesting Plan Refine costs into this file; ordinary non-model tool calls are included in orchestrator usage and get no separate record.

Before rendering any downstream handoff, append its orchestrator record with both counts `null` and reason `usage becomes visible only after this turn completes`. Report measured input/output totals, unavailable reasons, full-record coverage as measured records / total records, and input/output field coverage independently. Never call a partial subtotal complete.

## Handoff

Before any route, reread the selected session entry and rehash the plan, optional spec, and HTML companion. Require the decision snapshot to remain current, the spec to retain its handed-off hash, the plan/HTML to match the recorded resolution and approved fields, and the resolution file to cover every finding. Stale state blocks handoff.

When no human decision is pending, report applied/declined counts and the resolution path, then ask the human to choose Refine or Execute:

- **Refine:** invoke `superpowers-orchestrator:requesting-plan-refine` exactly once.
- **When the harness supports subagents, Execute:** invoke `superpowers-orchestrator:subagent-driven-development` exactly once.
- **Only when the harness has no subagent capability, Execute:** invoke `superpowers-orchestrator:executing-plans` exactly once.

Send exactly one selected route the workspace key, workflow ID, current decision snapshot, plan/spec/HTML paths and hashes, findings and resolution paths, author/reviewer provenance, and receiving token-cost report. Before invoking it, record a stable `handoff_id` (`<workflow-id>:plan-refine:<turn>:<final-plan-hash>`), selected route, payload hash, and `status: prepared` in the resolution. Pass `handoff_id` as the downstream idempotency key; retries and resumes reuse that key and route, and downstream acceptance changes the status to `handed_off`. Never select a second route or start a second logical handoff.

## Red Flags

**Never:**
- Apply a finding because the reviewer labelled it `plan_fix`
- Edit an approved decision or the manifest
- Read or apply stale findings
- Hand off before every finding has a durable disposition
- Offer Refine or Execute while a decision change awaits human approval
