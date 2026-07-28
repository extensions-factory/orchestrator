# Executing Plans

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
├── ○ Load the implementation plan
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
│   ├── mark task in progress
│   ├── execute every plan step
│   ├── run the specified verification
│   ├── perform orchestrator-owned Git bookkeeping
│   └── mark task complete
│
├── ◇ Blocker, unclear instruction, or repeated verification failure?
│   ├── yes → stop and ask; never guess
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
│   └── update: Git history after verified task units
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
├── Plan inputs [tracked, read]
│   └── docs/superpowers/features/<feature-slug>/
│       ├── design.md
│       └── plan.md
│
├── Implementation workspace [tracked, created or modified]
│   ├── source files named by each task
│   ├── test files named by each task
│   └── documentation/config files named by each task
│
└── Git history [updated after verified tasks]
    └── one orchestrator-owned commit per completed task or plan-defined unit
```

This skill is only the no-subagent alternative to the repository-wide execution lifecycle.
