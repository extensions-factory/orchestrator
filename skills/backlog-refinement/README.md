# Backlog Refinement

## Description

Produces evidence-backed roadmap ordering and grooming proposals from existing backlog items or work explicitly supplied by the human.

## Inputs

- The current workspace and matching session in the single `main:docs/superpower/manifest.json`, plus read-only approved decisions for affected roadmap items.
- Exact `roadmap.json` snapshot/hash, linked specs/plans, and human-supplied additions.
- Published token-cost baselines with measured totals, coverage, scope, and unavailable reasons.

## Durable Output

`70-backlog-refinement/refinement-record.json` retains the complete proposal diff, decision/baseline evidence, human disposition, stale checks, applied roadmap hash, and token coverage. Current D23 worker and orchestrator usage is stored separately in `backlog-refinement-token-cost.jsonl`.

## Human Decisions

The worker proposes only. The human approves, revises, or rejects the exact before/after order and every addition or grooming-field change before the orchestrator edits `roadmap.json` and regenerates `ROADMAP.html`.

## Handoff

Return the approved/rejected proposal, evidence quality, resulting roadmap hash or stale blocker, synchronized HTML result, and worker/orchestrator token report. Unapproved or stale proposals leave product files unchanged.

## Legend

- `◆` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human approval gate
- `↻` — repeat the refinement cycle

## Lifecycle Tree

```text
BACKLOG REFINEMENT
│
├── ○ Select current main-manifest session
│   └── preserve all other sessions as read-only evidence
│
├── ○ Read and hash docs/superpowers/roadmap.json
│   ├── preserve existing product scope
│   └── accept new work only when supplied by the human
│
├── ○ Collect per-item evidence
│   ├── approved decision records + linked spec/plan
│   └── measured token baselines + coverage/unavailable reasons
│
├── ◆ D23 propose ordering and grooming
│   ├── role: product_owner
│   ├── task_type: backlog_refinement_prioritization
│   ├── input: roadmap snapshot + decisions + baselines + additions
│   └── output: read-only complete proposal diff
│
├── ○ Validate the worker proposal
│
├── ◇ Human approves exact order/grooming diff?
│   ├── reject → record outcome
│   ├── revise → complete revised diff ↻
│   └── approve → revalidate inputs
│
├── ◇ Roadmap/decision/baseline inputs unchanged?
│   ├── no  → stale_input; new proposal and approval ↻
│   └── yes → apply
│
├── ○ Apply only approved changes
│   ├── update roadmap.json
│   ├── regenerate ROADMAP.html
│   └── record resulting hash + token report
│
├── use-tool
│   ├── superpowers-orchestrator:dispatch-agent
│   └── roadmap renderer defined by brainstorming/roadmap.md
│
├── use-file
│   ├── read/write: docs/superpowers/roadmap.json
│   ├── write: docs/superpowers/ROADMAP.html
│   ├── read: main manifest + linked specs/plans + token baselines
│   ├── read: skills/brainstorming/roadmap.md
│   ├── read: assets/roadmap.html + assets/roadmap.schema.json
│   └── write: refinement record + token-cost JSONL
│
└── ○ Return the ordered backlog

Degraded path:
no subagent capability → perform the same proposal inline → keep the same
human approval gate → update the same files.
```

## File Lifecycle Tree

```text
BACKLOG REFINEMENT FILES
│
├── Skill package [tracked]
│   ├── skills/backlog-refinement/SKILL.md
│   └── skills/backlog-refinement/README.md
│
├── Decision evidence [tracked, read-only]
│   └── main:docs/superpower/manifest.json
│
├── Product backlog [tracked, read and updated]
│   └── docs/superpowers/
│       ├── roadmap.json
│       └── ROADMAP.html
│
└── Dispatch evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        ├── backlog-refinement-token-cost.jsonl
        ├── 70-backlog-refinement/refinement-record.json
        └── 70-backlog-refinement/<task>/turns/<NNN>-<purpose>/
            ├── request.json
            └── response.json
```
