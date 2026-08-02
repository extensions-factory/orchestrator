# Using Git Worktrees

## Description

Creates, recreates, or reuses an isolated Git workspace without losing the selected session, workflow run, or canonical decision record.

## Inputs

- One selected `workspace.type` and `workspace.target` from the single `main:docs/superpower/manifest.json`.
- The caller's existing workflow ID; this skill never creates a replacement.
- Current Git branch/worktree registrations, which determine resumability.
- Human consent or standing worktree preference plus harness capabilities.
- Exact per-invocation or comparable cumulative token metadata.

## Durable Output

Git owns the created/reused branch and worktree registration. `.superpowers/runs/<workflow-id>/using-git-worktrees-token-cost.jsonl` records D12 worker attempts and main-orchestrator invocations. The single manifest remains on `main` and is read-only here.

## Human Decisions

The human chooses whether to use isolation when no standing preference exists. The Session Gate owns session selection and resolves ambiguity; this skill cannot substitute a slug match, ambient run, directory preference, or worker response for that decision.

## Handoff

After entering or retaining a workspace, the orchestrator rereads the main manifest and proves the actual Git workspace matches the original selected entry. The ready/blocked result carries the workspace key, unchanged workflow ID, `main:docs/superpower/manifest.json`, resolved path, setup/baseline result, and worker/orchestrator token report.

## Legend

- `◆ D12` — workspace-setup dispatch
- `○` — orchestrator inspection or verification
- `◇` — consent, state, or test gate

## Lifecycle Tree

```text
WORKTREE SETUP
│
├── Step 0 — ○ Detect current isolation
│   ├── resolve git-dir and git-common-dir
│   ├── guard against submodules
│   ├── inspect current branch or detached HEAD
│   └── bind selected main-manifest session + workflow ID
│
├── ◇ Already in a linked worktree?
│   ├── yes → reuse it; skip creation
│   └── no  → continue
│
├── ◇ Standing preference or human consent permits isolation?
│   ├── no  → work in current checkout
│   └── yes → continue
│
├── Step 0.5 — ○ Resume lookup
│   ├── git worktree list + git branch --list
│   ├── classify the exact selected branch/worktree
│   └── reuse attached; send pruned recreation to D12; report other matches
│
├── ◆ D12 create/recreate selected workspace
│   ├── role: devops_engineer
│   ├── task_type: workspace_setup
│   ├── carry workflow ID + main decision-record path unchanged
│   └── require and verify created worktree path
│
├── Step 1 — choose creation mechanism
│   ├── native harness worktree tool available
│   │   └── use native tool; host owns placement/lifecycle
│   └── no native tool
│       └── Git fallback
│           ├── choose location
│           │   ├── explicit instruction
│           │   ├── existing .worktrees/
│           │   ├── existing worktrees/
│           │   └── default .worktrees/
│           ├── project-local location → verify gitignored
│           ├── add and commit ignore rule when missing
│           └── git worktree add <path> -b <branch>
│
├── Step 2 — ○ Run project setup
│   ├── Node → install dependencies
│   ├── Rust → build
│   ├── Python → install environment
│   └── Go → download modules
│
├── Step 3 — ○ Run clean baseline tests
│
├── ○ Reread main manifest and verify entered workspace/session
│
├── ○ Report worker + orchestrator token totals and coverage
│
├── use-tool
│   ├── Git rev-parse/check-ignore/worktree commands
│   ├── native harness worktree tool [preferred when available]
│   ├── superpowers-orchestrator:dispatch-agent [D12]
│   ├── package manager/build tool selected from project manifests
│   └── project-specific test runner
│
├── use-file
│   ├── read: .git metadata and current branch state
│   ├── read/update: .gitignore [project-local fallback only]
│   ├── read: package.json/Cargo.toml/requirements.txt/pyproject.toml/go.mod
│   └── create: isolated worktree directory and generated dependency caches
│
└── ◇ Baseline passes?
    ├── no  → report failures and ask whether to investigate/proceed
    └── yes → report workspace ready for implementation
```

## File Lifecycle Tree

```text
WORKTREE FILES
│
├── Skill package [tracked]
│   ├── skills/using-git-worktrees/SKILL.md
│   └── skills/using-git-worktrees/README.md
│
├── Main repository [existing]
│   ├── .git/
│   │   └── worktrees/<branch>/ [Git-managed registration]
│   ├── .gitignore [updated only when project-local location is not ignored]
│   └── docs/superpower/manifest.json [authoritative on main, read-only here]
│
├── Isolated workspace [created when needed]
│   ├── .worktrees/<branch>/ [default project-local fallback]
│   ├── worktrees/<branch>/ [existing alternative]
│   ├── <explicit-global-location>/<branch>/ [user preference]
│   └── <host-managed-path>/ [native tool]
│
└── Workspace contents [installed/generated, normally ignored]
    ├── dependency directories and caches
    ├── build outputs
    ├── baseline test outputs
    └── .superpowers/runs/<workflow-id>/using-git-worktrees-token-cost.jsonl
```

Cleanup belongs to `finishing-a-development-branch`, which removes only worktrees Superpowers owns.
