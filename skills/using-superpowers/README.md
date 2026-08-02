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

## Pattern Omissions

- `anti-pattern` — baseline testing surfaced five rationalizations, all already countered by the existing `## Red Flags` table. No single dominant rationalization emerged that warrants a named anti-pattern separate from that table.
- `process-flow` — the workflow has a Create/Resume branch, but the Lifecycle Tree in this README already captures that structure. A duplicate `dot` fence would add no information beyond what is already present.
- `after-artifact` — the skill's durable output (appending to `docs/superpower/manifest.json`) and its handoff to downstream lifecycle skills are already described in the `## Durable Output` and `## Handoff` sections of this README. A separate `## After Using Superpowers` block would duplicate that material without adding substance.
- `token-cost-monitoring` — this skill never invokes a model nor dispatches a worker; it reads files and manifests and routes to the next skill.

## Pattern Migration Notes

- `hard-gate` — DERIVED from `## Session Gate` ("A Create MUST NOT overwrite other in-process session entries"; "Ask the human partner to choose Create Session or Resume Session unless their request already makes that choice explicit"), no new requirements.
- `checklist` — DERIVED from `## Session Gate` (steps 1–4 of the session reconcile/create/resume sequence), `## The Rule` (invoke skills before any response or action), and `## Skill Priority` (process skills first, then implementation skills), no new requirements.
- `the-process` — DERIVED from `## Session Gate` (full prose elaboration of manifest read, reconcile, create, resume steps), `## The Rule` (skill invocation timing), and `## Skill Priority` (ordering when multiple skills apply), no new requirements.
- `key-principles` — DERIVED from `<EXTREMELY-IMPORTANT>` (skills mandatory, 1% rule), `## The Rule` (check before acting, announce skill), `## Skill Priority` (process skills first), `## User Instructions` (user instructions override skills), and the orchestrator-split paragraph (never absorb work inline), no new requirements.

### Migration evidence

- Scenario: `bootstrap-before-action-under-launch-pressure` (adapted from `evals/scenarios/superpowers-bootstrap/story.md`)
- Baseline (pre-migration): 4/4 PASS
- After (post-migration): 4/4 PASS — no regression (gate: after >= baseline)
- Gate: no-regression A/B; DERIVED blocks only, no gap-fill content
- Caveat: baselines in this campaign are contaminated — the measuring subagent carries prior knowledge of this repository, so a pre-migration baseline is not a clean no-skill control. Contamination is symmetric across the A/B, so regression detection remains valid; necessity claims for new content do not.
