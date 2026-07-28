# Project Kickoff

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human approval or selection gate
- `↻` — return to clarify or correct an earlier phase

## Lifecycle Tree

```text
PROJECT KICKOFF
│
├── ○ Verify greenfield trigger
│   ├── empty/no meaningful repository → continue
│   ├── explicit "new/from scratch" request → continue
│   └── existing project → stop and use brainstorming
│
├── Phase 1 — Discovery
│   ├── ◇ Capture the idea in one sentence
│   ├── ○ Select research track
│   │   ├── market-facing product
│   │   └── technical/internal build
│   ├── ◆ D1–D4 research four independent domains in parallel
│   │   ├── role: business_analyst
│   │   ├── task_type: discovery_research
│   │   └── one isolated request per domain
│   ├── ◆ D5 synthesize discovery.md
│   │   ├── validate all four research areas
│   │   └── produce proposed Epic → Feature → User Story backlog
│   └── ◇ Human confirms the backlog
│       ├── revise candidates inline ↻
│       └── approve exact seed scope
│
├── Phase 2 — Setup decisions
│   ├── ◇ Choose stack
│   ├── ◇ Choose standards
│   ├── ◇ Choose AI tools
│   ├── ◆ D6 initialize Git repository [when absent]
│   │   └── devops_engineer / workspace_setup
│   └── ◆ D7 create two isolated bootstrap commits
│       ├── generated stack-specific .gitignore
│       └── discovery.md
│
├── Phase 3 — Scaffold specification
│   └── ◆ D8 write and validate scaffold artifacts
│       ├── tech_lead / architecture_design
│       ├── scaffold-design.md
│       ├── roadmap.json from human-confirmed backlog
│       └── ROADMAP.html from canonical template
│
├── ◇ Human approves scaffold specification?
│   ├── no  → revise D8 artifacts ↻
│   └── yes → continue
│
├── use-tool
│   ├── superpowers-orchestrator:dispatching-parallel-agents [D1–D4]
│   ├── superpowers-orchestrator:dispatch-agent [D1–D8]
│   ├── Git init/add/commit [D6/D7]
│   └── superpowers-orchestrator:writing-plans [handoff]
│
├── use-file
│   ├── read: references/stack-init-commands.md
│   ├── read: templates/discovery-template.md
│   ├── read: templates/constitution/tool-instruction/ci-stub templates
│   ├── create: .gitignore, discovery.md, scaffold-design.md
│   └── create: roadmap.json + ROADMAP.html
│
└── Phase 4 — Handoff
    └── ○ Invoke writing-plans for scaffold-design.md

Downstream plan tasks, not kickoff itself, create:
official stack scaffold, CONSTITUTION.md, per-tool instruction files,
enforceable config, CI stub, and the verified walking skeleton.
```

## File Lifecycle Tree

```text
PROJECT KICKOFF FILES
│
├── Skill package [tracked, read]
│   └── skills/project-kickoff/
│       ├── SKILL.md
│       ├── README.md
│       ├── references/
│       │   └── stack-init-commands.md
│       └── templates/
│           ├── discovery-template.md
│           ├── constitution-template.md
│           ├── tool-instruction-template.md
│           └── ci-stub-templates.md
│
├── Bootstrap files [tracked, created and committed]
│   ├── .gitignore
│   └── docs/superpowers/project/
│       └── discovery.md
│
├── Scaffold design and roadmap [tracked, created]
│   └── docs/superpowers/
│       ├── project/
│       │   └── scaffold-design.md
│       ├── roadmap.json
│       └── ROADMAP.html
│
├── Planned scaffold outputs [tracked, created during execution]
│   ├── CONSTITUTION.md
│   ├── CLAUDE.md / AGENTS.md / GEMINI.md [selected tools only]
│   ├── stack and lint/format/test configuration
│   ├── minimal CI workflow
│   └── official stack-generated source/test skeleton
│
└── Runtime evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        └── 10-discovery/
            ├── <research-domain>/turns/<NNN>-research/
            │   ├── request.json
            │   └── response.json
            └── synthesis/turns/<NNN>-research/
                ├── request.json
                └── response.json
```

See [A. Greenfield Project](../../docs/orchestrator-workflow.md#lifecycle-tree).
