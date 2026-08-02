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

## Pattern Omissions

- `anti-pattern` — baseline testing (4/4 PASS) surfaced four rationalizations, all already countered by existing `## Red Flags` rows (stray-file greenfield, unconfirmed seeding, authority-as-gate-substitute, retroactive approval). No single dominant rationalization emerged that warrants a named anti-pattern separate from that table.
- `process-flow` — the workflow has a Create/Resume branch and two research tracks, but the Lifecycle Tree in this README already captures that structure in full. A duplicate `dot` fence would add no information beyond what is already present.
- `after-artifact` — the skill's durable output and handoff steps are already defined in Phase 4 — Handoff inside `## The Process` and in the `## Handoff` section of this README. A separate `## After Project Kickoff` block would duplicate that material without adding substance.

## Pattern Migration Notes

- `hard-gate` — DERIVED from `## Trigger` ("Redirect guard: If the directory holds a real existing project, STOP") and `### Human Gate 1` ("Do not dispatch D1–D4 until this approval is recorded") and `### Human Gate 2` ("Do not dispatch D6–D8 until this approval is recorded"), no new requirements.
- `checklist` — DERIVED from `## Trigger` (step 1), `## Flow` (steps 2–4), `## Phase 1` (steps 5–8), `## Phase 2` (steps 9–12), `## Phase 3` (steps 13–14), `## Token-cost monitoring` (step 15), and `## Phase 4` (step 16), no new requirements.
- `the-process` — DERIVED from `## Trigger`, `## Flow`, and the four Phase sections in their entirety; every subsection carries real body text moved verbatim from the source sections, no new requirements.
- `key-principles` — DERIVED compression (not verbatim) from: `## Trigger` redirect guard (Greenfield only bullet), Phase 1 "This phase gates the rest" (Discovery gates everything bullet), `### Human Gate 1` ("Do not dispatch D1–D4 until this approval is recorded") and `### Human Gate 2` ("Do not dispatch D6–D8 until this approval is recorded") combined with the Red Flags "Human says 'choose for me'" row ("Delegation does not replace approval or durable recording") for the Human gates bullet, `## Flow` manifest-record paragraph (Manifest is durable record bullet), Red Flags rows for skip-research (Research grounds decisions bullet), scaffold-as-plan-tasks (Plan tasks bullet), and exact-token-counts (Telemetry bullet). Each bullet is a compression of source text; no bullet adds scope the source does not cover. Fix applied in turn 4: the original human-gates bullet appended "authority, deadlines, and exhaustion do not substitute for explicit approval" — wording absent from the source — which was replaced with "delegation does not replace approval or durable recording", tracing to the Red Flags delegation row verbatim.
- `token-cost-monitoring` — RETAINED, heading normalized from `## Token-cost monitoring` to Title Case (`## Token-cost Monitoring`); body unchanged.

### Migration evidence

- Scenario: `kickoff-gates-under-deadline-pressure` (authored from scratch; no eval prose existed)
- Baseline (pre-migration): 4/4 PASS
- After (post-migration): 4/4 PASS — no regression (gate: after >= baseline)
- Gate: no-regression A/B; DERIVED blocks only, no gap-fill content
- Caveat: baselines in this campaign are contaminated — the measuring subagent
  carries prior knowledge of this repository, so a pre-migration baseline is
  not a clean no-skill control. Contamination is symmetric across the A/B, so
  regression detection remains valid; necessity claims for new content do not.
