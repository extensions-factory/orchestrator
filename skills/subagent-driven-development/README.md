# Subagent-Driven Development

## Description

Executes an approved implementation plan sequentially with fresh implementation/fix workers, task reviews, and a final whole-branch review while preserving human-owned decisions.

## Inputs

- The current workspace and exactly matching session in the single `main:docs/superpower/manifest.json`.
- Approved Brainstorming scope/exclusions/acceptance criteria and the complete seven-field Writing Plans decision with workflow ID.
- Exact current plan/design paths and content hashes from the planning/refine handoff.
- Task briefs, prior-task interfaces, review evidence, Git history, and exact per-invocation token metadata.

## Durable Output

Implementation and test changes are committed by the orchestrator after successful workers. Each task retains its brief, report, diff review package, dispatch ledger evidence, and append-only `subagent-driven-development-progress.jsonl`. SDD-owned D13/D16/D18 and orchestrator usage is stored in `subagent-driven-development-token-cost.jsonl`.

## Human Decisions

Workers and reviewers may identify decision changes but cannot apply them. Product scope, exclusions, or acceptance-criteria proposals return to Brainstorming; build-order, file, interface, test, or verification proposals return to Writing Plans. Approval regenerates affected artifacts and invalidates completed-task evidence that no longer matches.

## Handoff

After every task has current-snapshot implementation and clean review evidence, SDD rechecks the selected main-manifest session and plan/design hashes, then invokes Finishing a Development Branch once with decision, progress, final-review, and token-cost context.

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator-owned action
- `◇` — status or review gate
- `↻` — repeat task, fix, or review cycle

## Lifecycle Tree

```text
SUBAGENT-DRIVEN DEVELOPMENT
│
├── ○ Select current main-manifest session and approved plan
│   ├── bind decision snapshot + plan/design hashes
│   ├── reconcile progress JSONL with Git history
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
│   │   ├── carry decision snapshot + plan path/hash
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
│   │   ├── carry the same decision/plan boundary
│   │   └── require spec + quality verdicts
│   ├── ◇ Security-sensitive surfaces touched?
│   │   ├── no  → continue
│   │   └── yes → ◆ D15 security review
│   ├── ◇ Critical/Important findings?
│   │   ├── decision change → owning human gate; regenerate/revalidate
│   │   ├── implementation issue → ◆ D16 task fix
│   │   │   ├── software_engineer + receiving-code-review
│   │   │   ├── rerun covering tests
│   │   │   ├── append fix evidence to report.md
│   │   │   ├── ○ commit validated fix
│   │   │   ├── ○ regenerate review package
│   │   │   └── D14/D15 re-review ↻
│   │   └── no  → continue
│   ├── ○ Append verified task checkpoint to progress JSONL
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
│   ├── decision change → owning human gate; regenerate/revalidate
│   ├── implementation issues → ◆ D18 one complete fix wave
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
│   ├── Git status/log/add/commit/merge-base
│   └── superpowers-orchestrator:finishing-a-development-branch
│
├── use-file
│   ├── read: main:docs/superpower/manifest.json + design.md + plan.md
│   ├── read: implementer/task-reviewer/code-reviewer prompts
│   ├── create/update: brief.md + report.md
│   ├── create: reviews/review-<base7>..<head7>.diff
│   ├── create/update: request.json, review.md, response.json, ledger.jsonl,
│   │   progress JSONL, and token-cost JSONL
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
│   ├── main:docs/superpower/manifest.json [single decision record]
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
        ├── ledger.jsonl
        ├── subagent-driven-development-progress.jsonl
        ├── subagent-driven-development-token-cost.jsonl
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
