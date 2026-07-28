# Backlog Refinement

## Legend

- `◆` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human approval gate
- `↻` — repeat the refinement cycle

## Lifecycle Tree

```text
BACKLOG REFINEMENT
│
├── ○ Read docs/superpowers/roadmap.json
│   ├── preserve existing product scope
│   └── accept new work only when supplied by the human
│
├── ◆ D23 propose ordering and grooming
│   ├── role: product_owner
│   ├── task_type: backlog_refinement_prioritization
│   └── input: current roadmap + human-supplied additions
│
├── ○ Validate the worker proposal
│
├── ◇ Human approves ordering and scope?
│   ├── no  → revise proposal ↻
│   └── yes → continue
│
├── ○ Apply only approved changes
│   ├── update roadmap.json
│   └── regenerate ROADMAP.html
│
├── use-tool
│   ├── superpowers-orchestrator:dispatch-agent
│   └── roadmap renderer defined by brainstorming/roadmap.md
│
├── use-file
│   ├── read/write: docs/superpowers/roadmap.json
│   ├── write: docs/superpowers/ROADMAP.html
│   ├── read: skills/brainstorming/roadmap.md
│   └── read: assets/roadmap.html + assets/roadmap.schema.json
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
├── Product backlog [tracked, read and updated]
│   └── docs/superpowers/
│       ├── roadmap.json
│       └── ROADMAP.html
│
└── Dispatch evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        └── <active-phase>/<task>/turns/<NNN>-<purpose>/
            ├── request.json
            └── response.json
```

See the repository-wide [Orchestrator Workflow](../../docs/orchestrator-workflow.md).
