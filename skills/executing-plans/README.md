# Executing Plans

## Description

Executes an approved implementation plan inline only when the harness has no subagent capability, while preserving human-owned decisions and verified task history.

## Inputs

- The current workspace and exactly matching session in the single `main:docs/superpower/manifest.json`.
- Approved Brainstorming scope/exclusions/acceptance criteria and the complete seven-field Writing Plans decision with workflow ID.
- Exact current plan/design paths and content hashes from the planning/refine handoff.
- Git history, prior task checkpoints, verification evidence, and exact orchestrator token metadata.

## Durable Output

Verified task commits are the implementation source of truth. Append-only `executing-plans-progress.jsonl` records task checkpoints, and `executing-plans-token-cost.jsonl` records exact-or-null main-orchestrator usage for this inline phase.

## Human Decisions

Inline execution may identify decision changes but cannot apply them. Product scope, exclusions, or acceptance-criteria proposals return to Brainstorming; build-order, file, interface, test, or verification proposals return to Writing Plans. Approval regenerates affected artifacts and invalidates completed-task evidence that no longer matches.

## Handoff

After every task has current-snapshot commit and verification evidence, Executing Plans rechecks the selected main-manifest session and plan/design hashes, then invokes Finishing a Development Branch once with decision, progress, verification, and token-cost context.

## Legend

- `○` — inline action in a harness without subagent capability
- `◇` — decision or blocker gate
- `↻` — return to plan review or retry after clarification

## Lifecycle Tree

```text
EXECUTING PLANS — DEGRADED INLINE MODE
│
├── ◇ Does the harness support subagents?
│   ├── yes → use subagent-driven-development instead
│   └── no  → continue inline
│
├── ○ Select current main-manifest session and approved plan
│   ├── bind decision snapshot + plan/design hashes
│   └── reconcile progress JSONL with Git history
│
├── ○ Review the plan critically
│   ├── verify scope, dependencies, and instructions
│   └── create one todo per task
│
├── ◇ Critical question or plan gap?
│   ├── yes → ask the human → update/re-read plan ↻
│   └── no  → continue
│
├── ○ For each task in order
│   ├── revalidate decision snapshot + plan hash
│   ├── mark task in progress
│   ├── execute every plan step
│   ├── revalidate before Git bookkeeping
│   ├── run the specified verification
│   ├── revalidate after verification
│   ├── perform orchestrator-owned Git bookkeeping
│   ├── append verified progress checkpoint
│   └── mark task complete
│
├── ◇ Blocker, decision change, unclear instruction, or repeated verification failure?
│   ├── decision change → owning human gate; regenerate/revalidate
│   ├── other blocker → stop and ask; never guess
│   └── no  → next task ↻
│
├── ○ Confirm every task and verification is complete
│
├── use-tool
│   ├── todo/task tracker
│   ├── project-specific test/build/lint commands
│   ├── Git for orchestrator-owned task commits
│   └── superpowers-orchestrator:finishing-a-development-branch
│
├── use-file
│   ├── read: design.md + plan.md
│   ├── modify: task-declared source/config/documentation files
│   ├── create/modify: task-declared test files
│   └── update: Git history, progress JSONL, and token-cost JSONL
│
└── ○ Invoke finishing-a-development-branch
```

## File Lifecycle Tree

```text
INLINE EXECUTION FILES
│
├── Skill package [tracked]
│   ├── skills/executing-plans/SKILL.md
│   └── skills/executing-plans/README.md
│
├── Approved inputs [tracked, read]
│   ├── main:docs/superpower/manifest.json [single decision record]
│   └── docs/superpowers/features/<feature-slug>/
│       ├── design.md
│       └── plan.md
│
├── Implementation workspace [tracked, created or modified]
│   ├── source files named by each task
│   ├── test files named by each task
│   └── documentation/config files named by each task
│
├── Git history [updated after verified tasks]
│   └── one orchestrator-owned commit per completed task or plan-defined unit
│
└── Runtime evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── executing-plans-progress.jsonl
        └── executing-plans-token-cost.jsonl
```

This skill is only the no-subagent alternative to the repository-wide execution lifecycle.
