---
name: backlog-refinement
description: Use when reordering the roadmap, adding newly discovered work supplied by the human, or before starting the next feature to groom and prioritize existing backlog items.
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

# Backlog Refinement

Run this workflow when reordering the roadmap, adding newly discovered work from the human, or before starting the next feature.

## Evidence Boundary

The token-cost boundary starts when this skill is announced. Capture the exact cumulative orchestrator counter scope and baseline when the harness exposes them.

**Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace** by `workspace.type` and `workspace.target`; require exactly one session entry and preserve every other session entry. Use `writing_plans.workflow_id` as the active run. Other sessions remain read-only evidence for their matching roadmap items; ambient session context never replaces the selected entry.

Read `docs/superpowers/roadmap.json` and capture its exact roadmap content hash. For every item a proposal would move, add, remove, or groom, collect approved decision evidence for each affected item from its manifest session and linked spec/plan, plus published token-cost baselines and their measured totals and record/input/output coverage. Missing evidence stays explicit.

Every D23 request carries `DECISION_RECORD=main:docs/superpower/manifest.json`, the selected workspace/workflow, roadmap path/hash, per-item decision evidence, token-baseline evidence, proposal-record path, and this instruction: “Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.” A mismatch returns blocked with reason `stale_input` and no proposal.

## Baseline Evidence Rules

Use exact measured baseline fields only. **Do not estimate missing token counts**, convert them to zero, or label a partial subtotal complete. Mark missing or incomplete evidence as unavailable or partial and carry its reason, measured subtotal, and record/input/output coverage into the proposal.

Token cost is not the sole priority signal. Approved value, dependencies, exclusions, acceptance criteria, delivery risk, and human-supplied urgency remain explicit evidence. A cost baseline may support or break a tie; it cannot override an approved dependency or invent product value.

## The Process

1. **Read the current backlog.** Read `docs/superpowers/roadmap.json`. Every item carries `slug, epic, feature, title, description, status, spec, plan, created, completed`.
<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D23` sends the Evidence Boundary, current roadmap snapshot, and only work the human explicitly adds through `superpowers-orchestrator:dispatch-agent` with `role: product_owner` and `task_type: backlog_refinement_prioritization` to propose ordering and grooming; require: “Return only a backlog proposal; never edit `roadmap.json`, `ROADMAP.html`, or product files.” The Scrum Master validates the complete proposal and applies it only after the human approves its exact diff; when there is no worker provider selected or ready, `superpowers-orchestrator:dispatch-agent` degrades to the always-available claude subagent.
<!-- riso-tech:orchestrator-split END -->

3. **Validate the proposal.** Each affected item includes `item_id`, current and proposed position, proposed field changes/addition, rationale, decision-record references, token-baseline references, value/dependency/risk evidence, confidence and unavailable evidence. Preserve exact roadmap/HTML preimages across D23; if a worker mutates either file, restore those exact bytes, reject its response, and record the violation before the Human Gate.
4. **Human Gate — backlog diff.** Write `.superpowers/runs/<workflow-id>/70-backlog-refinement/refinement-record.json`, then present the exact before/after order and every addition and grooming-field change with its evidence. Require one response: `approve | revise | reject`. A summary or approval of an older proposal is not approval of the current diff; revisions produce a complete revised diff before approval.
5. **Revalidate and apply.** Immediately before applying approved changes, reread the selected main-manifest entry, referenced decisions/baselines, and current roadmap hash. Any mismatch is `stale_input`: preserve the rejected evidence and require a new proposal and human approval. Apply only the exact approved diff to `docs/superpowers/roadmap.json`, validate the schema, regenerate `ROADMAP.html`, and update the refinement record with the resulting hash and outcome.

## Token-cost Monitoring

Use `.superpowers/runs/<workflow-id>/backlog-refinement-token-cost.jsonl`. This skill owns every D23 provider call, including retries, fallbacks, blocked results, revisions, and resumed calls:

```json
{"source":"worker","task":"D23","turn":1,"attempt":1,"agent":"codex","model":"<exact-model>","input_tokens":123,"output_tokens":45,"unavailable_reason":null}
```

`turn` identifies one request envelope, roadmap hash, and evidence snapshot. Provider retries and fallbacks increment `attempt`; a revised request, changed roadmap/evidence, or resumed proposal starts the next turn at attempt 1.

After each harness-reported main-orchestrator invocation becomes observable, append and validate one orchestrator record before the next refinement action:

```json
{"source":"orchestrator","task":"orchestrator","turn":1,"attempt":1,"agent":"claude","model":"<exact-model>","input_tokens":456,"output_tokens":78,"unavailable_reason":null}
```

Copy exact per-invocation metadata. Use monotonic cumulative-counter deltas only; after a reset, record affected counts as `null` with the reason and retain the new baseline. Otherwise keep unavailable fields `null` with a reason. **Do not estimate missing token counts** or treat them as zero. Ordinary tools get no separate record.

The historical baseline records are evidence, not current token cost: do not copy retrospective, prior-phase, or another run's usage into this file. Before the final handoff, append its orchestrator record with both counts `null` and reason `usage becomes visible only after this turn completes`. Report worker, orchestrator, and combined measured totals, unavailable reasons, full-record coverage as measured records / total records, and independent input/output field coverage. Never call a partial subtotal complete.

## Degraded Mode

<!-- riso-tech:orchestrator-split START -->
Only when the harness has no subagent capability at all, refine inline: read the same roadmap fields, propose ordering and grooming only from the existing items or work the human adds, validate it with the human, then apply only approved edits and synchronize `ROADMAP.html`.
<!-- riso-tech:orchestrator-split END -->

## Boundaries

- Never invents scope.
- Only orders and grooms what already exists or the human adds.
- Does not approve or apply unvalidated product decisions.
- D23 is read-only; only the orchestrator applies the human-approved diff.
