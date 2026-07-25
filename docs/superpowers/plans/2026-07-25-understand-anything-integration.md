# Understand-Anything Knowledge Graph Integration Implementation Plan

<!-- riso-tech:orchestrator-split START -->
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development when the harness supports subagents; use superpowers-orchestrator:executing-plans only when the harness has no subagent capability. Steps use checkbox (`- [ ]`) syntax for tracking.
<!-- riso-tech:orchestrator-split END -->

**Spec:** `docs/superpowers/specs/2026-07-25-understand-anything-integration-design.md`

**Goal:** Seed brainstorming from a fresh understand-anything graph and offer a human-gated post-land graph refresh while keeping collection inline, read-only, best-effort, and optional.

**Architecture:** Add one bounded instruction block to the existing brainstorming checklist and one post-D19 orchestration block to the branch-finishing skill. Both blocks read the existing graph schema without changing it; only the confirmed refresh creates a new dispatch, while the workflow document records the new inline and dispatch nodes.

**Tech Stack:** Markdown skills and workflow documentation, Bash contract tests using repository-local `grep`, `sed`, and `awk`, Git for scoped freshness checks, and the existing `superpowers-orchestrator:dispatch-agent` protocol.

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- US-1: orchestrators use matching node names, summaries, and edge targets from a fresh graph as brainstorming seed context, then continue normal file exploration; missing, stale, malformed, or empty graph results degrade silently without dispatch.
- US-2: merge and PR finish paths freshness-check the landed graph and, only when stale, ask the human before dispatching `/understand`; keep and discard paths never show the gate.
- US-3: readers see the inline collect action and conditional refresh dispatch in the lifecycle tree without any legend-semantic changes.

### Artifacts

- `skills/brainstorming/SKILL.md` — inline, best-effort graph context collection instructions.
- `skills/finishing-a-development-branch/SKILL.md` — post-D19 freshness gate, confirmed D20 refresh dispatch, validation, and ledger handling.
- `skills/sprint-retrospective/SKILL.md` — dispatch ID renumbered from D20 to D21.
- `skills/writing-skills/SKILL.md` — dispatch ID renumbered from D21 to D22.
- `skills/backlog-refinement/SKILL.md` — dispatch ID renumbered from D22 to D23.
- `docs/orchestrator-workflow.md` — lifecycle tree annotations and downstream dispatch renumbering.
- `tests/split/test-brainstorming-graph-context.sh` — static contract coverage for the collect instructions.
- `tests/split/test-finishing-graph-refresh.sh` — static contract coverage for the post-land gate and dispatch.
- `tests/split/test-workflow-graph-integration.sh` — static contract coverage for diagram placement and legend preservation.
- `tests/split/test-dispatch-completeness.sh` — updated to pin D21–D23 for retrospective/writing/backlog dispatches and add D20 assertion for the finishing-branch refresh.

### How to see it working

- Run `bash tests/split/test-brainstorming-graph-context.sh && bash tests/split/test-finishing-graph-refresh.sh && bash tests/split/test-workflow-graph-integration.sh`; expected output ends with `PASS test-brainstorming-graph-context`, `PASS test-finishing-graph-refresh`, and `PASS test-workflow-graph-integration`.
- In a checkout whose graph hash matches `git log -1 --format=%H -- .`, start brainstorming for a graph keyword; expected behavior is graph-derived seed context before ordinary file exploration and no worker dispatch.
- Finish a merge or PR with a stale graph, answer `yes` to `Knowledge graph is stale. Refresh it now? (yes/no)`, and observe a `technical_writer` / `documentation_knowledge_transfer` dispatch followed by a graph hash matching the new scoped HEAD and a ledger entry.

### Risks

- Static contract tests prove the behavior-shaping text and ordering, not model compliance; the per-US checkpoints retain manual end-to-end scenarios.
- Renumbering the later workflow dispatches is easy to miss; Task 3 asserts one D20 refresh node and the D21–D23 successors.
- A missing plugin or malformed graph must not interrupt core workflows; both skill blocks explicitly skip or fall back without retry.
- Large graphs can be expensive to read wholesale; US-1 keeps the read keyword-scoped through `grep_search`.

## Global Constraints

- `understand-anything` is installed on all providers including Codex; no provider pin is needed for the refresh worker.
- "Fresh" means the graph's `project.gitCommitHash` equals the HEAD commit of the working directory as scoped with `-- .` (i.e., git log restricted to the project root to handle monorepos).
- Freshness is checked by comparing `project.gitCommitHash` to the output of `git log -1 --format=%H -- .`.
- Legacy path (`.understand-anything/knowledge-graph.json`) is only considered when the `.understand-anything/` directory exists in the checkout; `.ua/` is always checked first.
- The collect step (Piece 1) is best-effort — it must never block brainstorming or add a dispatch point.
- The refresh step (Piece 2) fires only on merge/PR-finish paths — keep and discard paths skip it.
- The human gate on refresh is mandatory; the orchestrator must not auto-refresh without confirmation.

**Out of scope (do not implement):**
- Auto-refreshing the graph without a human gate — we do not want silent background rebuilds.
- Modifying how `understand-anything` itself builds the graph — this spec only describes how the orchestrator interacts with what the plugin already produces.
- Supporting graph formats other than the `.ua/knowledge-graph.json` schema the plugin writes today.
- Changing the brainstorming skill's overall structure, Red Flags table, or rationalization-prevention content.

---

## US-1: Graph-aware brainstorming context

### Task 1: Add inline graph collection to brainstorming

**Depends on:** none

**Files:**
- Create: `tests/split/test-brainstorming-graph-context.sh`
- Modify: `skills/brainstorming/SKILL.md:24-25`
- Test: `tests/split/test-brainstorming-graph-context.sh`

**Interfaces:**
- Consumes: feature keywords from the active brainstorming topic; `.ua/knowledge-graph.json`; conditional legacy `.understand-anything/knowledge-graph.json`; graph field `project.gitCommitHash`; scoped HEAD from `git log -1 --format=%H -- .`; existing `grep_search` and normal file-exploration tools.
- Produces: best-effort seed context containing matching graph node names, summaries, and edge targets; one-line missing/stale fallback notes; no new request envelope, worker, or graph write.

**task_type:** implementation_coding

- [ ] **Step 1: Write the failing contract test**

Create `tests/split/test-brainstorming-graph-context.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/brainstorming/SKILL.md"
SECTION="$(sed -n '/^1\. \*\*Explore project context\*\*/,/^2\. \*\*Offer the visual companion/p' "$SKILL")"
fail=0

check() {
  local needle="$1"
  local label="$2"
  if grep -Fq -- "$needle" <<< "$SECTION"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

check 'collect graph context inline and best-effort' 'brainstorming collect is inline and best-effort'
check '`.ua/knowledge-graph.json`' 'canonical graph path is checked first'
check '`.understand-anything/knowledge-graph.json` only when `.understand-anything/` exists' 'legacy graph path is conditional'
check '`project.gitCommitHash` with `git log -1 --format=%H -- .`' 'freshness uses the project-scoped HEAD'
check '`grep_search` the graph for the feature keywords' 'fresh graph is searched by feature keywords'
check 'node names, summaries, and edge targets' 'graph matches seed the required context fields'
check 'Knowledge graph missing or stale; continuing with file exploration.' 'missing or stale graph has a one-line fallback'
check 'malformed, `git log` fails, or the hashes differ' 'invalid freshness inputs fall back'
check 'no matches, continue normal file exploration without error' 'empty graph search is non-fatal'
check 'Never call `/understand`, dispatch a worker, write the graph, or block normal file exploration from this collect step.' 'collect cannot build, dispatch, write, or block'

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "PASS test-brainstorming-graph-context"
```

- [ ] **Step 2: Run the contract test to verify it fails**

Run: `bash tests/split/test-brainstorming-graph-context.sh`

Expected: FAIL with `[FAIL] brainstorming collect is inline and best-effort` and exit status 1.

- [ ] **Step 3: Add the minimal inline collection instructions**

In `skills/brainstorming/SKILL.md`, replace checklist item 1 with this exact block, leaving item 2 and every later section unchanged:

```markdown
1. **Explore project context** — check files, docs, recent commits, then collect graph context inline and best-effort before normal file exploration:
   - Resolve the graph path read-only: use `.ua/knowledge-graph.json` when present; otherwise use `.understand-anything/knowledge-graph.json` only when `.understand-anything/` exists. If neither graph exists, note `Knowledge graph missing or stale; continuing with file exploration.` and continue.
   - Compare `project.gitCommitHash` with `git log -1 --format=%H -- .`. If the graph is malformed, `git log` fails, or the hashes differ, note `Knowledge graph missing or stale; continuing with file exploration.` and continue.
   - When the graph is fresh, `grep_search` the graph for the feature keywords and seed context from matching node names, summaries, and edge targets. If there are no matches, continue normal file exploration without error.
   - Never call `/understand`, dispatch a worker, write the graph, or block normal file exploration from this collect step.
```

- [ ] **Step 4: Run the focused and aggregate contract tests**

Run: `bash tests/split/test-brainstorming-graph-context.sh && bash tests/split/run-all.sh`

Expected: the focused test prints `PASS test-brainstorming-graph-context`, the aggregate suite prints `ALL ORCHESTRATOR SPLIT TESTS PASS`, and both commands exit 0.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/split/test-brainstorming-graph-context.sh skills/brainstorming/SKILL.md
git commit -m "feat: seed brainstorming from fresh graph"
```

The worker never runs these commands.

**US-1 Checkpoint:**

- Action: Set `.ua/knowledge-graph.json` so `project.gitCommitHash` equals `git log -1 --format=%H -- .`, include the active feature keyword in a node name or summary and a connected edge, then start `superpowers-orchestrator:brainstorming`. Expected: before ordinary file exploration, session context surfaces the matching node name, summary, and edge target.
- Action: Repeat with no graph, then with a graph whose hash differs from `git log -1 --format=%H -- .`. Expected: each run emits exactly one `Knowledge graph missing or stale; continuing with file exploration.` note, continues normal file exploration, and creates no worker request.
- Action: Use a fresh graph with no matching feature keyword. Expected: brainstorming continues normal file exploration without an error.
- Action: Inspect `.superpowers/ledger.jsonl` and `.superpowers/*/turn-*-request.json` timestamps after all collect scenarios. Expected: no collect-triggered dispatch or worker launch appears.

## US-2: Post-land knowledge graph refresh gate

### Task 2: Add the post-D19 refresh gate and dispatch

**Depends on:** none

**Files:**
- Create: `tests/split/test-finishing-graph-refresh.sh`
- Modify: `skills/finishing-a-development-branch/SKILL.md:96-99`
- Test: `tests/split/test-finishing-graph-refresh.sh`

**Interfaces:**
- Consumes: D19 response status and named finish action (`merge`, `pr`, `keep`, or `discard`); canonical or conditional legacy graph; `project.gitCommitHash`; scoped HEAD; explicit human `yes` or `no`; `superpowers-orchestrator:dispatch-agent`.
- Produces: conditional D20 request with `role: technical_writer`, `task_type: documentation_knowledge_transfer`, no provider pin, and `/understand` as the checkout command; post-worker hash validation; one project-ledger result; no gate or freshness check on keep/discard.

**task_type:** implementation_coding

- [ ] **Step 1: Write the failing contract test**

Create `tests/split/test-finishing-graph-refresh.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/finishing-a-development-branch/SKILL.md"
SECTION="$(sed -n '/^### Step 4b: Post-Land Knowledge Graph Refresh/,/^### Step 5: Execute Choice/p' "$SKILL")"
fail=0

check() {
  local needle="$1"
  local label="$2"
  if grep -Fq -- "$needle" <<< "$SECTION"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

check 'After D19 returns `done` for `merge` or `pr`' 'refresh starts only after a landed finish path'
check 'For `keep` or `discard`, skip this entire step' 'keep and discard skip freshness and gate'
check 'use `.ua/knowledge-graph.json` first' 'canonical graph path has precedence'
check 'legacy path only when `.understand-anything/` exists' 'legacy graph path is conditional'
check 'compare `project.gitCommitHash` with `git log -1 --format=%H -- .`' 'post-land freshness uses scoped HEAD'
check 'If the graph is absent or malformed, skip the gate' 'absent or malformed graph degrades silently'
check 'If the graph is already fresh, continue without a gate' 'fresh graph avoids unnecessary work'
check 'Knowledge graph is stale. Refresh it now? (yes/no)' 'stale graph presents the exact human gate'
check 'On `no`, skip the refresh and continue without error.' 'declined refresh is non-fatal'
check 'On `yes`, proceed to the D20 dispatch.' 'confirmed refresh proceeds to dispatch block'
check '**Dispatch:** `D20`' 'D20 dispatch block is present'
check 'riso-tech:orchestrator-split START' 'D20 dispatch block is fenced with orchestrator-split markers'
check '`role: technical_writer`' 'refresh worker role is technical_writer'
check '`task_type: documentation_knowledge_transfer`' 'refresh task type is documentation knowledge transfer'
check 'no provider pin' 'standard model ranking remains active'
check 'run `/understand` in the checkout' 'worker rebuild command is explicit'
check 'validate the worker response' 'worker envelope is validated'
check 'matches the current scoped HEAD' 'rebuilt graph is checked against landed HEAD'
check 'append one result to the project ledger' 'refresh outcome is recorded'
check 'Do not retry automatically' 'refresh failures are surfaced without retry'

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "PASS test-finishing-graph-refresh"
```

- [ ] **Step 2: Run the contract test to verify it fails**

Run: `bash tests/split/test-finishing-graph-refresh.sh`

Expected: FAIL with `[FAIL] refresh starts only after a landed finish path` and exit status 1.

- [ ] **Step 3: Add the minimal post-land orchestration block**

In `skills/finishing-a-development-branch/SKILL.md`, insert this exact block after the D19 dispatch marker and before `### Step 5: Execute Choice`:

```markdown
### Step 4b: Post-Land Knowledge Graph Refresh

After D19 returns `done` for `merge` or `pr`, run this orchestrator-owned step against the landed checkout. For `keep` or `discard`, skip this entire step: do not freshness-check the graph and do not present a gate.

1. Resolve the graph read-only: use `.ua/knowledge-graph.json` first; use the legacy path only when `.understand-anything/` exists. If the graph is absent or malformed, skip the gate and continue without error.
2. Freshness-check the landed graph: compare `project.gitCommitHash` with `git log -1 --format=%H -- .`. If the graph is already fresh, continue without a gate. If `git log` fails, record the one-line failure and continue without dispatch.
3. If the graph is stale, ask exactly: `Knowledge graph is stale. Refresh it now? (yes/no)`.
   - On `no`, skip the refresh and continue without error.
   - On `yes`, proceed to the D20 dispatch.
<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D20` routes through `superpowers-orchestrator:dispatch-agent` with `role: technical_writer`, `task_type: documentation_knowledge_transfer`, no provider pin, and a request to run `/understand` in the checkout; only reached after a merge or PR finish path and an explicit human `yes` at the freshness gate.
<!-- riso-tech:orchestrator-split END -->
4. When the worker returns, validate the worker response, then verify that the rebuilt graph's `project.gitCommitHash` matches the current scoped HEAD from `git log -1 --format=%H -- .`; append one result to the project ledger.
5. If the worker returns `blocked` or `needs_revision`, or the rebuilt hash is still stale, append that result to the ledger and surface it to the human. Do not retry automatically.
```

- [ ] **Step 4: Run the focused and aggregate contract tests**

Run: `bash tests/split/test-finishing-graph-refresh.sh && bash tests/split/run-all.sh`

Expected: the focused test prints `PASS test-finishing-graph-refresh`, the aggregate suite prints `ALL ORCHESTRATOR SPLIT TESTS PASS`, and both commands exit 0.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/split/test-finishing-graph-refresh.sh skills/finishing-a-development-branch/SKILL.md
git commit -m "feat: gate post-land graph refresh"
```

The worker never runs these commands.

**US-2 Checkpoint:**

- Action: Complete D19 through `merge`, then through `pr`, with a stale graph. Expected: each landed path compares the graph hash to the new `git log -1 --format=%H -- .` before showing `Knowledge graph is stale. Refresh it now? (yes/no)`.
- Action: At the stale-graph gate, answer `yes`. Expected: D20 dispatches exactly one worker with `role: technical_writer`, `task_type: documentation_knowledge_transfer`, no provider pin, and `/understand` in the checkout.
- Action: Let the confirmed worker return `done`. Expected: response validation succeeds, the rebuilt `project.gitCommitHash` equals the current scoped HEAD, and the project ledger contains the refresh result.
- Action: At the stale-graph gate, answer `no`. Expected: no D20 request is created and finishing continues without error.
- Action: Complete D19 through `keep`, then through confirmed `discard`. Expected: neither path reads graph freshness nor presents the refresh gate.
- Action: Inspect the D20 request envelope after a confirmed refresh. Expected: it contains no provider/model override, so dispatch-agent uses standard model-lookup ranking.
- Action: Return `blocked`, `needs_revision`, or a still-stale graph from the refresh worker. Expected: one failure or mismatch is appended to the ledger, surfaced to the human, and not retried automatically.

## US-3: Workflow diagram updated

### Task 3: Document both graph integration points

**Depends on:** Task 1 and Task 2

**Files:**
- Create: `tests/split/test-workflow-graph-integration.sh`
- Modify: `docs/orchestrator-workflow.md:43-46`
- Modify: `docs/orchestrator-workflow.md:108-136`
- Modify: `skills/sprint-retrospective/SKILL.md:16` (`D20` → `D21` in dispatch line)
- Modify: `skills/writing-skills/SKILL.md:19` (`D21` → `D22` in dispatch line)
- Modify: `skills/backlog-refinement/SKILL.md:16` (`D22` → `D23` in dispatch line)
- Modify: `tests/split/test-dispatch-completeness.sh:103-108` (update pinned IDs and add D20 assertion)
- Test: `tests/split/test-workflow-graph-integration.sh`

**Interfaces:**
- Consumes: Task 1's inline collect semantics; Task 2's post-D19 D20 gate and dispatch semantics; existing lifecycle-tree legend.
- Produces: one `○` graph-collect note at brainstorming context inspection; one conditional `◆ D20` refresh dispatch after D19; unique downstream dispatch IDs D21–D23; unchanged meanings for `○`, `◆ Dn`, `◇`, and `↻`.

**task_type:** documentation_knowledge_transfer

- [ ] **Step 1: Write the failing diagram contract test**

Create `tests/split/test-workflow-graph-integration.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKFLOW="$ROOT/docs/orchestrator-workflow.md"
SR="$ROOT/skills/sprint-retrospective/SKILL.md"
WS="$ROOT/skills/writing-skills/SKILL.md"
BR="$ROOT/skills/backlog-refinement/SKILL.md"
TC="$ROOT/tests/split/test-dispatch-completeness.sh"
fail=0

check() {
  local needle="$1"
  local label="$2"
  if grep -Fq -- "$needle" "$WORKFLOW"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

check_file() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if grep -Fq -- "$needle" "$file"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

before() {
  local first second
  first="$(awk -v needle="$1" 'index($0, needle) { print NR; exit }' "$WORKFLOW")"
  second="$(awk -v needle="$2" 'index($0, needle) { print NR; exit }' "$WORKFLOW")"
  if [[ -n "$first" && -n "$second" && "$first" -lt "$second" ]]; then
    echo "[PASS] $3"
  else
    echo "[FAIL] $3"
    fail=1
  fi
}

check '- `◆ Dn` — dispatch point; always routes through `superpowers-orchestrator:dispatch-agent`' 'dispatch legend is unchanged'
check '- `○` — orchestrator action performed inline' 'inline legend is unchanged'
check '- `◇` — human approval gate' 'human-gate legend is unchanged'
check '- `↻` — loop back to an earlier step' 'loop legend is unchanged'
check '○ collect fresh graph matches inline; missing, stale, malformed, or no matches → normal file exploration' 'brainstorming shows the inline collect note'
check '◆ D20 refresh knowledge graph [conditional]' 'phase E shows the conditional refresh dispatch'
check 'role: technical_writer' 'workflow shows the refresh role'
check 'task_type: documentation_knowledge_transfer' 'workflow shows the refresh task type'
check '◆ D21 process review' 'retrospective dispatch is renumbered'
check '◆ D22 edit skill' 'skill-edit dispatch is renumbered'
check '◆ D23 propose ordering and grooming' 'backlog dispatch is renumbered'
before '◆ D19 execute the selected finish path' '◆ D20 refresh knowledge graph [conditional]' 'refresh dispatch appears after D19'

d20_count="$(grep -Fc -- '◆ D20 ' "$WORKFLOW")"
if [[ "$d20_count" -eq 1 ]]; then
  echo "[PASS] D20 is unique"
else
  echo "[FAIL] D20 is unique"
  fail=1
fi

# B1: skill files carry their new dispatch IDs
check_file "$SR" '**Dispatch:** `D21`' 'sprint-retrospective carries D21'
check_file "$WS" '**Dispatch:** `D22`' 'writing-skills carries D22'
check_file "$BR" '**Dispatch:** `D23`' 'backlog-refinement carries D23'

# B2: test-dispatch-completeness.sh pins the updated IDs and adds D20 assertion
check_file "$TC" 'check_dispatch "$SR" D21' 'dispatch-completeness updated SR to D21'
check_file "$TC" 'check_dispatch "$WS" D22' 'dispatch-completeness updated WS to D22'
check_file "$TC" 'check_dispatch "$BR" D23' 'dispatch-completeness updated BR to D23'
check_file "$TC" 'check_dispatch "$FB" D20' 'dispatch-completeness has new D20 for finishing-branch'

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "PASS test-workflow-graph-integration"
```

- [ ] **Step 2: Run the diagram test to verify it fails**

Run: `bash tests/split/test-workflow-graph-integration.sh`

Expected: FAIL with `[FAIL] brainstorming shows the inline collect note` and exit status 1.

- [ ] **Step 3: Add the brainstorming inline note**

In `docs/orchestrator-workflow.md`, replace the existing `inspect project context` line with:

```text
│       ├── ○ inspect project context
│       │      ○ collect fresh graph matches inline; missing, stale, malformed, or no matches → normal file exploration
```

- [ ] **Step 4: Add D20 and renumber later dispatches**

In `docs/orchestrator-workflow.md`, replace the lifecycle tree from `├── E. Finish Branch` through the end of `G. Backlog Refinement` with:

```text
├── E. Finish Branch
│   ├── ○ verify test results
│   ├── ◇ choose merge, PR, keep, or discard
│   ├── ◆ D19 execute the selected finish path
│   │      role: devops_engineer
│   │      task_type: release_deployment
│   │      ├── Git mechanics
│   │      ├── PR body and gh pr create
│   │      ├── roadmap release update
│   │      └── worktree cleanup
│   ├── merge or PR finished?
│   │   ├── no (keep/discard) → continue
│   │   └── yes → ○ freshness-check knowledge graph
│   │       ├── fresh, missing, or malformed → continue
│   │       └── stale → ◇ refresh graph?
│   │           ├── no → continue
│   │           └── yes → ◆ D20 refresh knowledge graph [conditional]
│   │                  role: technical_writer
│   │                  task_type: documentation_knowledge_transfer
│   └── continue
│
├── F. Sprint Retrospective
│   ├── ○ calculate metrics from ledger.jsonl
│   ├── ◆ D21 process review
│   │      role: agile_coach
│   │      task_type: retrospective_process_improvement
│   ├── ◇ approve process improvements
│   └── approved skill improvement?
│       └── ◆ D22 edit skill
│              role: software_engineer
│              task_type: implementation_coding
│
└── G. Backlog Refinement
    ├── ○ read roadmap
    ├── ◆ D23 propose ordering and grooming
    │      role: product_owner
    │      task_type: backlog_refinement_prioritization
    ├── ◇ approve proposal
    └── ○ apply approved roadmap changes
```

- [ ] **Step 5: Renumber skill-file dispatch IDs**

In each skill file, replace only the dispatch-line `D` number inside the `<!-- riso-tech:orchestrator-split START/END -->` block. Show exact before → after for each file:

`skills/sprint-retrospective/SKILL.md` line 16:
- Before: `**Dispatch:** \`D20\` sends the process review through \`superpowers-orchestrator:dispatch-agent\` with \`role: agile_coach\` and \`task_type: retrospective_process_improvement\`...`
- After:  `**Dispatch:** \`D21\` sends the process review through \`superpowers-orchestrator:dispatch-agent\` with \`role: agile_coach\` and \`task_type: retrospective_process_improvement\`...`

`skills/writing-skills/SKILL.md` line 19:
- Before: `**Dispatch:** \`D21\` runs only for a human-approved skill improvement handed off from the retrospective: through \`superpowers-orchestrator:writing-skills\`...`
- After:  `**Dispatch:** \`D22\` runs only for a human-approved skill improvement handed off from the retrospective: through \`superpowers-orchestrator:writing-skills\`...`

`skills/backlog-refinement/SKILL.md` line 16:
- Before: `**Dispatch:** \`D22\` sends the current roadmap and only work the human explicitly adds through \`superpowers-orchestrator:dispatch-agent\` with \`role: product_owner\`...`
- After:  `**Dispatch:** \`D23\` sends the current roadmap and only work the human explicitly adds through \`superpowers-orchestrator:dispatch-agent\` with \`role: product_owner\`...`

- [ ] **Step 6: Update test-dispatch-completeness.sh**

In `tests/split/test-dispatch-completeness.sh`, apply these exact replacements to lines 103–108, keeping each call's existing phrase arguments unchanged:

```diff
-check_dispatch "$SR" D20 "role: agile_coach" "task_type: retrospective_process_improvement" "process review"
+check_dispatch "$SR" D21 "role: agile_coach" "task_type: retrospective_process_improvement" "process review"
-check_dispatch "$WS" D21 "role: software_engineer" "task_type: implementation_coding" "human-approved skill improvement" "writing-skills"
+check_dispatch "$WS" D22 "role: software_engineer" "task_type: implementation_coding" "human-approved skill improvement" "writing-skills"
-check_dispatch "$BR" D22 "role: product_owner" "task_type: backlog_refinement_prioritization" "propose ordering and grooming" "human approves"
+check_dispatch "$BR" D23 "role: product_owner" "task_type: backlog_refinement_prioritization" "propose ordering and grooming" "human approves"
```

And insert this new line immediately after the updated D23 call (add the new D20 assertion for the finishing-branch refresh dispatch):

```bash
check_dispatch "$FB" D20 "role: technical_writer" "task_type: documentation_knowledge_transfer" "no provider pin" "/understand"
```

- [ ] **Step 7: Run the focused and aggregate contract tests**

Run: `bash tests/split/test-workflow-graph-integration.sh && bash tests/split/run-all.sh`

Expected: the focused test prints `PASS test-workflow-graph-integration`, the aggregate suite prints `ALL ORCHESTRATOR SPLIT TESTS PASS`, and both commands exit 0.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/split/test-workflow-graph-integration.sh docs/orchestrator-workflow.md \
  skills/sprint-retrospective/SKILL.md skills/writing-skills/SKILL.md \
  skills/backlog-refinement/SKILL.md tests/split/test-dispatch-completeness.sh
git commit -m "docs: show knowledge graph integration"
```

The worker never runs these commands.

**US-3 Checkpoint:**

- Run: `bash tests/split/test-workflow-graph-integration.sh`. Expected: `PASS test-workflow-graph-integration`, including a unique `◆ D20 refresh knowledge graph [conditional]` after D19 in phase E.
- Action: Open `docs/orchestrator-workflow.md` and inspect the brainstorming subtree. Expected: an `○ collect fresh graph matches inline` note appears directly under `○ inspect project context`.
- Action: Compare the four legend lines before and after the implementation. Expected: `○` still means inline orchestrator action, `◆ Dn` still means dispatch through dispatch-agent, `◇` still means human approval gate, and `↻` still means loop.
