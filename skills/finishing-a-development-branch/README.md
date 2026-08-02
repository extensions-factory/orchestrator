# Finishing a Development Branch

## Description

Verifies completed work and lets the human choose how an approved development branch is integrated, preserved, or discarded.

## Inputs

- The current workspace and exactly matching session in the single `main:docs/superpower/manifest.json`.
- Approved decision snapshot, Brainstorming acceptance criteria, exact plan/design paths and hashes, execution progress, and clean final review evidence.
- Current Git/worktree state, base branch, observed test/checkpoint results, and exact worker/orchestrator token metadata.

## Durable Output

`50-finish/finish-record.json` records every acceptance criterion's delivery evidence, the exact human-selected action, action result, resulting Git/PR/workspace state, and token coverage. PR paths also retain `pr-body.md`; all finish-owned D19/D20 and orchestrator usage is stored in `finishing-a-development-branch-token-cost.jsonl`.

## Human Decisions

The human explicitly chooses `merge`, `pr`, `keep`, or `discard` at the finish gate; no prior intent or worker suggestion substitutes. Discard requires its second exact confirmation. An approved acceptance-criteria change returns to Brainstorming before finishing can resume; stale-graph refresh remains a separate optional gate.

## Handoff

Return the selected action and outcome, acceptance-delivery matrix, resulting SHAs/PR URL/workspace state, graph-refresh result, and worker/orchestrator token report. Blocked actions return to a new finish gate rather than switching automatically.

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human decision or destructive-action gate
- `↻` — return to verification or review

## Lifecycle Tree

```text
FINISH DEVELOPMENT BRANCH
│
├── ○ Select current main-manifest session and approved plan
│   └── bind decision snapshot + plan/design hashes + clean D17
│
├── ○ Build acceptance-delivery matrix
│   ├── one status + observed evidence per approved criterion
│   └── persist 50-finish/finish-record.json
│
├── ◇ Every acceptance criterion delivered?
│   ├── no  → record gaps and return to execution/owning decision gate
│   └── yes → run the project test suite
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
│   ├── record exact response + named action
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
│   ├── carry approved finish boundary + finish record
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
├── ◇ D19 blocked?
│   ├── yes → record result and return to a new finish-action gate
│   └── no  → continue
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
│   ├── write: 50-finish/finish-record.json + pr-body.md [PR]
│   ├── read/write: knowledge-graph.json [conditional]
│   └── update: token-cost JSONL, branch, worktree, remote, and PR state
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
├── Approved inputs [tracked, read]
│   ├── main:docs/superpower/manifest.json [single decision record]
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
│       ├── finishing-a-development-branch-token-cost.jsonl
│       └── 50-finish/
│           ├── finish-record.json
│           └── pr-body.md [PR path only]
│
└── Git/GitHub state [updated by D19]
    ├── base branch and feature branch
    ├── remote feature branch [PR path]
    ├── draft pull request [PR path]
    └── worktree registration [removed only when owned and permitted]
```
