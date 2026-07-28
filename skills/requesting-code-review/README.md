# Requesting Code Review

## Legend

- `◆ Dn` — reviewer or fixer dispatch
- `○` — orchestrator preparation and adjudication
- `◇` — review verdict gate
- `↻` — fix and re-review loop

## Lifecycle Tree

```text
CODE REVIEW
│
├── Per-task review
│   ├── ○ Preserve the exact pre-D13 BASE_SHA
│   ├── ○ Commit validated worker changes
│   ├── ○ Generate BASE_SHA..HEAD_SHA review package
│   ├── ◆ D14 task review
│   │   ├── role: tech_lead
│   │   ├── task_type: code_review_quality
│   │   ├── enforce reviewer provider diversity
│   │   └── require spec-compliance + code-quality verdicts
│   ├── ◇ Security-sensitive diff?
│   │   ├── no  → continue
│   │   └── yes → ◆ D15 security review
│   │       ├── role: security_engineer
│   │       ├── task_type: security_review
│   │       └── require base_sha + complete security_focus
│   └── ◇ Critical or Important findings?
│       ├── yes → ◆ D16 fix wave
│       │   ├── commit validated fix
│       │   ├── regenerate review package
│       │   └── re-dispatch D14/D15 ↻
│       └── no  → task gate is clean
│
└── Whole-branch review
    ├── ○ Derive MERGE_BASE
    ├── ○ Generate MERGE_BASE..HEAD review package
    ├── ◆ D17 final review
    │   ├── role: tech_lead
    │   ├── task_type: code_review_quality
    │   └── include plan/spec and accumulated Minor findings
    └── ◇ Findings?
├── yes → ◆ D18 one complete fix wave
│   ├── commit validated fixes
│   ├── regenerate whole-branch package
│   └── re-dispatch D17 ↻
└── no  → hand off to finishing-a-development-branch
│
├── use-tool
│   ├── Git rev-parse, merge-base, and commit
│   ├── subagent-driven-development/scripts/review-package
│   ├── superpowers-orchestrator:dispatch-agent [D14–D18]
│   └── project-specific covering/full test commands [fix evidence]
│
└── use-file
    ├── read: prompts/code-reviewer.md
    ├── read: task brief, implementer report, design, and plan
    ├── create: review-<base7>..<head7>.diff
    └── create/update: review.md, response.json, report.md, ledger.jsonl
```

## File Lifecycle Tree

```text
CODE REVIEW FILES
│
├── Skill package [tracked]
│   └── skills/requesting-code-review/
│       ├── SKILL.md
│       ├── README.md
│       └── prompts/
│           └── code-reviewer.md
│
├── Review inputs [tracked or run-scoped, read]
│   ├── docs/superpowers/features/<feature-slug>/
│   │   ├── design.md
│   │   └── plan.md
│   └── .superpowers/runs/<workflow-id>/40-execution/tasks/<task>/
│       ├── brief.md
│       ├── report.md
│       └── reviews/review-<base7>..<head7>.diff
│
└── Review evidence [ignored, created]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        └── 40-execution/tasks/<task>/turns/
            ├── <NNN>-review/
            │   ├── request.json
            │   ├── review.md
            │   └── response.json
            └── <NNN>-fix/
                ├── request.json
                └── response.json
```

See [D. Execute Plan](../../docs/orchestrator-workflow.md#lifecycle-tree).
