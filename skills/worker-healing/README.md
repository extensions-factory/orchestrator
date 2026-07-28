# Worker Healing

## Legend

- `◆` — repair dispatch through a healthy provider path
- `○` — orchestrator diagnosis or validation
- `◇` — failure classification gate

## Lifecycle Tree

```text
WORKER HEALING
│
├── ○ Collect failed-dispatch evidence
│
├── ◇ Failure class
│   ├── task-logic failure
│   │   └── stop worker-healing; re-scope or re-dispatch the task
│   └── bridge/plugin failure
│       ├── invalid forwarded CLI flag
│       ├── print/response timeout
│       └── spawn/forward failure
│
├── ○ Identify broken bridge in external codex-plugin-cc repository
│   ├── codex
│   │   ├── plugins/codex/scripts/lib/codex.mjs
│   │   └── tests/fake-codex-fixture.mjs
│   └── antigravity
│       ├── plugins/antigravity/scripts/lib/antigravity.mjs
│       └── tests/fake-antigravity-fixture.mjs
│
├── ◆ Dispatch repair through a provider other than the broken bridge
│   ├── role: software_engineer
│   ├── task_type: debugging_root_cause
│   ├── reproduce failure
│   ├── add failing regression test
│   ├── apply smallest root-cause fix
│   └── run focused bridge suite
│
├── ○ Validate returned repair
│   ├── regression test passes
│   ├── relevant suite passes
│   └── forwarded invocation is no longer mangled
│
├── ○ Validate response envelope and append ledger entry
│
├── use-tool
│   ├── superpowers-orchestrator:dispatch-agent
│   ├── healthy Claude worker path
│   ├── external bridge's focused test runner
│   └── scripts/validate-message.mjs + normal ledger flow
│
├── use-file
│   ├── read: failed dispatch evidence
│   ├── modify: external plugins/<bridge>/scripts/lib/<bridge>.mjs
│   ├── read/use: matching fake bridge fixture
│   ├── create/update: external regression test
│   └── read/write: request.json, response.json, ledger.jsonl
│
└── ○ Remind human to release codex-plugin-cc
    ├── bump version
    ├── update affected CHANGELOG.md
    └── push release

Boundary:
the orchestrator neither edits the external bridge inline nor performs the release.
```

## File Lifecycle Tree

```text
WORKER-HEALING FILES
│
├── Orchestrator skill [tracked, read]
│   ├── skills/worker-healing/SKILL.md
│   └── skills/worker-healing/README.md
│
├── External codex-plugin-cc checkout [modified by repair worker]
│   ├── plugins/codex/scripts/lib/codex.mjs
│   ├── plugins/antigravity/scripts/lib/antigravity.mjs
│   ├── tests/fake-codex-fixture.mjs
│   ├── tests/fake-antigravity-fixture.mjs
│   ├── tests/<affected-runtime-suite>
│   └── plugins/<affected-plugin>/CHANGELOG.md [release step]
│
└── Orchestrator run evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        └── <phase>/<repair-task>/turns/<NNN>-fix/
            ├── request.json
            └── response.json
```

The external bridge repository remains the authority for its own source and tests.
