# Using Git Worktrees

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
│   └── inspect current branch or detached HEAD
│
├── ◇ Already in a linked worktree?
│   ├── yes → reuse it; skip creation
│   └── no  → continue
│
├── ◇ Standing preference or human consent permits isolation?
│   ├── no  → work in current checkout
│   └── yes → continue
│
├── ◆ D12 create isolated workspace
│   ├── role: devops_engineer
│   ├── task_type: workspace_setup
│   └── require and verify returned worktree path
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
│   └── .gitignore [updated only when project-local location is not ignored]
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
    └── baseline test outputs
```

Cleanup belongs to `finishing-a-development-branch`, which removes only worktrees Superpowers owns.
