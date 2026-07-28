# Dispatch Agent

## Legend

- `◆` — worker or reviewer dispatch
- `○` — deterministic orchestration step
- `↻` — retry, revision, or provider fallback

## Lifecycle Tree

```text
DISPATCH AGENT
│
├── 1. ○ Resolve task_type
│   ├── planned work → read the task annotation
│   └── unplanned work → derive from the requested role
│
├── 2. ○ Resolve ranked candidates
│   └── scripts/model-lookup.sh <task_type>
│       └── assets/sdlc-model-routing.json
│
├── 3. ○ Select provider and model
│   ├── normal work → first ready ranked candidate
│   ├── review → prefer a provider different from author_agent
│   └── failed/unready provider → walk the ranking ↻
│       └── Claude subagent is the final degradation rung
│
├── 4. ○ Initialize or reuse workflow run
│   ├── scripts/run-paths.mjs init
│   ├── set phase, purpose, stable task slug, and next turn
│   └── write <turn-dir>/request.json
│       └── validate shape against message-envelope.schema.json
│
├── 5. ○ Provider readiness preflight
│   ├── claude      → Agent tool
│   ├── codex       → setup + allowed command family
│   └── antigravity → setup + rescue command
│
├── 6. ◆ Dispatch
│   ├── claude worker
│   │   └── Agent prompt = ROLE header + request envelope
│   ├── codex review
│   │   ├── code_review_quality → /codex:review
│   │   └── security_review     → /codex:adversarial-review
│   └── codex/antigravity rescue
│       ├── write prompt.txt
│       ├── scripts/dispatch-worker.mjs
│       └── haiku forwarder waits for TERMINAL status
│
├── 7. ○ Receive result
│   ├── TERMINAL <status> <path>
│   ├── malformed → remind once → second failure becomes blocked
│   └── provider failure → next ranked provider ↻
│
├── 8. ○ Validate response
│   └── scripts/validate-message.mjs response.json
│
├── 9. ○ Append request/response pair to ledger.jsonl
│   └── entry conforms to ledger-entry.schema.json
│
├── use-tool
│   ├── scripts/model-lookup.sh
│   ├── scripts/run-paths.mjs
│   ├── Agent tool [Claude workers and haiku forwarder]
│   ├── /codex:review or /codex:adversarial-review [Codex reviews]
│   ├── scripts/dispatch-worker.mjs [Codex/Antigravity rescue]
│   └── scripts/validate-message.mjs
│
├── use-file
│   ├── read: assets/sdlc-model-routing.json
│   ├── read: assets/message-envelope.schema.json
│   ├── read: references/*-workers.md and codex-worker-protocol.md
│   └── create/update: manifest.json, request.json, response.json,
│       prompt.txt, job.txt, review.md, ledger.jsonl
│
└── 10. ○ Route status
    ├── done           → next workflow step
    ├── needs_revision → same task, next turn ↻
    ├── blocked        → resolve context/escalate, next turn ↻
    └── blocked_ops
        ├── Git bookkeeping → orchestrator performs inline
        └── other operation → dispatch exact residual operation
```

## File Lifecycle Tree

```text
DISPATCH FILES
│
├── Skill package [tracked, read]
│   └── skills/dispatch-agent/
│       ├── SKILL.md
│       ├── README.md
│       └── references/
│           ├── codex-worker-protocol.md
│           ├── codex-workers.md
│           └── antigravity-workers.md
│
├── Shared contracts and routing [tracked, read]
│   ├── assets/message-envelope.schema.json
│   ├── assets/ledger-entry.schema.json
│   ├── assets/run-manifest.schema.json
│   ├── assets/run-index-template.md
│   └── assets/sdlc-model-routing.json
│
├── Runtime helpers [tracked, executed]
│   ├── scripts/model-lookup.sh
│   ├── scripts/run-paths.mjs
│   ├── scripts/dispatch-worker.mjs
│   └── scripts/validate-message.mjs
│
└── Per-run evidence [ignored, created or updated]
    └── .superpowers/runs/<workflow-id>/
        ├── manifest.json
        ├── README.md
        ├── ledger.jsonl
        └── <phase-directory>/<task>/turns/<NNN>-<purpose>/
            ├── request.json
            ├── prompt.txt [rescue only]
            ├── job.txt [asynchronous rescue only]
            ├── result-raw.txt [malformed result only]
            ├── review.md [review commands only]
            └── response.json
```

See the repository-wide [Dispatch-Agent Subtree](../../docs/orchestrator-workflow.md#dispatch-agent-subtree).
