# Finishing a Development Branch

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human decision or destructive-action gate
- `↻` — return to verification or review

## Lifecycle Tree

```text
FINISH DEVELOPMENT BRANCH
│
├── ○ Run the project test suite
│
├── ◇ Tests pass?
│   ├── no  → report failures and stop
│   └── yes → continue
│
├── ○ Detect workspace state
│   ├── normal repository
│   ├── named-branch linked worktree
│   └── detached externally managed worktree
│
├── ○ Determine the base branch
│
├── ◇ Human chooses finish action
│   ├── attached branch
│   │   ├── merge
│   │   ├── draft PR
│   │   ├── keep
│   │   └── discard
│   └── detached HEAD
│       ├── draft PR
│       ├── keep
│       └── discard
│
├── ◇ Discard selected?
│   ├── no  → continue
│   └── yes → require exact "discard" confirmation
│
├── ◆ D19 execute selected release path
│   ├── role: devops_engineer
│   ├── task_type: release_deployment
│   ├── merge
│   │   ├── merge into base
│   │   ├── update and commit roadmap
│   │   ├── test merged result
│   │   └── clean owned worktree and delete branch
│   ├── pr
│   │   ├── create branch for detached HEAD when needed
│   │   ├── update and commit roadmap
│   │   ├── test, push, and validate PR body
│   │   ├── create draft PR
│   │   └── preserve worktree
│   ├── keep
│   │   └── preserve branch/HEAD and workspace
│   └── discard
│       ├── named branch → remove owned worktree and branch
│       └── detached HEAD → report abandoned SHA; host owns disposal
│
├── ◇ Did merge or PR finish?
│   ├── no → finish without graph refresh
│   └── yes
│       └── ○ inspect knowledge-graph freshness
│           ├── missing/malformed/fresh → continue
│           └── stale
│               └── ◇ Refresh now?
│                   ├── no  → continue
│                   └── yes → ◆ D20 refresh graph
│                       ├── role: technical_writer
│                       ├── task_type: documentation_knowledge_transfer
│                       └── verify graph commit hash
│
├── use-tool
│   ├── project test runner
│   ├── Git branch/merge/push/worktree commands
│   ├── gh pr create [PR path]
│   ├── superpowers-orchestrator:dispatch-agent [D19/D20]
│   └── /understand [approved stale-graph refresh only]
│
├── use-file
│   ├── read: design.md, plan.md, templates/pr-body-template.md
│   ├── read/write: roadmap.json + ROADMAP.html [merge/PR]
│   ├── write: 50-finish/pr-body.md [PR]
│   ├── read/write: knowledge-graph.json [conditional]
│   └── update: branch, worktree, remote, and PR state
│
└── ○ Hand off to the next lifecycle event
```

## File Lifecycle Tree

```text
BRANCH FINISH FILES
│
├── Skill package [tracked]
│   └── skills/finishing-a-development-branch/
│       ├── SKILL.md
│       ├── README.md
│       └── templates/
│           └── pr-body-template.md
│
├── Planning evidence [tracked, read]
│   └── docs/superpowers/features/<feature-slug>/
│       ├── design.md
│       └── plan.md
│
├── Product roadmap [tracked, merge and PR paths]
│   └── docs/superpowers/
│       ├── roadmap.json
│       └── ROADMAP.html
│
├── Knowledge graph [optional, read and conditionally regenerated]
│   ├── .ua/knowledge-graph.json
│   └── .understand-anything/knowledge-graph.json [legacy]
│
├── Finish evidence [ignored]
│   └── .superpowers/runs/<workflow-id>/
│       ├── ledger.jsonl
│       └── 50-finish/
│           └── pr-body.md [PR path only]
│
└── Git/GitHub state [updated by D19]
    ├── base branch and feature branch
    ├── remote feature branch [PR path]
    ├── draft pull request [PR path]
    └── worktree registration [removed only when owned and permitted]
```

See [E. Finish Branch](../../docs/orchestrator-workflow.md#lifecycle-tree).
