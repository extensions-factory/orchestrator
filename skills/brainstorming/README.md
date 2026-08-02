# Brainstorming

## Description

Turns one scoped feature idea into an approved decision record, reviewed design artifacts, and a planning handoff.

## Inputs

- The current workspace and its selected entry in the single `main:docs/superpower/manifest.json`.
- Existing project files, documentation, recent commits, and optional fresh knowledge graph.
- The human partner's answers and approvals.
- Exact per-invocation or comparable cumulative token metadata exposed by the harness/provider.

## Durable Output

Brainstorming adds its decisions to only the selected workspace session:

```json
{
  "sessions": [
    {
      "workspace": {
        "type": "branch",
        "target": "feature/example-feature"
      },
      "brainstorming": {
        "workflow_id": "20260802T120000Z-example-feature",
        "problem": "The approved problem statement",
        "scope": ["Approved in-scope behavior"],
        "exclusions": ["Explicitly excluded behavior"],
        "approach": "The approved approach",
        "acceptance_criteria": ["A measurable success condition"]
      }
    }
  ]
}
```

It also creates `design.md`, `design.html`, and the feature's roadmap updates.

## Token-cost Monitoring

`.superpowers/runs/<workflow-id>/brainstorming-token-cost.jsonl` stores source-tagged records for every D9 worker attempt and every harness-reported main-orchestrator model invocation. Missing counts remain `null` with reasons. Handoff reports worker, orchestrator, and combined measured totals and coverage without treating partial values as complete.

## Human Decisions

Before detailed design, the human explicitly approves one bundle containing the problem, scope, exclusions, approach, and acceptance criteria. Permission to choose is not approval of the resulting values. Later changes return to this gate, update the selected manifest entry, and regenerate affected design artifacts.

The existing section-by-section design approval and written-spec review remain required after the decision gate.

## Handoff

Before `writing-plans`, brainstorming rereads the selected main-manifest session, verifies all five approved decisions and the workflow ID, checks that the written design matches, and includes the token-cost report plus the workspace-aware manifest instruction.

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human approval gate
- `↻` — return to an earlier design step

## Lifecycle Tree

```text
BRAINSTORMING
│
├── ○ Start token-cost boundary and select current manifest session
│   └── initialize/reuse brainstorming.workflow_id
│
├── ○ Inspect project context
│   ├── read files, docs, and recent commits
│   ├── check .ua/knowledge-graph.json freshness
│   └── fresh graph → collect matching nodes and edges
│       missing/stale/no matches → continue with normal exploration
│
├── ○ Create isolated workspace
│   ├── kebab-slugify the feature and use `feature/<slug>`
│   ├── invoke superpowers-orchestrator:using-git-worktrees
│   └── defer workspace creation until each decomposed sub-project begins
│
├── ○ Understand the idea
│   ├── detect oversized scope and decompose when necessary
│   └── ask one question at a time
│
├── ○ Present two or three approaches
│   └── lead with the recommended approach and trade-offs
│
├── ◇ Human approves problem + scope + exclusions + approach + criteria?
│   ├── no  → revise the decision bundle ↻
│   └── yes → record it in the selected session entry
│
├── ○ Present the design in reviewable sections
│
├── ◇ Human approves the design?
│   ├── no  → clarify or revise design sections ↻
│   └── yes → continue
│
├── ◆ D9 write design artifacts
│   ├── rename on material feature-name drift before writing: check collision,
│   │   rename the branch, and use the owning native tool or git fallback move
│   ├── discovery      → business_analyst / discovery_research
│   ├── requirements   → product_owner / requirements_user_stories
│   ├── architecture   → tech_lead / architecture_design
│   └── documentation  → technical_writer / documentation_knowledge_transfer
│
├── ○ Validate returned artifacts
│   ├── design.md follows spec-template.md
│   ├── design.html follows document-companion-template.html
│   ├── roadmap.json follows roadmap.schema.json
│   └── ROADMAP.html starts from the canonical template
│
├── ○ Self-review the written specification
│   ├── placeholders
│   ├── contradictions
│   ├── scope
│   ├── ambiguity
│   └── User Story acceptance criteria
│
├── ◇ Human reviews the written specification
│   ├── decision changed  → return to decision gate, update record, rerun D9 ↻
│   ├── artifact changed  → update artifacts → self-review again ↻
│   └── approved          → continue
│
├── ○ Report worker + orchestrator token usage and combined coverage
│
├── use-tool
│   ├── Git/file exploration for current project context
│   ├── graph keyword search [fresh graph only]
│   ├── superpowers-orchestrator:using-git-worktrees [create or resume workspace]
│   ├── superpowers-orchestrator:dispatch-agent [D9]
│   └── superpowers-orchestrator:writing-plans [terminal handoff]
│
├── use-file
│   ├── read: .ua/knowledge-graph.json [optional]
│   ├── read: templates/spec-template.md
│   ├── read: templates/document-companion-template.html
│   ├── read: roadmap.md + assets/roadmap.*
│   └── write: design.md, design.html, roadmap.json, ROADMAP.html
│
└── ○ Invoke superpowers-orchestrator:writing-plans

Hard gate:
no implementation, scaffolding, or implementation skill runs before design
approval. The only terminal handoff is writing-plans.
```

## File Lifecycle Tree

```text
BRAINSTORMING FILES
│
├── Decision record [tracked on main, read and updated]
│   └── docs/superpower/manifest.json
│       └── sessions[current workspace].brainstorming
│           ├── workflow_id
│           └── problem + scope + exclusions + approach + acceptance_criteria
│
├── Skill package [tracked]
│   └── skills/brainstorming/
│       ├── SKILL.md
│       ├── README.md
│       ├── roadmap.md
│       ├── prompts/
│       │   └── spec-document-reviewer-prompt.md
│       └── templates/
│           ├── spec-template.md
│           └── document-companion-template.html
│
├── Shared roadmap contracts [tracked, read]
│   └── assets/
│       ├── roadmap.schema.json
│       └── roadmap.html
│
├── Knowledge graph [read-only, optional]
│   ├── .ua/knowledge-graph.json
│   └── .understand-anything/knowledge-graph.json [legacy fallback]
│
├── Durable feature documents [tracked, created or updated]
│   └── docs/superpowers/
│       ├── features/<feature-slug>/
│       │   ├── design.md
│       │   └── design.html
│       ├── roadmap.json
│       └── ROADMAP.html
│
└── Runtime evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        ├── brainstorming-token-cost.jsonl
        └── 20-design/
            └── <task>/turns/<NNN>-documentation/
                ├── request.json
                └── response.json
```
