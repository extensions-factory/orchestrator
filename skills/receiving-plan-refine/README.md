# Receiving Plan Refine

## Legend

- `○` — orchestrator validation performed inline
- `◇` — human workflow choice
- `↻` — request another independent refine pass

## Lifecycle Tree

```text
RECEIVE PLAN-REFINE FINDINGS
│
├── ○ Read findings.md from requesting-plan-refine
│
├── ○ Evaluate every finding independently
│   ├── restate the claim
│   ├── verify against plan
│   ├── verify against specification when present
│   ├── verify against codebase evidence
│   ├── valid finding   → edit plan
│   └── invalid finding → decline with technical reason
│
├── ○ Regenerate the plan HTML companion
│
├── ○ Report fixed and declined counts with reasons
│
├── use-tool
│   ├── plan/spec/codebase file inspection
│   ├── plan HTML regeneration from writing-plans conventions
│   ├── superpowers-orchestrator:requesting-plan-refine [loop]
│   └── selected execution skill [terminal handoff]
│
├── use-file
│   ├── read: 30-plan/plan-refine/findings.md
│   ├── read: design.md and relevant codebase evidence
│   └── update: plan.md + plan.html
│
└── ◇ Human chooses next action
    ├── Refine
    │   └── invoke requesting-plan-refine ↻
    └── Execute
        ├── subagent-capable harness → subagent-driven-development
        └── no subagent capability  → executing-plans
```

## File Lifecycle Tree

```text
PLAN-REFINE RECEIVER FILES
│
├── Skill package [tracked]
│   ├── skills/receiving-plan-refine/SKILL.md
│   └── skills/receiving-plan-refine/README.md
│
├── Review evidence [ignored, read]
│   └── .superpowers/runs/<workflow-id>/
│       └── 30-plan/plan-refine/
│           └── findings.md
│
└── Plan artifacts [tracked, updated]
    └── docs/superpowers/features/<feature-slug>/
        ├── plan.md
        └── plan.html
```

The findings evaluation is never dispatched; it is the orchestrator's validation gate.
