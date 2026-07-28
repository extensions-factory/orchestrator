# Requesting Plan Refine

## Legend

- `◆ D11` — independent plan-review dispatch
- `○` — orchestrator preparation or result routing
- `◇` — human execution/refinement choice
- `↻` — another independent review pass

## Lifecycle Tree

```text
REQUEST PLAN REFINE
│
├── ○ Locate plan and optional specification
│
├── ○ Resolve active run plan-refine directory
│   └── scripts/run-paths.mjs task --phase plan --task plan-refine
│
├── ○ Fill prompts/plan-reviewer.md
│   ├── PLAN_FILE
│   ├── SPEC_FILE or explicit absence
│   └── FINDINGS_FILE
│
├── ◆ D11 independent review
│   ├── role: tech_lead
│   ├── task_type: code_review_quality
│   ├── use author_agent from ledger.jsonl
│   ├── enforce reviewer provider diversity
│   └── write findings.md
│
├── ○ Receive only findings path and one-line summary
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
│   └── create: 30-plan/plan-refine/findings.md
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
│   └── docs/superpowers/features/<feature-slug>/
│       ├── design.md [when present]
│       └── plan.md
│
└── Review evidence [ignored, created]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        └── 30-plan/
            ├── plan-refine/
            │   └── findings.md
            └── <task>/turns/<NNN>-review/
                ├── request.json
                ├── review.md
                └── response.json
```

See [C. Writing Plan](../../docs/orchestrator-workflow.md#lifecycle-tree).
