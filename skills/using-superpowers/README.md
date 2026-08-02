# Using Superpowers

## Description

Session bootstrap selects one of the concurrent workspace-scoped workflows recorded in a single manifest on `main`.

## Inputs

- The human partner's current request and project instructions.
- The single `main:docs/superpower/manifest.json`.
- Current Git branches and worktrees, which determine which sessions are resumable.
- The human partner's Create/Resume choice and exact workspace selection.

## Durable Output

`docs/superpower/manifest.json` exists only on `main` and records every in-process session:

```json
{
  "sessions": [
    {
      "workspace": {
        "type": "branch",
        "target": "feature/feature-a"
      }
    },
    {
      "workspace": {
        "type": "worktree",
        "target": ".worktrees/feature-b"
      }
    }
  ]
}
```

Create/Resume is not stored. Each `sessions` entry is identified by its workspace tuple and accumulates that workflow's later durable decisions. Creating Feature B appends an entry without changing Feature A. Actual Git branch/worktree state is authoritative when resuming.

## Human Decisions

The human partner chooses **Create Session** or **Resume Session**. Create requires a new workspace type and exact target. Resume requires selecting an existing Git branch or worktree with a matching manifest entry. Later lifecycle phases keep using that entry without repeating the choice.

## Handoff

Create appends the new workspace entry to the manifest on `main`; Resume selects an existing entry by its Git workspace. Every lifecycle phase and worker handoff reads the one main manifest and selects the entry matching its current branch or worktree.

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
├── ○ read main:docs/superpower/manifest.json
│
├── ○ inspect Git branches/worktrees and reconcile session entries
│
├── ◇ Create Session or Resume Session?
│   ├── Create
│   │   ├── ◇ human confirms new workspace.type and workspace.target
│   │   ├── ○ create the workspace
│   │   └── ○ append its entry to sessions[] on main
│   └── Resume
│       ├── ◇ human selects an existing branch or worktree
│       └── ○ match its existing sessions[] entry
│
├── ○ enter the selected workspace
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
│   ├── read/write: main:docs/superpower/manifest.json
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
├── Single session manifest [tracked on main]
│   └── docs/superpower/manifest.json
│       └── sessions[]
│           ├── Feature A → workspace + durable decisions
│           └── Feature B → workspace + durable decisions
│
├── Instruction sources [read-only]
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   ├── GEMINI.md
│   └── equivalent harness/project instructions
│
└── Downstream files
    └── determined by the selected lifecycle skill after it selects its entry
        from the main manifest.
```
