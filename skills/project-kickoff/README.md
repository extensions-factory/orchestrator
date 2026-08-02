# Project Kickoff

## Description

Turns one approved greenfield idea into researched discovery, approved setup decisions, scaffold artifacts, and a complete handoff to `writing-plans`.

## Inputs

- The current workspace and its matching session entry in the single `main:docs/superpower/manifest.json`.
- The human partner's idea and approval of the research direction.
- Research findings and the human-confirmed Epic → Feature → User Story backlog.
- The human partner's approved stack, standards, and AI-tool choices.
- Exact per-turn or comparable cumulative token metadata exposed by the harness/provider.

## Durable Output

Kickoff adds only `project_kickoff` to the current workspace's entry in the main manifest; other session entries are preserved:

```json
{
  "sessions": [
    {
      "workspace": {
        "type": "worktree",
        "target": ".worktrees/example-project"
      },
      "project_kickoff": {
        "workflow_id": "20260802T120000Z-example-project",
        "idea": "A one-sentence project idea",
        "research_direction": "market-facing",
        "stack": {
          "language": "TypeScript",
          "framework": "React",
          "package_manager": "npm",
          "test_runner": "Vitest"
        },
        "standards": {
          "formatter_linter": "Prettier and ESLint",
          "naming": "project convention",
          "commits": "Conventional Commits",
          "tests": "*.test.ts"
        },
        "ai_tools": ["Codex"]
      }
    }
  ]
}
```

Kickoff also creates `docs/superpowers/project/discovery.md`, `docs/superpowers/project/scaffold-design.md`, `docs/superpowers/roadmap.json`, and `docs/superpowers/ROADMAP.html`.

## Token-cost Monitoring

Appends one validated record at a time to `.superpowers/runs/<workflow-id>/project-kickoff-token-cost.jsonl`, with `source` set to `worker` or `orchestrator`. Worker records cover D1–D8 attempts, including fallbacks and reroutes. Orchestrator records cover every harness-reported main-orchestrator model invocation (orchestrator model turns) from project-kickoff activation through handoff; resumed sessions continue after the highest recorded orchestrator turn. Both preserve exact provider/model, turn, available input/output counts, and reasons for unavailable counts.

Before handoff, kickoff reports worker subtotals, orchestrator subtotals, combined project-kickoff totals, partial columns, unavailable records, and coverage for each source and combined. It never estimates missing counts or presents a partial subtotal as complete. Ordinary tool calls are not counted separately because their results are part of orchestrator model input. The handoff turn remains explicitly unmeasured because its usage becomes visible only after completion.

## Human Decisions

The human approves two decision bundles before dependent work begins:

1. The normalized idea and research direction, before research dispatch.
2. The stack, standards, and AI tools, before repository setup or scaffold dispatch.

The human also confirms the proposed backlog and approves the scaffold artifacts. A resumed kickoff reuses complete approved bundles. Later changes return to the owning human gate, update the same session entry, and rerun affected downstream work.

## Handoff

Before invoking `writing-plans`, kickoff rereads the current workspace's main-manifest entry and verifies its workflow ID and all five approved fields are present. The handoff includes the project-kickoff token-cost report, names the workspace, passes `scaffold-design.md` plus any UI-shell spec, and tells the next session to read the main manifest and select the matching workspace entry.

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
├── ○ Start token-cost boundary and capture usage baseline
│
├── ○ Select current workspace entry from the manifest on main
│
├── ○ Initialize/reuse workflow_id for project-kickoff telemetry
│
├── Phase 1 — Discovery
│   ├── ○ Capture and normalize the idea
│   ├── ○ Recommend research direction
│   │   ├── market-facing product
│   │   └── technical/internal build
│   ├── ◇ Approve idea + research direction
│   │   └── ○ record both in the selected session entry
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
│   ├── ○ Gather stack, standards, and AI-tool choices
│   ├── ◇ Approve the complete setup decision bundle
│   │   └── ○ record all three in the selected session entry
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
├── ○ Report worker + orchestrator token usage and combined coverage
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
    ├── ○ reread the selected session entry and check five fields
    └── ○ invoke writing-plans with workspace-aware manifest instruction

Downstream plan tasks, not kickoff itself, create:
official stack scaffold, CONSTITUTION.md, per-tool instruction files,
enforceable config, CI stub, and the verified walking skeleton.
```

## File Lifecycle Tree

```text
PROJECT KICKOFF FILES
│
├── Decision record [tracked on main, read and updated]
│   └── docs/superpower/manifest.json
│       └── sessions[current workspace].project_kickoff
│           ├── workflow_id
│           ├── idea + research_direction
│           └── stack + standards + ai_tools
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
        ├── project-kickoff-token-cost.jsonl
        └── 10-discovery/
            ├── <research-domain>/turns/<NNN>-research/
            │   ├── request.json
            │   └── response.json
            └── synthesis/turns/<NNN>-research/
                ├── request.json
                └── response.json
```
