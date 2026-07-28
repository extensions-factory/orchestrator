# Using Superpowers

## Legend

- `○` — orchestrator classification or routing decision
- `◇` — applicability or harness-capability gate
- `◆` — downstream dispatch through `dispatch-agent`

## Lifecycle Tree

```text
SESSION BOOTSTRAP
│
├── ○ Session-start loads using-superpowers
│
├── ◇ Is this agent a dispatched worker?
│   ├── yes → stop; worker follows its request envelope and worker skills
│   └── no  → continue as Scrum Master orchestrator
│
├── ○ Read user and project instructions
│   └── direct user instructions override skill defaults
│
├── ○ Inspect available skill descriptions
│
├── ◇ Is there at least a 1% chance a skill applies?
│   ├── no  → respond normally
│   └── yes → invoke skill before any response, question, or file action
│
├── ○ Order applicable skills
│   ├── process skill first
│   └── implementation/domain skill second
│
├── ○ Announce selected skill and follow its checklist
│
├── ◇ Does work need a worker or reviewer?
│   ├── no  → perform allowed orchestrator validation/routing action
│   └── yes → ◆ dispatch-agent
│
├── use-tool
│   ├── harness skill discovery/invocation
│   ├── superpowers-orchestrator:dispatch-agent
│   └── platform-specific tools from references/<harness>-tools.md
│
├── use-file
│   ├── read: AGENTS.md/CLAUDE.md/GEMINI.md or equivalent instructions
│   ├── read: selected SKILL.md files
│   └── read: references/codex-tools.md, pi-tools.md, or antigravity-tools.md
│
└── ○ RECEIVE → VALIDATE → ROUTE
    ├── never absorb implementation after worker failure
    └── use dispatch-agent degradation ladder until terminal result

Common entry routing:
"build/change" → brainstorming → writing-plans → execution → finish
"bug"          → systematic-debugging → implementation workflow
"greenfield"   → project-kickoff → writing-plans
```

## File Lifecycle Tree

```text
BOOTSTRAP FILES
│
├── Skill package [tracked, read]
│   └── skills/using-superpowers/
│       ├── SKILL.md
│       ├── README.md
│       └── references/
│           ├── codex-tools.md
│           ├── pi-tools.md
│           └── antigravity-tools.md
│
├── Instruction sources [read-only]
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   ├── GEMINI.md
│   └── equivalent harness/project instructions
│
└── Downstream files
    └── determined by the selected skill; using-superpowers itself creates
        no project artifact and only routes into the appropriate lifecycle.
```

See [Session Bootstrap](../../docs/orchestrator-workflow.md#lifecycle-tree).
