---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and an integration decision is required
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Detect Environment

**Determine workspace state before presenting options:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

### Step 3: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a draft Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a draft Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D19` executes the selected finish path only after tests pass and the human chooses an option. Resolve the chosen option's menu selection to a named action before dispatch: attached branch: 1 = `merge`, 2 = `pr`, 3 = `keep`, 4 = `discard`; detached: 1 = `pr`, 2 = `keep`, 3 = `discard`. Then call `superpowers-orchestrator:dispatch-agent` with `role: devops_engineer` and `task_type: release_deployment` for that action's Git mechanics in the documented order. The `merge` action merges first, runs the shared roadmap recipe and commits it on the base branch, then tests the merged result. The `pr` action creates a branch at detached `HEAD` when needed, runs and commits the roadmap recipe on the feature branch, tests, pushes, validates the PR body against the template, then calls `gh pr create --draft --body-file`. The `keep` and `discard` actions skip the roadmap recipe. Preserve worktrees for `pr` and `keep`; clean up only for `merge` and confirmed `discard`, except detached externally managed workspaces are never cleaned up. For detached `discard`, do not delete a branch or worktree; after confirmation, report the abandoned `HEAD` SHA and leave disposal to the external workspace manager. For any `discard`, after the human's exact discard confirmation and before dispatch, append `HUMAN_CONFIRMED_DESTRUCTIVE_RELEASE: <operation>` to `context.constraints`, replacing `<operation>` with the exact confirmed destructive operation; never infer confirmation. Run the documented commands inline only if the harness has no subagent capability at all.
<!-- riso-tech:orchestrator-split END -->

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>
```

Run the shared Step 5b recipe on `<base-branch>` now, including its roadmap commit, before running the merged-result tests.

```bash
# Verify tests on merged result after the roadmap commit
<test command>
```

Then: Cleanup worktree (Step 6), then delete branch:

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create Draft PR

Run the shared Step 5b recipe on the feature branch now, including its roadmap commit, then verify the branch before pushing.

```bash
# Verify tests on feature branch after the roadmap commit
<test command>

# Push only after the roadmap update, commit, and tests succeed
git push -u origin <feature-branch>
```

<!-- riso-tech:orchestrator-split START -->
Then create the draft PR with a body following `skills/finishing-a-development-branch/pr-body-template.md` — read it before writing. Fill every section from the spec, plan, and this session's actual test results, preserving the template's exact section headings; write the body to a temp file.

Validate the completed body before creating the draft PR. Compare it against the template line by line, reject placeholders or invented results, and run these minimum traceability checks (when no spec/plan exists, omit the Design Docs and US-ID checks as the template permits):

```bash
grep -Fqx '## Summary' <path-to-body-file>
grep -Fqx '## User Stories Delivered' <path-to-body-file>
grep -Fqx '## Key Changes' <path-to-body-file>
grep -Fqx '## Design Docs' <path-to-body-file>
grep -Fqx '## Testing' <path-to-body-file>
grep -Eq '^- \[x\] US-[0-9]+:' <path-to-body-file>
grep -Eq '^  - US-[0-9]+:' <path-to-body-file>
```

Every command that applies must succeed. Every checked User Story must have the same ID under Testing checkpoints. Only then create the PR:

```bash
gh pr create --draft --base <base-branch> --title "<type>: <feature title>" --body-file <path-to-body-file>
```

Show the user the PR URL when done.
<!-- riso-tech:orchestrator-split END -->

**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

Report the preserved branch, or the preserved `HEAD` SHA when detached, and its workspace path.

**Don't cleanup worktree.**

#### Option 4: Discard

**Named-branch discard confirmation:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

**Detached discard confirmation:**
```
This abandons detached HEAD <sha>. No branch or worktree will be deleted; the external workspace manager controls disposal.

Type 'discard' to confirm.
```

Wait for exact confirmation.

If detached, do not delete a branch or clean up the externally managed worktree. Report the abandoned `HEAD` SHA and stop; the external workspace manager owns disposal.

If confirmed on a named branch:
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then: Cleanup worktree (Step 6), then force-delete branch:
```bash
git branch -D <feature-branch>
```

<!-- riso-tech:orchestrator-split START -->
### Step 5b: Update Product Roadmap

**Runs for the `merge` and `pr` actions only** — the work is being integrated, so the feature is done. Skip for `keep` and `discard`.

- Identify the feature's `slug` from the spec/plan filename used for this work (`YYYY-MM-DD-<slug>-design.md`). If no spec/plan is in context and the slug is ambiguous, ask the user which feature this work corresponds to.
- Set every User-Story entry belonging to that feature (match on `feature` or the `slug` prefix) to `status: released` and `completed` to today's date in `docs/superpowers/roadmap.json`, then regenerate `ROADMAP.html`. If no entries exist yet, create one for the feature as released.
- See [../brainstorming/roadmap.md](../brainstorming/roadmap.md) for the schema, idempotent update rules, and the `ROADMAP.html` template.
- At the option-specific invocation point above, stage `docs/superpowers/roadmap.json` and `docs/superpowers/ROADMAP.html`, then commit them with `git commit -m "docs: release <feature>"`.
<!-- riso-tech:orchestrator-split END -->

### Step 6: Cleanup Workspace

**Only runs for `merge` and confirmed `discard`.** The `pr` and `keep` actions always preserve the worktree; detached externally managed workspaces are never cleaned up.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If worktree path is under `.worktrees/` or `worktrees/`:** Superpowers created this worktree — we own cleanup.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.

## Quick Reference

| Action | Merge | Push | Keep Worktree | Delete Branch |
|--------|-------|------|---------------|---------------|
| `merge` | yes | - | no | yes |
| `pr` | - | yes | yes | no |
| `keep` | - | - | yes | no |
| attached `discard` | - | - | no | yes (force) |
| detached `discard` | - | - | yes (external owner) | no |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)

**Cleaning up worktree for the PR action**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only clean up for `merge` and confirmed `discard`, never detached externally managed workspaces

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because worktree still references the branch
- **Fix:** Merge first, remove worktree, then delete branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/` or `worktrees/`

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree

**Always:**
- Verify tests before offering options
- Detect environment before presenting menu
- Present exactly 4 options (or 3 for detached HEAD)
- Get typed confirmation for the `discard` action
- Clean up worktrees only for `merge` and confirmed `discard`, never detached externally managed workspaces
- `cd` to main repo root before worktree removal
- Run `git worktree prune` after removal
