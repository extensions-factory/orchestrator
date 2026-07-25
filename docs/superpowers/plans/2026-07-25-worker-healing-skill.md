# Worker Healing Skill Implementation Plan

<!-- riso-tech:orchestrator-split START -->
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development when the harness supports subagents; use superpowers-orchestrator:executing-plans only when the harness has no subagent capability. Steps use checkbox (`- [ ]`) syntax for tracking.
<!-- riso-tech:orchestrator-split END -->

**Spec:** `docs/superpowers/specs/2026-07-25-worker-healing-skill-design.md`

**Goal:** Add an orchestrator skill that routes, validates, and records bridge repairs without implementing or releasing them.

**Architecture:** One new `SKILL.md` provides the routing contract and bridge map. It reuses `dispatch-agent` to send a Claude `debugging_root_cause` worker to the separate bridge repository, then uses the ordinary response-validation and ledger path.

**Tech Stack:** Markdown with YAML frontmatter; existing bash marker scan.

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- US-1: the orchestrator recognizes bridge failures and dispatches a Claude repair worker rather than editing inline.
- US-2: codex and antigravity use the same procedure with their respective lib builders and fixtures.
- US-3: a completed repair is validated and recorded; release remains a human reminder.

### Artifacts

- `skills/worker-healing/SKILL.md` — the auto-triggering routing skill.
- `docs/superpowers/specs/2026-07-25-worker-healing-skill-design.md` — the design record.
- `docs/superpowers/plans/2026-07-25-worker-healing-skill.md` — this implementation plan.
- `../docs/superpowers/MERGE-DECISIONS.md` — new-file merge rule entry.

### How to see it working

- Run `bash tests/split/test-marker-scan.sh`; it prints `PASS`. Parse the new
  skill frontmatter and check its location and bridge-map markers.

## Global Constraints

- Only the skill, this spec and plan, and the merge-decision new-file list change.
- The orchestrator routes and validates; a Claude worker repairs the separate
  `codex-plugin-cc` repository with reproduction, failing fixture regression,
  smallest fix, and suite verification.
- No commit, push, dependency installation, sync script, version bump, or release action.

---

## US-1: Route a bridge repair

### Task 1: Write the orchestration workflow

**Depends on:** none

**Files:**
- Create: `skills/worker-healing/SKILL.md`

**Interfaces:**
- Consumes: worker-dispatch failure evidence and `superpowers-orchestrator:dispatch-agent`.
- Produces: a five-step procedure that classifies, locates, dispatches,
  validates/ledgers, and reminds.

- [ ] **Step 1: Write the skill.** Add two-field YAML frontmatter, the exact
  new-skill marker, and the five-step SM workflow.
- [ ] **Step 2: Make the routing explicit.** Require a Claude subagent with
  `task_type: debugging_root_cause` after the broken provider is bypassed;
  require reproduce → failing fixture regression → smallest lib fix → suite.
- [ ] **Step 3: Verify the artifact.** Parse the frontmatter and confirm the
  path, numbered steps, dispatch-agent reference, and no inline-fix instruction.

**US-1 Checkpoint:**

Run a frontmatter/content check. Expected: bridge failures route through
`dispatch-agent`; task-logic failures re-scope or re-dispatch.

## US-2: Cover both bridges

### Task 2: Add the shared bridge map and example

**Depends on:** Task 1

**Files:**
- Modify: `skills/worker-healing/SKILL.md`

**Interfaces:**
- Consumes: shared workflow from Task 1.
- Produces: codex and antigravity lib-builder/fixture mappings.

- [ ] **Step 1: Add both mappings.** Name the two lib builders and the two
  fake fixtures in one table.
- [ ] **Step 2: Add the canonical incident.** Record the parenthesized-model
  `--effort` guard, 5m→15m timeout, regression-test location, and v3.0.2.
- [ ] **Step 3: Verify the markers.** Confirm all four paths and the example
  appear in the skill.

**US-2 Checkpoint:**

Read the bridge map. Expected: either bridge has one shared worker contract and
its correct lib builder plus fixture.

## US-3: Preserve human release control

### Task 3: Record merge treatment and validate

**Depends on:** Task 1

**Files:**
- Modify: `../docs/superpowers/MERGE-DECISIONS.md`
- Modify: `skills/worker-healing/SKILL.md`

**Interfaces:**
- Consumes: the existing New file merge-decision row.
- Produces: `worker-healing/` as a no-upstream-counterpart file and a
  remind-only release step.

- [ ] **Step 1: Add `worker-healing/` to the New file row.** Preserve the
  existing merge rule.
- [ ] **Step 2: Add the release reminder.** Name `node scripts/bump-version.mjs
  <version>`, the affected plugin changelog, and GitHub push as human actions;
  explicitly prohibit the orchestrator from running them.
- [ ] **Step 3: Run the marker scan.** Run `bash tests/split/test-marker-scan.sh`.

**US-3 Checkpoint:**

Expected: marker scan prints `PASS`; the skill reminds but never directs the
orchestrator to release.
