# Brainstorming

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human approval gate
- `↻` — return to an earlier design step

## Lifecycle Tree

```text
BRAINSTORMING
│
├── ○ Inspect project context
│   ├── read files, docs, and recent commits
│   ├── check .ua/knowledge-graph.json freshness
│   └── fresh graph → collect matching nodes and edges
│       missing/stale/no matches → continue with normal exploration
│
├── ○ Understand the idea
│   ├── detect oversized scope and decompose when necessary
│   ├── ask one question at a time
│   └── optionally offer the visual companion just in time
│       ├── visual question → browser companion
│       └── textual question → normal conversation
│
├── ○ Present two or three approaches
│   └── lead with the recommended approach and trade-offs
│
├── ○ Present the design in reviewable sections
│
├── ◇ Human approves the design?
│   ├── no  → clarify or revise design sections ↻
│   └── yes → continue
│
├── ◆ D9 write design artifacts
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
│   ├── changes requested → update artifacts → self-review again ↻
│   └── approved          → continue
│
├── use-tool
│   ├── Git/file exploration for current project context
│   ├── graph keyword search [fresh graph only]
│   ├── visual-companion server [approved visual questions only]
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
├── Skill package [tracked]
│   └── skills/brainstorming/
│       ├── SKILL.md
│       ├── README.md
│       ├── roadmap.md
│       ├── visual-companion.md
│       ├── prompts/
│       │   └── spec-document-reviewer-prompt.md
│       ├── scripts/
│       │   ├── helper.js
│       │   ├── server.cjs
│       │   ├── start-server.sh
│       │   └── stop-server.sh
│       └── templates/
│           ├── spec-template.md
│           ├── document-companion-template.html
│           └── frame-template.html
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
        └── 20-design/
            ├── brainstorm/<session-id>/
            │   ├── content/
            │   └── state/
            └── <task>/turns/<NNN>-documentation/
                ├── request.json
                └── response.json
```

See the repository-wide [Orchestrator Workflow](../../docs/orchestrator-workflow.md).
