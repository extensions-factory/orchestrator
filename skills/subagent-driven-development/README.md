# Subagent-Driven Development

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator-owned action
- `◇` — status or review gate
- `↻` — repeat task, fix, or review cycle

## Lifecycle Tree

```text
SUBAGENT-DRIVEN DEVELOPMENT
│
├── ○ Read plan and active run manifest
│   ├── restore completed/active/blocked task state
│   ├── collect global constraints
│   └── create todos for remaining tasks
│
├── ○ Pre-flight plan review
│   ├── scan contradictions between tasks and constraints
│   └── blocking contradiction → ask one batched human question
│
├── ◆ D12 ensure isolated workspace
│   └── using-git-worktrees / devops_engineer / workspace_setup
│
├── For each remaining task, sequentially
│   ├── ○ Record exact pre-task BASE_SHA
│   ├── ○ Extract task brief
│   │   └── scripts/task-brief → brief.md
│   ├── ◆ D13 implement and test
│   │   ├── role: software_engineer
│   │   ├── task_type: value declared by the plan task
│   │   ├── prompt: implementer-prompt.md
│   │   ├── worker edits and tests; worker never commits
│   │   └── worker writes report.md
│   ├── ◇ Implementer status
│   │   ├── DONE / DONE_WITH_CONCERNS → validate result
│   │   ├── NEEDS_CONTEXT → provide context and re-dispatch D13 ↻
│   │   └── BLOCKED → re-scope, stronger model, split, or ask human
│   ├── ○ Commit validated worker changes
│   ├── ○ Generate task review package
│   │   └── scripts/review-package BASE_SHA HEAD → review-*.diff
│   ├── ◆ D14 task review
│   │   ├── role: tech_lead
│   │   ├── task_type: code_review_quality
│   │   └── require spec + quality verdicts
│   ├── ◇ Security-sensitive surfaces touched?
│   │   ├── no  → continue
│   │   └── yes → ◆ D15 security review
│   ├── ◇ Critical/Important findings?
│   │   ├── yes → ◆ D16 task fix
│   │   │   ├── software_engineer + receiving-code-review
│   │   │   ├── rerun covering tests
│   │   │   ├── append fix evidence to report.md
│   │   │   ├── ○ commit validated fix
│   │   │   ├── ○ regenerate review package
│   │   │   └── D14/D15 re-review ↻
│   │   └── no  → continue
│   ├── ○ Mark task done in manifest.json
│   └── more tasks? → next D13 ↻
│
├── ○ Derive branch MERGE_BASE
│
├── ○ Generate whole-branch review package
│
├── ◆ D17 final whole-branch review
│   └── tech_lead / code_review_quality
│
├── ◇ Final findings?
│   ├── yes → ◆ D18 one complete fix wave
│   │   ├── commit validated fixes
│   │   ├── regenerate whole-branch package
│   │   └── D17 re-review ↻
│   └── no  → continue
│
├── use-tool
│   ├── superpowers-orchestrator:using-git-worktrees [D12]
│   ├── superpowers-orchestrator:dispatch-agent [D13–D18]
│   ├── scripts/task-brief
│   ├── scripts/review-package
│   ├── scripts/run-paths.mjs task-status
│   ├── Git status/log/add/commit/merge-base
│   └── superpowers-orchestrator:finishing-a-development-branch
│
├── use-file
│   ├── read: design.md, plan.md, manifest.json
│   ├── read: implementer/task-reviewer/code-reviewer prompts
│   ├── create/update: brief.md + report.md
│   ├── create: reviews/review-<base7>..<head7>.diff
│   ├── create/update: request.json, review.md, response.json, ledger.jsonl
│   └── modify: task-declared source, test, config, and documentation files
│
└── ○ Invoke finishing-a-development-branch

Continuous-execution rule:
do not pause between tasks; stop only for an unresolved blocker, genuine
ambiguity, or completion of the full plan.
```

## File Lifecycle Tree

```text
SDD FILES
│
├── Skill package [tracked, read or executed]
│   └── skills/subagent-driven-development/
│       ├── SKILL.md
│       ├── README.md
│       ├── prompts/
│       │   ├── implementer-prompt.md
│       │   └── task-reviewer-prompt.md
│       ├── scripts/
│       │   ├── task-brief
│       │   ├── review-package
│       │   └── sdd-workspace
│       └── templates/
│           └── task-report-template.md
│
├── Durable requirements [tracked, read]
│   └── docs/superpowers/features/<feature-slug>/
│       ├── design.md
│       └── plan.md
│
├── Implementation files [tracked, created or modified]
│   ├── source files declared by each task
│   ├── test files declared by each task
│   └── config/docs declared by each task
│
└── Runtime execution evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── manifest.json
        ├── ledger.jsonl
        └── 40-execution/
            └── tasks/<task>/
                ├── brief.md
                ├── report.md
                ├── reviews/
                │   └── review-<base7>..<head7>.diff
                └── turns/
                    ├── <NNN>-implement/
                    │   ├── request.json
                    │   └── response.json
                    ├── <NNN>-review/
                    │   ├── request.json
                    │   ├── review.md
                    │   └── response.json
                    └── <NNN>-fix/
                        ├── request.json
                        └── response.json
```

See [D. Execute Plan](../../docs/orchestrator-workflow.md#lifecycle-tree).
