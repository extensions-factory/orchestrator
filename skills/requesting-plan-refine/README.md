# Requesting Plan Refine

## Description

Runs an independent, read-only review of a plan against the selected workspace's approved final build decision and produces decision-aware findings for Receiving Plan Refine.

## Inputs

- The current workspace and its exactly matching session in the single `main:docs/superpower/manifest.json`.
- The complete approved `writing_plans` record and its workflow ID.
- Exact current-workspace `plan.md` and optional `design.md` paths handed off by Writing Plans, their content hashes, and the plan author's provider from the run ledger.
- Exact per-invocation or comparable cumulative token metadata exposed by the harness/provider.

## Durable Output

Each D11 turn writes a unique `.superpowers/runs/<workflow-id>/30-plan/plan-refine/findings-<turn>.md`. Findings distinguish plan defects, deviations from approved decisions, and proposed decision changes. This skill reads the manifest but never edits it or the plan.

## Token-cost Monitoring

`.superpowers/runs/<workflow-id>/requesting-plan-refine-token-cost.jsonl` stores source-tagged records for every D11 worker call and every harness-reported main-orchestrator invocation. Missing counts remain `null` with reasons. The handoff reports worker, orchestrator, and combined measured totals and coverage without presenting partial values as complete.

## Human Decisions

No approved decision changes here. A plan deviation is routed back toward the approved value; a suggested change to scope, exclusions, ordering, files, interfaces, tests, or verification is labeled `human_decision_required` for the owning Writing Plans gate.

## Handoff

Before invoking Receiving Plan Refine, the orchestrator rereads the selected session and rehashes the plan and spec. Stale findings remain evidence but are not handed off; D11 runs again against current inputs. A current handoff includes the workspace key, workflow ID, decision snapshot, artifact hashes, findings path, and token-cost report.

## Legend

- `◆ D11` — independent plan-review dispatch
- `○` — orchestrator preparation or result routing
- `◇` — human execution/refinement choice
- `↻` — another independent review pass

## Lifecycle Tree

```text
REQUEST PLAN REFINE
│
├── ○ Start token-cost boundary and select current manifest session
│   └── require complete writing_plans decision record + workflow_id
│
├── ○ Resolve handed-off plan/spec paths inside the current workspace
│   └── snapshot decision record + plan/spec content hashes
│
├── ○ Resolve active run plan-refine directory
│   └── scripts/run-paths.mjs task --phase plan --task plan-refine
│
├── ○ Fill prompts/plan-reviewer.md
│   ├── PLAN_FILE
│   ├── SPEC_FILE or explicit absence
│   ├── workspace root/key + approved writing_plans snapshot
│   ├── plan/spec hashes
│   └── FINDINGS_FILE
│
├── ◆ D11 independent review
│   ├── role: tech_lead
│   ├── task_type: code_review_quality
│   ├── use author_agent from ledger.jsonl
│   ├── enforce reviewer provider diversity
│   └── write unique findings-<turn>.md
│
├── ○ Receive only findings path and one-line summary
│
├── ○ Reread decision record and rehash artifacts
│   ├── changed → retain stale findings, redispatch D11 ↻
│   └── unchanged → continue
│
├── ○ Report worker + orchestrator token usage and combined coverage
│
├── use-tool
│   ├── Git rev-parse --show-toplevel
│   ├── scripts/run-paths.mjs
│   ├── superpowers-orchestrator:dispatch-agent [D11]
│   └── superpowers-orchestrator:receiving-plan-refine
│
├── use-file
│   ├── read: prompts/plan-reviewer.md
│   ├── read: plan.md + optional design.md
│   ├── read: active run ledger.jsonl for author_agent
│   └── create: 30-plan/plan-refine/findings-<turn>.md
│
└── ○ Invoke receiving-plan-refine
    └── human later chooses:
        ├── Refine again → D11 ↻
        └── Execute      → execution workflow
```

## File Lifecycle Tree

```text
PLAN REVIEW FILES
│
├── Skill package [tracked]
│   └── skills/requesting-plan-refine/
│       ├── SKILL.md
│       ├── README.md
│       └── prompts/
│           └── plan-reviewer.md
│
├── Durable inputs [tracked, read]
│   ├── main:docs/superpower/manifest.json
│   │   └── sessions[current workspace].writing_plans [read-only]
│   └── docs/superpowers/features/<feature-slug>/
│       ├── design.md [when present]
│       └── plan.md
│
└── Review evidence [ignored, created]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        ├── requesting-plan-refine-token-cost.jsonl
        └── 30-plan/
            ├── plan-refine/
            │   └── findings-<turn>.md
            └── <task>/turns/<NNN>-review/
                ├── request.json
                ├── review.md
                └── response.json
```
