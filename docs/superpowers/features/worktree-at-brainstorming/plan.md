# Branch/worktree per feature, created at brainstorming start Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development when the harness supports subagents; use superpowers-orchestrator:executing-plans only when the harness has no subagent capability. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** `docs/superpowers/features/worktree-at-brainstorming/design.md`

**Goal:** Create or resume each feature's isolated branch and worktree at brainstorming start so its spec, plan, and implementation stay together off `main`.

**Architecture:** `brainstorming` derives a short feature slug and invokes `using-git-worktrees` after context exploration and scope decomposition but before clarifying questions; `using-git-worktrees` reuses an unmerged matching feature workspace when it is safe to do so. The planning and execution skills retain their current calls and behavior, with wording corrected to reflect that isolation now begins during brainstorming.

**Tech Stack:** Markdown skill definitions, Git branches and worktrees, Graphviz DOT process diagrams, and the existing `evals/` skill-behavior harness.

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- US-1: an orchestrator can begin a suitably scoped feature in `feature/<slug>` before asking clarifying questions, while preserving consent, decomposition, rename-on-material-drift, and same-session no-op behavior.
- US-2: an orchestrator starting from the main checkout can resume an unmerged matching feature workspace, reject merged matches, ask about ambiguous matches, or create a new workspace when no match exists.

### Artifacts

- `skills/brainstorming/SKILL.md` owns the new workspace-creation checklist step and revised process flow.
- `skills/using-git-worktrees/SKILL.md` owns fresh-session resume lookup and match classification.
- `skills/writing-plans/SKILL.md` states that plan writing continues in the workspace created during brainstorming.
- `skills/executing-plans/SKILL.md` and `skills/subagent-driven-development/SKILL.md` describe verification and continuation of the brainstorming-created workspace.
- Before/after pressure-test evidence records the behavior change for each edited skill.

### How to see it working

- Run the approved spec's US-1 and US-2 walkthroughs through `superpowers-orchestrator:writing-skills`: observe workspace creation before the first clarifying question, design and plan work remaining on `feature/<slug>`, same-session execution avoiding duplicates, and fresh sessions producing reuse, fresh creation, or an explicit ambiguity question according to branch state.

## Global Constraints

- No change to `finishing-a-development-branch`'s merge, pull-request, keep, discard, or cleanup behavior.
- No change to `project-kickoff` for greenfield projects without an existing repository or `main` branch.
- No change to the `using-git-worktrees` consent prompt or its directory-selection priority.
- No new automated test framework for skill content. Verification uses manual walkthroughs plus the existing `evals/` harness through `superpowers-orchestrator:writing-skills` during implementation.

---

## Foundation

### Task 1: Correct the plan-writing workspace context

**Depends on:** none

**Files:**
- Modify: `skills/writing-plans/SKILL.md:16`
- Test: No automated test file; use `superpowers-orchestrator:writing-skills` pressure testing and record before/after eval evidence.

**Interfaces:**
- Consumes: the workspace created or deliberately declined during `superpowers-orchestrator:brainstorming`.
- Produces: an exact Context statement telling plan writers to continue in that same workspace.

**task_type:** implementation_coding

- [ ] **Step 1: Replace the stale Context line**

Before (exact current text):

```diff
-**Context:** If working in an isolated worktree, it should have been created via the `superpowers-orchestrator:using-git-worktrees` skill at execution time.
```

After (exact replacement):

```diff
+**Context:** If working in an isolated worktree, it should have been created via the `superpowers-orchestrator:using-git-worktrees` skill during brainstorming; continue writing the plan in that same workspace.
```

- [ ] **Step 2: Run pressure testing and record the behavior change**

Run the edited skill through `superpowers-orchestrator:writing-skills`' pressure-testing process and record the before/after behavior difference.

Expected: before the edit, a plan-writing scenario says isolation was created at execution time; after the edit, it recognizes the brainstorming-created workspace and continues there without creating or requesting a second workspace.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with recorded pressure-test evidence, the orchestrator runs this before generating the task review package:

```bash
git add skills/writing-plans/SKILL.md
git commit -m "docs: correct plan workspace context"
```

The worker never runs these commands.

### Task 2: Correct the executing-plans worktree wording

**Depends on:** none

**Files:**
- Modify: `skills/executing-plans/SKILL.md:72`
- Test: No automated test file; use `superpowers-orchestrator:writing-skills` pressure testing and record before/after eval evidence.

**Interfaces:**
- Consumes: `using-git-worktrees` Step 0's existing-isolation detection.
- Produces: execution guidance that verifies and continues the workspace created during brainstorming without changing the call.

**task_type:** implementation_coding

- [ ] **Step 1: Replace the using-git-worktrees integration line**

Before (exact current text):

```diff
-- **superpowers-orchestrator:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
```

After (exact replacement):

```diff
+- **superpowers-orchestrator:using-git-worktrees** - Verifies and continues the isolated workspace created during brainstorming; its existing-isolation check prevents duplicate creation
```

- [ ] **Step 2: Run pressure testing and record the behavior change**

Run the edited skill through `superpowers-orchestrator:writing-skills`' pressure-testing process and record the before/after behavior difference.

Expected: before the edit, an execution scenario describes worktree creation as an execution-time responsibility; after the edit, it still calls `using-git-worktrees` but treats Step 0 as verification and continues the existing brainstorming-created workspace.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with recorded pressure-test evidence, the orchestrator runs this before generating the task review package:

```bash
git add skills/executing-plans/SKILL.md
git commit -m "docs: clarify execution workspace verification"
```

The worker never runs these commands.

### Task 3: Correct the subagent workflow's worktree wording

**Depends on:** none

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:436`
- Test: No automated test file; use `superpowers-orchestrator:writing-skills` pressure testing and record before/after eval evidence.

**Interfaces:**
- Consumes: `using-git-worktrees` Step 0's existing-isolation detection.
- Produces: subagent-driven execution guidance that verifies and continues the workspace created during brainstorming without changing the call.

**task_type:** implementation_coding

- [ ] **Step 1: Replace the using-git-worktrees integration line**

Before (exact current text):

```diff
-- **superpowers-orchestrator:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
```

After (exact replacement):

```diff
+- **superpowers-orchestrator:using-git-worktrees** - Verifies and continues the isolated workspace created during brainstorming; its existing-isolation check prevents duplicate creation
```

- [ ] **Step 2: Run pressure testing and record the behavior change**

Run the edited skill through `superpowers-orchestrator:writing-skills`' pressure-testing process and record the before/after behavior difference.

Expected: before the edit, a subagent-driven execution scenario describes worktree creation as an execution-time responsibility; after the edit, it still calls `using-git-worktrees` but treats Step 0 as verification and continues the existing brainstorming-created workspace.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with recorded pressure-test evidence, the orchestrator runs this before generating the task review package:

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "docs: clarify subagent workspace verification"
```

The worker never runs these commands.

## US-1: Branch/worktree created at brainstorming start

### Task 4: Add isolated workspace creation to brainstorming

**Depends on:** Foundation

**Files:**
- Modify: `skills/brainstorming/SKILL.md:24-65`
- Test: No automated test file; use `superpowers-orchestrator:writing-skills` pressure testing and record before/after eval evidence.

**Interfaces:**
- Consumes: the user's initial request text, the existing brainstorming scope check, and `superpowers-orchestrator:using-git-worktrees`' consent and existing-isolation behavior.
- Produces: a kebab-case slug of approximately five words, a `feature/<slug>` workspace before clarifying questions, and material-name-drift rename guidance before `design.md` is written.

**task_type:** implementation_coding

- [ ] **Step 1: Replace the checklist with the workspace-aware sequence**

Before (exact current text):

```diff
-1. **Explore project context** — check files, docs, recent commits, then collect graph context inline and best-effort before normal file exploration:
-   - Resolve the graph path read-only: use `.ua/knowledge-graph.json` when present; otherwise use `.understand-anything/knowledge-graph.json` only when `.understand-anything/` exists. If neither graph exists, note `Knowledge graph missing or stale; continuing with file exploration.` and continue.
-   - Compare `project.gitCommitHash` with `git log -1 --format=%H -- .`. If the graph is malformed, `git log` fails, or the hashes differ, note `Knowledge graph missing or stale; continuing with file exploration.` and continue.
-   - When the graph is fresh, `grep_search` the graph for the feature keywords and seed context from matching node names, summaries, and edge targets. If there are no matches, continue normal file exploration without error.
-   - Never call `/understand`, dispatch a worker, write the graph, or block normal file exploration from this collect step.
-2. **Offer the visual companion just-in-time** — NOT upfront. The first time a question would genuinely be clearer shown than described, offer it then (its own message); on approval its browser tab opens for you. If no visual question ever arises, never offer it. See the Visual Companion section below.
-3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
-4. **Propose 2-3 approaches** — with trade-offs and your recommendation
-5. **Present design** — in sections scaled to their complexity, get user approval after each section
-<!-- riso-tech:orchestrator-split START -->
-6. **Write design doc** — save to `docs/superpowers/features/<feature-slug>/design.md` following `skills/brainstorming/templates/spec-template.md`, generate `design.html` from `templates/document-companion-template.html`, add the feature to the product roadmap (see Documentation), and commit all
-<!-- riso-tech:orchestrator-split END -->
-7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
-8. **User reviews written spec** — ask user to review the spec file before proceeding
-9. **Transition to implementation** — invoke `superpowers-orchestrator:writing-plans` to create implementation plan
```

After (exact replacement):

```diff
+1. **Explore project context** — check files, docs, recent commits, then collect graph context inline and best-effort before normal file exploration:
+   - Resolve the graph path read-only: use `.ua/knowledge-graph.json` when present; otherwise use `.understand-anything/knowledge-graph.json` only when `.understand-anything/` exists. If neither graph exists, note `Knowledge graph missing or stale; continuing with file exploration.` and continue.
+   - Compare `project.gitCommitHash` with `git log -1 --format=%H -- .`. If the graph is malformed, `git log` fails, or the hashes differ, note `Knowledge graph missing or stale; continuing with file exploration.` and continue.
+   - When the graph is fresh, `grep_search` the graph for the feature keywords and seed context from matching node names, summaries, and edge targets. If there are no matches, continue normal file exploration without error.
+   - Never call `/understand`, dispatch a worker, write the graph, or block normal file exploration from this collect step.
+2. **Create isolated workspace** — after the scope check confirms one appropriately-sized feature and before asking any clarifying question:
+   - Kebab-slugify approximately five words from the user's initial request and use the branch name `feature/<slug>`.
+   - Invoke `superpowers-orchestrator:using-git-worktrees` with `<slug>` and continue in the workspace state it reports: created, reused, or working in place after declined consent or sandbox fallback.
+   - If the request requires decomposition, create no workspace for the umbrella request. Start this step separately when brainstorming begins for each sub-project.
+   - Before writing the design document, compare the settled feature name with `<slug>`. If it changed materially, rename the branch with `git branch -m feature/<old-slug> feature/<new-slug>` and move or rename the worktree directory to match; ignore cosmetic or minor wording drift. Surface any unrelated branch collision and do not overwrite it.
+3. **Offer the visual companion just-in-time** — NOT upfront. The first time a question would genuinely be clearer shown than described, offer it then (its own message); on approval its browser tab opens for you. If no visual question ever arises, never offer it. See the Visual Companion section below.
+4. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
+5. **Propose 2-3 approaches** — with trade-offs and your recommendation
+6. **Present design** — in sections scaled to their complexity, get user approval after each section
+<!-- riso-tech:orchestrator-split START -->
+7. **Write design doc** — save to `docs/superpowers/features/<feature-slug>/design.md` following `skills/brainstorming/templates/spec-template.md`, generate `design.html` from `templates/document-companion-template.html`, add the feature to the product roadmap (see Documentation), and commit all
+<!-- riso-tech:orchestrator-split END -->
+8. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
+9. **User reviews written spec** — ask user to review the spec file before proceeding
+10. **Transition to implementation** — invoke `superpowers-orchestrator:writing-plans` to create implementation plan
```

- [ ] **Step 2: Replace the Process Flow DOT diagram**

Before (exact current text):

```diff
-```dot
-digraph brainstorming {
-    "Explore project context" [shape=box];
-    "Ask clarifying questions" [shape=box];
-    "Propose 2-3 approaches" [shape=box];
-    "Present design sections" [shape=box];
-    "User approves design?" [shape=diamond];
-    "Write design doc" [shape=box];
-    "Spec self-review\n(fix inline)" [shape=box];
-    "User reviews spec?" [shape=diamond];
-    "Invoke superpowers-orchestrator:writing-plans" [shape=doublecircle];
-
-    "Explore project context" -> "Ask clarifying questions";
-    "Ask clarifying questions" -> "Propose 2-3 approaches";
-    "Propose 2-3 approaches" -> "Present design sections";
-    "Present design sections" -> "User approves design?";
-    "User approves design?" -> "Present design sections" [label="no, revise"];
-    "User approves design?" -> "Write design doc" [label="yes"];
-    "Write design doc" -> "Spec self-review\n(fix inline)";
-    "Spec self-review\n(fix inline)" -> "User reviews spec?";
-    "User reviews spec?" -> "Write design doc" [label="changes requested"];
-    "User reviews spec?" -> "Invoke superpowers-orchestrator:writing-plans" [label="approved"];
-}
-```
```

After (exact replacement):

```diff
+```dot
+digraph brainstorming {
+    "Explore project context" [shape=box];
+    "One appropriately-sized feature?" [shape=diamond];
+    "Decompose into sub-projects" [shape=box];
+    "Create isolated workspace" [shape=box];
+    "Ask clarifying questions" [shape=box];
+    "Propose 2-3 approaches" [shape=box];
+    "Present design sections" [shape=box];
+    "User approves design?" [shape=diamond];
+    "Feature name changed materially?" [shape=diamond];
+    "Rename branch and worktree" [shape=box];
+    "Write design doc" [shape=box];
+    "Spec self-review\n(fix inline)" [shape=box];
+    "User reviews spec?" [shape=diamond];
+    "Invoke superpowers-orchestrator:writing-plans" [shape=doublecircle];
+
+    "Explore project context" -> "One appropriately-sized feature?";
+    "One appropriately-sized feature?" -> "Create isolated workspace" [label="yes"];
+    "One appropriately-sized feature?" -> "Decompose into sub-projects" [label="no"];
+    "Decompose into sub-projects" -> "Explore project context" [label="begin first sub-project"];
+    "Create isolated workspace" -> "Ask clarifying questions";
+    "Ask clarifying questions" -> "Propose 2-3 approaches";
+    "Propose 2-3 approaches" -> "Present design sections";
+    "Present design sections" -> "User approves design?";
+    "User approves design?" -> "Present design sections" [label="no, revise"];
+    "User approves design?" -> "Feature name changed materially?" [label="yes"];
+    "Feature name changed materially?" -> "Rename branch and worktree" [label="yes"];
+    "Feature name changed materially?" -> "Write design doc" [label="no"];
+    "Rename branch and worktree" -> "Write design doc";
+    "Write design doc" -> "Spec self-review\n(fix inline)";
+    "Spec self-review\n(fix inline)" -> "User reviews spec?";
+    "User reviews spec?" -> "Write design doc" [label="changes requested"];
+    "User reviews spec?" -> "Invoke superpowers-orchestrator:writing-plans" [label="approved"];
+}
+```
```

- [ ] **Step 3: Run pressure testing and record the behavior change**

Run the edited skill through `superpowers-orchestrator:writing-skills`' pressure-testing process and record the before/after behavior difference.

Expected: before the edit, brainstorming reaches clarifying questions without workspace isolation; after the edit, a single scoped feature invokes `using-git-worktrees` with an approximately five-word slug first, a decomposed umbrella creates no workspace, declined consent continues in place, material name drift renames safely, cosmetic drift does not rename, and later workflow skills see existing isolation.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with recorded pressure-test evidence, the orchestrator runs this before generating the task review package:

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat: create worktree during brainstorming"
```

The worker never runs these commands.

**US-1 Checkpoint:**

Run: Through `superpowers-orchestrator:writing-skills`, run separate brainstorming walkthroughs for a single feature with consent granted, consent declined, an umbrella request requiring decomposition, material and cosmetic feature-name drift, and continuation into writing-plans and both execution workflows.

Expected:
- GIVEN a new feature idea and a single appropriately-sized project whose scope check did not require decomposition WHEN brainstorming reaches the new step after project-context exploration THEN `using-git-worktrees` is invoked with a slug auto-slugified from the user's initial request before any clarifying question is asked.
- GIVEN the user declines the worktree consent prompt WHEN brainstorming continues THEN work proceeds in place on the current branch exactly as it does today.
- GIVEN the request describes multiple independent subsystems that require decomposition WHEN brainstorming performs the scope check THEN no branch is created for the umbrella request, and each sub-project creates its own branch only when that sub-project's brainstorming begins.
- GIVEN the feature's real name changes materially during brainstorming before the design document is written WHEN the design is about to be written THEN the branch and worktree directory are renamed to match the new slug, while cosmetic or minor wording drift does not trigger a rename.
- GIVEN the branch and worktree already exist for this session WHEN `writing-plans` or an execution-phase skill runs afterward THEN no duplicate worktree is created because `using-git-worktrees` Step 0 detects the existing isolation and skips creation.

## US-2: Resume an in-progress feature branch in a fresh session

### Task 5: Add fresh-session resume lookup

**Depends on:** Foundation

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md:45-53`
- Test: No automated test file; use `superpowers-orchestrator:writing-skills` pressure testing and record before/after eval evidence.

**Interfaces:**
- Consumes: `<slug>` from brainstorming, `git worktree list`, `git branch --list feature/<slug>*`, branch merge state, and `docs/superpowers/features/<slug>/design.md` presence on a matched branch.
- Produces: one of four explicit outcomes before existing creation logic: reuse the matching feature workspace, treat a merged match as stale and create fresh, ask the user to resolve ambiguity, or proceed with normal creation when no match exists.

**task_type:** implementation_coding

- [ ] **Step 1: Insert resume lookup before existing Step 1 and narrow D12 to unresolved workspaces**

Before (exact current text):

```diff
-Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.
-
-<!-- riso-tech:orchestrator-split START -->
-**Dispatch:** `D12` runs only when Step 0 confirms isolation is needed and the human or standing instructions consent: dispatch worktree creation through `superpowers-orchestrator:dispatch-agent` with `role: devops_engineer` and `task_type: workspace_setup`; require `output.artifacts` to contain the created worktree path, verify it exists, then `cd` exactly once and continue with setup and baseline tests, otherwise treat the response as blocked; create it inline only if the harness has no subagent capability at all.
-<!-- riso-tech:orchestrator-split END -->
-
-## Step 1: Create Isolated Workspace
-
-**You have two mechanisms. Try them in this order.**
```

After (exact replacement):

```diff
+Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.
+
+## Step 0.5: Resume an Existing Feature Workspace
+
+After Step 0 determines that this is a normal checkout and the user consents, if the caller supplied `<slug>`, inspect existing worktrees and matching feature branches before creating anything:
+
+```bash
+git worktree list
+git branch --list "feature/<slug>*"
+```
+
+Classify every match before continuing:
+
+- If a matching branch is already merged into `main`, report it as stale or finished, do not reuse it, and continue to Step 1's fresh-creation path.
+- If exactly one matching branch is unmerged and contains `docs/superpowers/features/<slug>/design.md`, reuse it. If `git worktree list` shows it already attached, enter that worktree. If only the branch remains because its worktree was deleted or pruned, recreate a worktree at that branch: prefer a native worktree tool; otherwise follow Step 1b's directory selection and safety verification, then run `git worktree add "$path" "$MATCHED_BRANCH"` without `-b`.
+- If exactly one matching branch is unmerged but lacks `docs/superpowers/features/<slug>/design.md` or otherwise looks unrelated, report the match and ask the user to choose resume or create-new. Never silently reuse it.
+- If multiple unmerged branches match, report every match and ask the user which one to resume or whether to create new. Never guess.
+- If no branch or worktree matches, continue to Step 1 unchanged.
+
+<!-- riso-tech:orchestrator-split START -->
+**Dispatch:** `D12` runs only when Step 0 confirms isolation is needed, the human or standing instructions consent, and Step 0.5 did not enter an existing worktree: dispatch worktree reuse or creation through `superpowers-orchestrator:dispatch-agent` with `role: devops_engineer` and `task_type: workspace_setup`; require `output.artifacts` to contain the resolved worktree path, verify it exists, then `cd` exactly once and continue with setup and baseline tests, otherwise treat the response as blocked; resolve it inline only if the harness has no subagent capability at all.
+<!-- riso-tech:orchestrator-split END -->
+
+## Step 1: Create Isolated Workspace
+
+**You have two mechanisms. Try them in this order.**
```

- [ ] **Step 2: Run pressure testing and record the behavior change**

Run the edited skill through `superpowers-orchestrator:writing-skills`' pressure-testing process and record the before/after behavior difference.

Expected: before the edit, a fresh main-root session proceeds directly to creation; after the edit, a matching unmerged branch with its design document is reused, a merged match follows fresh creation, an unmerged match without the design document and multiple matches trigger an explicit choice, a pruned worktree is recreated at its existing branch, and no match preserves existing creation behavior.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with recorded pressure-test evidence, the orchestrator runs this before generating the task review package:

```bash
git add skills/using-git-worktrees/SKILL.md
git commit -m "feat: resume brainstorming worktree"
```

The worker never runs these commands.

**US-2 Checkpoint:**

Run: Through `superpowers-orchestrator:writing-skills`, start fresh CLI sessions at the main repository root for an unmerged matching branch with its design document, a merged matching branch, an ambiguous unmerged branch without its design document, and no matching branch or worktree.

Expected:
- GIVEN an unmerged branch `feature/<slug>` already exists from an earlier session and `docs/superpowers/features/<slug>/design.md` is present on that branch WHEN `using-git-worktrees` is invoked again with the same slug THEN it reuses that branch and worktree instead of creating a new one.
- GIVEN a branch matching the slug exists but has already been merged into `main` WHEN `using-git-worktrees` is invoked with that slug THEN it treats the branch as stale or finished and creates a fresh branch instead of reusing it.
- GIVEN a branch matching the slug exists and is unmerged but has no matching `docs/superpowers/features/<slug>/design.md` WHEN `using-git-worktrees` is invoked THEN it reports the ambiguous match and asks the user to confirm resume versus create-new rather than silently reusing it.
- GIVEN no branch or worktree matches the slug WHEN `using-git-worktrees` is invoked THEN it creates a new one exactly as it does today.
