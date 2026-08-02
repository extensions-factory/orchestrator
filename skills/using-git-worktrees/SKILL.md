---
name: using-git-worktrees
description: Use when feature work or implementation-plan execution requires an isolated workspace
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.

## Step 0.5: Resume an Existing Feature Workspace

After Step 0 determines that this is a normal checkout and the user consents, if the caller supplied `<slug>`, inspect existing worktrees and matching feature branches before creating anything:

```bash
git worktree list
git branch --list "feature/<slug>*"
```

For each matching branch found, classify it with these exact checks, in order:

```bash
# 1. Is it already merged into main?
git merge-base --is-ancestor "$MATCHED_BRANCH" main && echo merged || echo unmerged

# 2. If unmerged, does it have the feature's design document?
git cat-file -e "$MATCHED_BRANCH:docs/superpowers/features/<slug>/design.md" 2>/dev/null && echo present || echo absent
```

- If `git merge-base --is-ancestor "$MATCHED_BRANCH" main` exits `0`, the branch is already merged into `main`: report it as stale or finished, do not reuse it, and continue to Step 1's fresh-creation path.
- If the branch is unmerged and `git cat-file -e "$MATCHED_BRANCH:docs/superpowers/features/<slug>/design.md" 2>/dev/null` exits `0` (the design document is present on that branch), reuse it. If `git worktree list` shows it already attached, enter that worktree. If only the branch remains because its worktree was deleted or pruned, first run `git worktree prune` to clear the stale administrative entry — otherwise `git worktree add` fails with "already checked out" even though the directory is gone — then recreate a worktree at that branch: prefer a native worktree tool; otherwise follow Step 1b's directory selection and safety verification, then run `git worktree add "$path" "$MATCHED_BRANCH"` without `-b`.
- If the branch is unmerged but the `git cat-file -e` check exits non-zero (no matching design document) or the branch otherwise looks unrelated, report the match and ask the user to choose resume or create-new. Never silently reuse it.
- If multiple branches match, report every match and its classification, and ask the user which one to resume or whether to create new. Never guess.
- If no branch or worktree matches, continue to Step 1 unchanged.

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D12` runs only when Step 0 confirms isolation is needed, the human or standing instructions consent, and Step 0.5 did not enter an existing worktree: dispatch worktree reuse or creation through `superpowers-orchestrator:dispatch-agent` with `role: devops_engineer` and `task_type: workspace_setup`; require `output.artifacts` to contain the resolved worktree path, verify it exists, then `cd` exactly once and continue with setup and baseline tests, otherwise treat the response as blocked; resolve it inline only if the harness has no subagent capability at all.
<!-- riso-tech:orchestrator-split END -->

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 2.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, set `LOCATION` to it without asking. An explicit custom location inside the project root is project-local and must pass the safety verification below; if it is absolute, normalize `LOCATION` to a repository-relative path before continuing so both `git check-ignore` and `.gitignore` use the same path. A global location outside the project root remains absolute and does not use the repository ignore check.

2. **Check for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, set `LOCATION` to it. If both exist, `.worktrees` wins.

3. **If there is no other guidance available**, default to `.worktrees/` at the project root by setting `LOCATION=.worktrees`.

#### Safety Verification (project-local directories only)

**MUST verify the selected project-local directory is ignored before creating the worktree.** This includes explicit custom project-local preferences. Native tools already exited at Step 1a, and a global `LOCATION` outside the project root skips this repository ignore check.

```bash
git check-ignore -q -- "$LOCATION/"
```

Validate only `$LOCATION/`; never OR-check candidate directories that were not selected.

**If NOT ignored:** Add `$LOCATION/` to `.gitignore`, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

#### Create the Worktree

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

## Step 2: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 3: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it; skip manual ignore validation (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Custom project-local preference | Use it; validate exactly `$LOCATION/` |
| Global location outside project root | Use it; skip repository ignore validation |
| Selected directory not ignored | Add `$LOCATION/` to `.gitignore` + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one
- **Fix:** Always run Step 0 before creating anything

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Run `git check-ignore -q -- "$LOCATION/"` for the selected project-local location, including custom preferences

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: explicit instructions > existing project-local directory > default

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

## Red Flags

**Never:**
- Create a worktree when Step 0 detects existing isolation
- Use `git worktree add` when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
- Skip Step 1a by jumping straight to Step 1b's git commands
- Create worktree without verifying the selected `$LOCATION/` is ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Run Step 0 detection first
- Prefer native tools over git fallback
- Follow directory priority: explicit instructions > existing project-local directory > default
- Verify exactly the selected `$LOCATION/` is ignored for project-local locations
- Auto-detect and run project setup
- Verify clean test baseline
