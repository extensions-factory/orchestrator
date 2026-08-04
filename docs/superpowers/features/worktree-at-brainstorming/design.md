---
title: Branch/worktree per feature, created at brainstorming start
date: 2026-08-01
status: draft
---

# Branch/worktree per feature, created at brainstorming start — Design Spec

## 1. Overview

Today, `superpowers-orchestrator:brainstorming` writes and commits the design spec, and `superpowers-orchestrator:writing-plans` commits the plan, on whatever branch the orchestrator started on—normally `main`. Only `superpowers-orchestrator:executing-plans` or `superpowers-orchestrator:subagent-driven-development` creates an isolated Git worktree and branch, and only at execution time. As a result, a feature's spec and plan land directly on `main` while only its code is isolated. This feature moves worktree and branch creation to the start of brainstorming so the spec, plan, and code all land on one feature branch from the first commit, while `superpowers-orchestrator:finishing-a-development-branch` remains unchanged at the end.

## 2. Context & Assumptions

- `brainstorming` currently invokes no worktree or branch step; `using-git-worktrees` is referenced only by `executing-plans` and `subagent-driven-development`.
- `writing-plans/SKILL.md` currently says, "If working in an isolated worktree, it should have been created via the `superpowers-orchestrator:using-git-worktrees` skill at execution time." That statement becomes false when creation moves to brainstorming and must be corrected.
- `using-git-worktrees` Step 0 already detects an existing isolated workspace when `GIT_DIR != GIT_COMMON` and skips creation. If the orchestrator remains in the worktree created during brainstorming, later execution-phase calls are naturally no-ops; no same-session logic change is needed.
- Assumption: this change applies only to feature work in an existing repository. `project-kickoff` is out of scope because a greenfield project has no existing `main` branch to protect.
- Assumption: the consent prompt in `using-git-worktrees` Step 0—"Would you like me to set up an isolated worktree?"—stays unchanged. A decline continues work in place on the current branch, as it does today.

## 3. Scope

### Goals

- Create the feature branch and worktree at brainstorming start, after project-context exploration and the scope/decompose check but before clarifying questions, rather than at execution time.
- Derive the initial branch and worktree slug by kebab-slugifying the user's initial request or idea and truncating it to approximately five words; use the branch name `feature/<slug>`.
- Support resuming a feature in a fresh CLI session at the main repository root by checking for an existing unmerged branch that matches the slug before creating a new one.
- Update `writing-plans`' stale Context line to describe the new creation time.
- Update worktree-related wording in `executing-plans` and `subagent-driven-development`; their behavior remains unchanged because `using-git-worktrees` Step 0 already skips creation in an existing isolated workspace.

### Non-Goals

- No change to `finishing-a-development-branch`'s merge, pull-request, keep, discard, or cleanup behavior.
- No change to `project-kickoff` for greenfield projects without an existing repository or `main` branch.
- No change to the `using-git-worktrees` consent prompt or its directory-selection priority.
- No new automated test framework for skill content. Verification uses manual walkthroughs plus the existing `evals/` harness through `superpowers-orchestrator:writing-skills` during implementation.

## 4. User Stories

### US-1: Branch/worktree created at brainstorming start (Priority: P1)

As an orchestrator running the brainstorming skill for a new feature, I want an isolated feature branch/worktree created immediately after project-context exploration and the scope check, before clarifying questions begin, so that the spec, the plan, and all implementation for this feature land on one branch instead of the spec and plan committing directly to `main`.

**Acceptance criteria:**

- GIVEN a new feature idea and a single appropriately-sized project whose scope check did not require decomposition WHEN brainstorming reaches the new step after project-context exploration THEN `using-git-worktrees` is invoked with a slug auto-slugified from the user's initial request before any clarifying question is asked.
- GIVEN the user declines the worktree consent prompt WHEN brainstorming continues THEN work proceeds in place on the current branch exactly as it does today.
- GIVEN the request describes multiple independent subsystems that require decomposition WHEN brainstorming performs the scope check THEN no branch is created for the umbrella request, and each sub-project creates its own branch only when that sub-project's brainstorming begins.
- GIVEN the feature's real name changes materially during brainstorming before the design document is written WHEN the design is about to be written THEN the branch and worktree directory are renamed to match the new slug, while cosmetic or minor wording drift does not trigger a rename.
- GIVEN the branch and worktree already exist for this session WHEN `writing-plans` or an execution-phase skill runs afterward THEN no duplicate worktree is created because `using-git-worktrees` Step 0 detects the existing isolation and skips creation.

### US-2: Resume an in-progress feature branch in a fresh session (Priority: P1)

As an orchestrator resuming work on a feature in a new CLI session started at the main repository root, I want `using-git-worktrees` to look for an existing unmerged branch/worktree matching the feature's slug before creating a new one, so that resuming work does not create a duplicate branch when the spec and plan exist only on the feature branch.

**Acceptance criteria:**

- GIVEN an unmerged branch `feature/<slug>` already exists from an earlier session and `docs/superpowers/features/<slug>/design.md` is present on that branch WHEN `using-git-worktrees` is invoked again with the same slug THEN it reuses that branch and worktree instead of creating a new one.
- GIVEN a branch matching the slug exists but has already been merged into `main` WHEN `using-git-worktrees` is invoked with that slug THEN it treats the branch as stale or finished and creates a fresh branch instead of reusing it.
- GIVEN a branch matching the slug exists and is unmerged but has no matching `docs/superpowers/features/<slug>/design.md` WHEN `using-git-worktrees` is invoked THEN it reports the ambiguous match and asks the user to confirm resume versus create-new rather than silently reusing it.
- GIVEN no branch or worktree matches the slug WHEN `using-git-worktrees` is invoked THEN it creates a new one exactly as it does today.

## 5. Approach

Add a brainstorming checklist step after project-context exploration and the scope check, but before clarifying questions, that invokes `using-git-worktrees` with a slug derived from the user's initial request. Extend `using-git-worktrees` immediately before its existing Step 1 so it searches `git worktree list` and `git branch --list feature/<slug>*`: reuse an unmerged match when the matching design document is present, treat a merged match as stale and create fresh, and ask the user when an unmerged match is ambiguous. Keep its consent gate, directory-selection priority, and fallbacks unchanged. Correct wording in `writing-plans`, `executing-plans`, and `subagent-driven-development` so those skills no longer claim that workspace creation happens at execution time; their worktree logic does not change.

### Alternatives considered

| Option | Why rejected |
|--------|--------------|
| Create the branch only after the design is approved, immediately before writing `design.md` | This delays isolation until after most of the conversation and makes the trigger inconsistent with protecting work from the first commit. The approved trigger is after context exploration and before clarifying questions. |
| Skip the worktree consent prompt and always create a branch | The existing Step 0 prompt and decline fallback are intentional. Removing them would be a larger, unrequested behavior change to an already-tuned skill. |
| Ask the user for an explicit short slug as the first clarifying question | Auto-slugifying avoids adding a question to every brainstorming session. Rename-on-drift handles a material change between the initial wording and the final feature name. |
| Leave fresh-session resume out of scope and require the human to identify the branch manually | Moving the spec and plan off `main` removes their visibility from a fresh main-root session. Manual recovery would regress the current implicit resume experience, so resume lookup is included as US-2. |

## 6. Design

### Architecture

- `brainstorming/SKILL.md`: insert checklist item 2, **Create isolated workspace**, between **Explore project context** and **Ask clarifying questions**; renumber later items and update the Process Flow diagram. Run the step only after the existing scope check confirms one appropriately-sized project. For decomposition, defer workspace creation to each sub-project's own brainstorming pass. Pass `using-git-worktrees` a kebab-case slug of approximately five words derived from the user's initial request.
- `using-git-worktrees/SKILL.md`: add resume lookup before the existing **Step 1: Create Isolated Workspace**. Run `git worktree list` and `git branch --list feature/<slug>*` only after Step 0 determines the session is in a normal checkout and the user consents. Step 0, its consent gate, and all existing creation behavior remain unchanged.
- `writing-plans/SKILL.md`: revise the Context line to state that brainstorming already created the worktree and that plan writing continues in the same workspace.
- `executing-plans/SKILL.md` and `subagent-driven-development/SKILL.md`: revise the `using-git-worktrees` wording to describe verifying or continuing the workspace created during brainstorming. Their calls remain unchanged, and Step 0 keeps them as same-session no-ops.

### Components & Interfaces

| Component | Responsibility and interface | Dependencies |
|-----------|------------------------------|--------------|
| `brainstorming` (caller) | Supplies the slug to `using-git-worktrees` and consumes the reported state—created, reused, or working in place—to determine where later `design.md` and `plan.md` writes land. | `using-git-worktrees` |
| `using-git-worktrees` (callee) | Keeps its public reporting contract, including `Worktree ready at <path>` and existing in-place or detached fallbacks. Adds reporting for reused-existing versus newly-created and asks the ambiguous-match question when required. | Local Git and its existing native-worktree-tool detection; no new external dependency |
| `writing-plans`, `executing-plans`, and `subagent-driven-development` | Keep their existing interfaces and calls to or reliance on `using-git-worktrees`; only their description of when the workspace was created changes. | Existing skill workflow |

### Data Model & Flow

```text
user's initial idea text
  -> kebab-slugify (approximately five words)
  -> slug
  -> branch feature/<slug>
  -> worktree directory selected by existing priority:
       explicit preference
       > existing project-local .worktrees/ or worktrees/
       > default .worktrees/
  -> docs/superpowers/features/<slug>/design.md
  -> docs/superpowers/features/<slug>/plan.md

fresh-session resume
  -> git branch --list feature/<slug>* + git worktree list
  -> inspect matched branch for docs/superpowers/features/<slug>/design.md
  -> reuse | create fresh | ask user

material feature-name drift before design.md
  -> new slug
  -> git branch -m old-branch new-branch
  -> rename or move the worktree directory to match
```

The spec and plan paths do not change; only the branch on which they are committed changes.

### Error Handling

| Condition | Behavior |
|-----------|----------|
| User declines consent in `using-git-worktrees` Step 0 | Continue in place on the current branch, identical to today's fallback. |
| Sandbox denies worktree creation | Use the existing work-in-place fallback, unchanged. |
| Matching branch is already merged into `main` | Treat it as stale or finished; do not reuse it, and create a fresh branch under the same name because the earlier branch is fully integrated. |
| Matching branch is unmerged and contains `docs/superpowers/features/<slug>/design.md` | Reuse it as the in-progress feature branch. |
| Matching branch is unmerged but lacks the matching design document or otherwise looks unrelated | Report the match and ask the user to confirm resume versus creating a new branch; never silently reuse it. |

### Edge Cases

- If multiple unmerged branches match the slug pattern, such as `feature/<slug>` and `feature/<slug>-v2`, report all matches rather than guessing which one to resume.
- If the worktree directory was deleted or pruned externally but its branch still exists and is unmerged, recreate the worktree at that branch instead of creating another branch.
- If a material feature-name change produces a slug that collides with an unrelated existing branch, surface the collision before renaming and do not overwrite or rename onto that branch silently.

## 7. Testing Strategy

This feature changes skill prose rather than application code, so it adds no automated test framework or repository code test. Verification consists of the following manual and eval-based checks:

- **US-1 walkthrough:** Run brainstorming for a single appropriately-sized feature with consent granted. Confirm workspace creation occurs after context exploration and the scope check but before the first clarifying question, and confirm the design and plan commits land on `feature/<slug>` with no brainstorming or plan-writing commit on `main`.
- **US-1 fallback and scope variants:** Repeat with consent declined, an umbrella request that requires decomposition, a material feature-name change, and a cosmetic name change. Confirm work-in-place, per-sub-project creation, required rename, and no rename respectively.
- **US-1 same-session continuation:** Continue from brainstorming into `writing-plans` and each execution workflow. Confirm `using-git-worktrees` Step 0 recognizes the existing isolated workspace and no duplicate worktree is created.
- **US-2 fresh-session walkthrough:** From a new CLI session at the main repository root, exercise an unmerged branch with a matching design document, a merged matching branch, an ambiguous unmerged match without a design document, and no match. Confirm reuse, fresh creation, an explicit user choice, and unchanged creation respectively. Also exercise multiple matches and a pruned worktree directory.
- **Skill-change evaluation gate:** Per the repository's `CLAUDE.md` skill-change requirement, the later edits to `SKILL.md` files must be developed through `superpowers-orchestrator:writing-skills`, adversarially pressure-tested across multiple sessions, and supported by before/after eval evidence from `evals/`. This gate belongs to the implementation plan, not this design deliverable.

## 8. Success Criteria

- SC-1: For a newly brainstormed, appropriately-sized feature with consent given, `git log` shows both the `design.md` and `plan.md` commits on `feature/<slug>`, with zero new commits added directly to `main` during brainstorming or plan writing.
- SC-2: Starting a fresh session at the main repository root and asking to resume an in-progress feature reuses the existing `feature/<slug>` branch and worktree, as shown by `git branch --list` and `git worktree list`, and does not create a second branch for the same feature.
- SC-3: `finishing-a-development-branch`'s merge, pull-request, keep, and discard flow and its Step 4b knowledge-graph gate run unchanged against the branch created during brainstorming, with no new integration-time errors caused by the earlier creation point.
