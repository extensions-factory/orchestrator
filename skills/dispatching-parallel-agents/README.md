# Dispatching Parallel Agents

## Legend

- `◆` — independent dispatch through `dispatch-agent`
- `○` — orchestrator analysis or integration
- `◇` — independence decision

## Lifecycle Tree

```text
PARALLEL AGENT DISPATCH
│
├── ○ Collect candidate problems or research domains
│
├── ◇ Are there at least two independent domains?
│   ├── no  → use one worker or a sequential workflow
│   └── yes → continue
│
├── ◇ Can workers operate without shared mutable state?
│   ├── no  → dispatch sequentially
│   └── yes → continue
│
├── ○ Build one focused request per domain
│   ├── exact scope
│   ├── domain-specific context and artifacts
│   ├── constraints
│   └── expected output
│
├── ◆ Dispatch every domain in the same orchestration message
│   ├── Domain 1 → dispatch-agent → its own request and ledger entry
│   ├── Domain 2 → dispatch-agent → its own request and ledger entry
│   └── Domain N → dispatch-agent → its own request and ledger entry
│
├── ○ Wait for all terminal results
│
├── ○ Review and integrate
│   ├── inspect each summary and artifact
│   ├── detect overlapping edits or contradictory findings
│   └── reconcile conflicts before accepting results
│
├── use-tool
│   ├── superpowers-orchestrator:dispatch-agent [one call per domain]
│   ├── concurrent subagent/worker dispatch
│   └── project-specific focused and full verification commands
│
├── use-file
│   ├── read: domain-specific failures, requirements, or research inputs
│   ├── create: one request.json and response.json per domain
│   ├── update: .superpowers/runs/<workflow-id>/ledger.jsonl
│   └── modify: only the non-overlapping files assigned to each worker
│
└── ○ Run combined verification
    ├── focused checks for each domain
    └── full relevant suite for the integrated state
```

## File Lifecycle Tree

```text
PARALLEL DISPATCH FILES
│
├── Skill package [tracked]
│   ├── skills/dispatching-parallel-agents/SKILL.md
│   └── skills/dispatching-parallel-agents/README.md
│
└── Runtime evidence [ignored, one branch per domain]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        └── <phase-directory>/
            ├── <domain-1>/turns/001-<purpose>/
            │   ├── request.json
            │   └── response.json
            ├── <domain-2>/turns/001-<purpose>/
            │   ├── request.json
            │   └── response.json
            └── <domain-N>/turns/001-<purpose>/
                ├── request.json
                └── response.json
```

Each domain uses the full [Dispatch-Agent Subtree](../../docs/orchestrator-workflow.md#dispatch-agent-subtree).
