---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and an integration decision is required
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Approved Finish Boundary

The token-cost boundary starts when this skill is announced. Capture the exact cumulative orchestrator counter scope and baseline when the harness exposes them.

**Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace** by `workspace.type` and `workspace.target`; require exactly one session entry and preserve every other session entry. Require `writing_plans.workflow_id`, the exact approved decision snapshot, exact plan path and content hash, optional design path/hash, current execution progress, and a clean D17 whole-branch review. For feature work also require `brainstorming.acceptance_criteria`.

Use `writing_plans.workflow_id` as the active run. Reread the selected entry and rehash the plan before acceptance verification, before presenting the finish-action gate, before D19, and before an eligible D20. A mismatch returns blocked with reason `stale_input`; do not present or execute a finish action. Ambient run IDs and another session's artifacts never override the selected entry.

Every D19 and D20 request carries `DECISION_RECORD=main:docs/superpower/manifest.json`, the original finish workspace key, workflow ID, decision snapshot, plan/design paths and hashes, finish-record path, selected action or refresh decision, and this instruction: “Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.” A worker mismatch returns `stale_input` without mutation.

## Acceptance Delivery Record

Create `.superpowers/runs/<workflow-id>/50-finish/finish-record.json` before presenting any action. It contains the workspace/workflow, decision and artifact hashes, final review evidence, test evidence, and one entry for every approved acceptance criterion with its exact text, status `delivered | not_delivered | unverified`, and observed evidence or missing-evidence reason.

`all_delivered` is true only when every criterion is `delivered` with observed evidence. Tests passing and a clean review do not substitute for criterion-by-criterion proof; developer claims are not observed evidence. If any criterion is `not_delivered` or `unverified`, write the record, set `all_delivered` false, and stop. Do not present the finish-action gate. A proposal to remove, waive, or change a criterion returns to the Brainstorming Human Gate and affected downstream approval before finishing resumes.

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

This is the finish-action Human Gate. Require the exact action selected at this gate. Never infer an action from prior conversation, a plan, branch state, a worker suggestion, or "choose for me." After resolving the menu response to `merge | pr | keep | discard`, write `selected_action` and the exact human response to the finish record before any D19 call. D19 executes only that named action.

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
**Dispatch:** `D19` executes only the named selected finish path after tests pass, every acceptance criterion is delivered, and the human chooses an option at the current gate. Resolve the chosen option's menu selection to a named action before dispatch: attached branch: 1 = `merge`, 2 = `pr`, 3 = `keep`, 4 = `discard`; detached: 1 = `pr`, 2 = `keep`, 3 = `discard`. Then call `superpowers-orchestrator:dispatch-agent` with `role: devops_engineer`, `task_type: release_deployment`, the Approved Finish Boundary, and finish record for that action's Git mechanics in the documented order. The `merge` action merges first, runs the shared roadmap recipe and commits it on the base branch, then tests the merged result. The `pr` action creates a branch at detached `HEAD` when needed, runs and commits the roadmap recipe on the feature branch, tests, pushes, validates the PR body against the template, then calls `gh pr create --draft --body-file`. The `keep` and `discard` actions skip the roadmap recipe. Preserve worktrees for `pr` and `keep`; clean up only for `merge` and confirmed `discard`, except detached externally managed workspaces are never cleaned up. For detached `discard`, do not delete a branch or worktree; after confirmation, report the abandoned `HEAD` SHA and leave disposal to the external workspace manager. For any `discard`, after the human's exact discard confirmation and before dispatch, append `HUMAN_CONFIRMED_DESTRUCTIVE_RELEASE: <operation>` to `context.constraints`, replacing `<operation>` with the exact confirmed destructive operation; never infer confirmation. D19 never switches actions automatically: record a failed action as blocked, then require a new finish-action gate before another named action. Run the documented commands inline only if the harness has no subagent capability at all.
<!-- riso-tech:orchestrator-split END -->

### Step 4b: Post-Land Knowledge Graph Refresh

After D19 returns `done` for `merge` or `pr`, run this orchestrator-owned step against the landed checkout. For `keep` or `discard`, skip this entire step: do not freshness-check the graph and do not present a gate.

1. Resolve the graph read-only: use `.ua/knowledge-graph.json` first; use `.understand-anything/knowledge-graph.json` only when `.understand-anything/` exists. If the graph is absent or malformed (including a missing or null `project.gitCommitHash`), skip the gate and continue without error.
2. Freshness-check the landed graph: compare `project.gitCommitHash` with `git log -1 --format=%H -- .`. If the graph is already fresh, continue without a gate. If `git log` fails, record the one-line failure and continue without dispatch.
3. If the graph is stale, ask exactly: `Knowledge graph is stale. Refresh it now? (yes/no)`.
   - On `no`, skip the refresh and continue without error.
   - On `yes`, proceed to the D20 dispatch.
<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D20` routes through `superpowers-orchestrator:dispatch-agent` with `role: technical_writer`, `task_type: documentation_knowledge_transfer`, no provider pin, and a request to run `/understand` in the checkout; only reached after a merge or PR finish path and an explicit human `yes` at the freshness gate.
<!-- riso-tech:orchestrator-split END -->
4. When the worker returns, validate the worker response, then verify that the rebuilt graph's `project.gitCommitHash` matches the current scoped HEAD from `git log -1 --format=%H -- .`; append one result to the project ledger.
5. If the worker returns `blocked` or `needs_revision`, or the rebuilt hash is still stale, append that result to the ledger and surface it to the human. Do not retry automatically.

## Token-cost Monitoring

Use `.superpowers/runs/<workflow-id>/finishing-a-development-branch-token-cost.jsonl`. This skill owns every provider call for D19 and D20, including retries, fallbacks, blocked results, and resumed calls:

```json
{"source":"worker","task":"D19","action":"pr","turn":1,"attempt":1,"agent":"codex","model":"<exact-model>","input_tokens":123,"output_tokens":45,"unavailable_reason":null}
```

`turn` identifies one request envelope, approved snapshot, and human decision. Provider retries and fallbacks increment `attempt`; a revised request, resumed call, or newly selected action starts the next turn at attempt 1. An ineligible D20 creates no worker record.

After each harness-reported main-orchestrator invocation becomes observable, append and validate one orchestrator record before the next finish action:

```json
{"source":"orchestrator","task":"orchestrator","turn":1,"attempt":1,"agent":"claude","model":"<exact-model>","input_tokens":456,"output_tokens":78,"unavailable_reason":null}
```

Copy exact per-invocation metadata. Use monotonic cumulative-counter deltas only; after a reset, record affected counts as `null` with the reason and retain the new baseline. Otherwise keep unavailable fields `null` with a reason. **Do not estimate missing token counts** or treat them as zero. Ordinary tools get no separate record.

Do not copy this skill's usage into the caller execution ledger; the caller stopped metering at its handoff. Before the final handoff, append its orchestrator record with both counts `null` and reason `usage becomes visible only after this turn completes`. Report worker, orchestrator, and combined measured totals, unavailable reasons, full-record coverage as measured records / total records, and independent input/output field coverage. Never call a partial subtotal complete.

Update the finish record with the selected action's `done | blocked` result, resulting SHAs/PR URL/workspace state, acceptance status, graph-refresh result when eligible, and token report before the final handoff.

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
Then create the draft PR with a body following `skills/finishing-a-development-branch/templates/pr-body-template.md` — read it before writing. Fill every section from the spec, plan, and this session's actual test results, preserving the template's exact section headings; resolve the active run's finish directory with `node scripts/run-paths.mjs phase --root <repo-root> --run <workflow-id> --phase finish` and write the body to `pr-body.md` there.

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

**Inferring a finish action**
- **Problem:** Prior intent or a worker fallback replaces the human gate
- **Fix:** Execute only the action selected at the current gate; failures return to a new gate

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
