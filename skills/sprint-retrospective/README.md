# Sprint Retrospective

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human approval gate

## Lifecycle Tree

```text
SPRINT RETROSPECTIVE
│
├── ○ Read the completed run ledger
│   ├── count total dispatches
│   ├── count blocked results
│   ├── count needs_revision loops
│   ├── count provider degradation events
│   └── select concise supporting evidence
│
├── ◆ D21 process review
│   ├── role: agile_coach
│   ├── task_type: retrospective_process_improvement
│   └── input: metrics + supporting ledger excerpt
│
├── ○ Validate evidence and recommendations
│
├── ◇ Human approves process improvements?
│   ├── no  → record no approved change
│   └── yes → write retrospective.md
│
├── use-tool
│   ├── ledger metric calculation
│   ├── superpowers-orchestrator:dispatch-agent [D21]
│   └── superpowers-orchestrator:writing-skills [approved actions]
│
├── use-file
│   ├── read: .superpowers/runs/<workflow-id>/ledger.jsonl
│   ├── read: templates/retrospective-template.md
│   └── write: 60-retrospective/retrospective.md
│
└── ○ Route approved skill/workflow improvements
    └── invoke writing-skills
        └── D22 performs any approved skill edit

Boundary:
the retrospective produces recommendations and approved action items only;
it never edits code or skills directly.
```

## File Lifecycle Tree

```text
RETROSPECTIVE FILES
│
├── Skill package [tracked]
│   └── skills/sprint-retrospective/
│       ├── SKILL.md
│       ├── README.md
│       └── templates/
│           └── retrospective-template.md
│
└── Run evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl [read]
        └── 60-retrospective/
            ├── retrospective.md [created after approval]
            └── <task>/turns/<NNN>-<purpose>/
                ├── request.json
                └── response.json
```

See [F. Sprint Retrospective](../../docs/orchestrator-workflow.md#lifecycle-tree).
