---
name: sprint-retrospective
description: Use when finishing-a-development-branch has completed and the Scrum team needs to inspect delivery evidence, agree process improvements with the human, and prepare approved skill-work without changing code.
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

# Sprint Retrospective

Run this workflow after `finishing-a-development-branch` completes. The retrospective produces action items only; it makes no code changes.

## The Process

1. **Measure the sprint.** Read `.superpowers/ledger.jsonl` and compute total dispatches, blocked count, needs_revision loops, and degradation events. Select a concise ledger excerpt that supports those metrics.
<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D20` sends the process review through `dispatch-agent` with `role: agile_coach` and `task_type: retrospective_process_improvement`, placing the computed metrics and supporting ledger excerpt in `context.input_artifacts`; the worker recommends evidence-backed process improvements without implementing them, and when there is no worker provider selected or ready, `dispatch-agent` degrades to the always-available claude subagent.
<!-- riso-tech:orchestrator-split END -->

3. **Validate with the human.** The Scrum Master presents the recommendations and their evidence to the human, then records only the process improvements the human approves.
4. **Route approved improvements.** Send each approved skill or workflow improvement into `writing-skills`; never edit skills directly from this retrospective.

## Degraded Mode

<!-- riso-tech:orchestrator-split START -->
Only when the harness has no subagent capability at all, run the retrospective inline: calculate the same metrics, prepare recommendations from the ledger excerpt, and validate them with the human before routing approved skill work into `writing-skills`.
<!-- riso-tech:orchestrator-split END -->

## Boundaries

- Produces action items only.
- Makes no code changes.
- Does not decide process changes without human approval.
