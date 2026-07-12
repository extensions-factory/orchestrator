---
name: backlog-refinement
description: Use when reordering the roadmap, adding newly discovered work supplied by the human, or before starting the next feature to groom and prioritize existing backlog items.
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

# Backlog Refinement

Run this workflow when reordering the roadmap, adding newly discovered work from the human, or before starting the next feature.

## The Process

1. **Read the current backlog.** Read `docs/superpowers/roadmap.json`. Every item carries `slug, epic, feature, title, description, status, spec, plan, created, completed`.
<!-- riso-tech:orchestrator-split START -->
2. **Dispatch prioritization.** Always dispatch via `dispatch-agent` with `role: product_owner` and `task_type: backlog_refinement_prioritization`. Ask the product owner to propose ordering and grooming for the existing items and any work the human explicitly adds. When there is no worker provider selected or ready, `dispatch-agent` resolves provider availability to the always-available claude subagent; that is not an inline exception.
3. **Validate with the human.** The Scrum Master presents the proposed ordering and grooming to the human and accepts only the ordering and scope the human approves.
4. **Apply approved backlog changes.** The Scrum Master applies the approved edits to `docs/superpowers/roadmap.json` and keeps `ROADMAP.html` in sync.
<!-- riso-tech:orchestrator-split END -->

## Degraded Mode

<!-- riso-tech:orchestrator-split START -->
Only when the harness has no subagent capability at all, refine inline: read the same roadmap fields, propose ordering and grooming only from the existing items or work the human adds, validate it with the human, then apply only approved edits and synchronize `ROADMAP.html`.
<!-- riso-tech:orchestrator-split END -->

## Boundaries

- Never invents scope.
- Only orders and grooms what already exists or the human adds.
- Does not approve or apply unvalidated product decisions.
