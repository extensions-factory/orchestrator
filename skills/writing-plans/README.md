# Writing Plans

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator validation or routing
- `◇` — human choice or scope gate
- `↻` — revise and validate again

## Lifecycle Tree

```text
WRITING PLANS
│
├── ○ Read approved specification and project context
│
├── ◇ Spec contains multiple independent subsystems?
│   ├── yes → recommend separate plans/specs
│   └── no  → continue
│
├── ◆ D10 author implementation plan
│   ├── role: tech_lead
│   ├── task_type: sprint_planning
│   ├── use templates/plan-template.md
│   └── generate plan.md + plan.html
│
├── Plan structure
│   ├── header with spec, goal, architecture, stack
│   ├── Expected Outcome
│   ├── Global Constraints copied exactly from spec
│   ├── optional Foundation for work shared by multiple stories
│   ├── one vertical-slice section per spec User Story
│   │   ├── preserve US IDs
│   │   ├── one or more independently reviewable tasks
│   │   └── end-to-end US checkpoint
│   └── every task contains
│       ├── dependencies
│       ├── exact files
│       ├── consumed and produced interfaces
│       ├── valid task_type
│       ├── failing test step
│       ├── observed failure
│       ├── minimal implementation
│       ├── passing verification
│       └── orchestrator-only Git bookkeeping block
│
├── ○ Self-review returned artifacts
│   ├── complete spec coverage
│   ├── no placeholders or vague steps
│   ├── type/interface consistency
│   ├── template conformance
│   ├── valid task_type on every task
│   └── spec US ↔ plan US ↔ checkpoint traceability
│
├── ◇ Self-review finds gaps?
│   ├── yes → fix plan + regenerate plan.html ↻
│   └── no  → continue
│
├── use-tool
│   ├── superpowers-orchestrator:dispatch-agent [D10]
│   ├── plan self-review and traceability checks
│   ├── superpowers-orchestrator:requesting-plan-refine [optional]
│   └── selected execution skill [terminal handoff]
│
├── use-file
│   ├── read: approved design.md
│   ├── read: templates/plan-template.md
│   ├── read: templates/plan-companion-template.html
│   └── create/update: plan.md + plan.html
│
└── ◇ Human chooses next action
    ├── Refine
    │   └── requesting-plan-refine
    └── Execute
        ├── subagent-capable harness → subagent-driven-development
        └── no subagent capability  → executing-plans
```

## File Lifecycle Tree

```text
PLAN FILES
│
├── Skill package [tracked, read]
│   └── skills/writing-plans/
│       ├── SKILL.md
│       ├── README.md
│       ├── prompts/
│       │   └── plan-document-reviewer-prompt.md
│       └── templates/
│           ├── plan-template.md
│           └── plan-companion-template.html
│
├── Specification [tracked, read]
│   └── docs/superpowers/features/<feature-slug>/
│       └── design.md
│
├── Plan artifacts [tracked, created and kept synchronized]
│   └── docs/superpowers/features/<feature-slug>/
│       ├── plan.md
│       └── plan.html
│
└── Runtime planning evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        └── 30-plan/<task>/turns/<NNN>-planning/
            ├── request.json
            └── response.json
```

See [C. Writing Plan](../../docs/orchestrator-workflow.md#lifecycle-tree).
