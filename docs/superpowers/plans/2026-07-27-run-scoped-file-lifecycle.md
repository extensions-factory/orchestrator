# Run-scoped File Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development when the harness supports subagents; use superpowers-orchestrator:executing-plans only when the harness has no subagent capability. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** `docs/superpowers/specs/2026-07-27-run-scoped-file-lifecycle-design.md`

**Goal:** Make every workflow artifact traceable from one run-scoped, lifecycle-ordered directory.

**Architecture:** A dependency-free Node resolver owns initialization and path validation. Runtime producers use its run/phase/task/turn paths; durable documents move to project- and feature-scoped locations. Skills, hooks, schemas, and contract tests share the same terminology.

**Tech Stack:** Node.js standard library, POSIX shell, Markdown, JSON Schema, HTML.

## Expected Outcome

### Working behavior

- US-1: maintainers can trace a complete workflow from one run directory.
- US-2: every authored artifact has an explicit template or schema.
- US-3: every active producer and consumer uses the new structure.

### Artifacts

- `scripts/run-paths.mjs` owns validated run paths.
- `assets/*schema.json`, `skills/*/templates/`, and `skills/*/prompts/` define
  artifact and dispatch contracts.
- Dispatch, SDD, brainstorm, hooks, and workflow skills use run-scoped paths.
- `docs/orchestrator-workflow.md` documents the implemented structure.

### How to see it working

- Run `node --test tests/run-paths/run-paths.test.mjs`.
- Run the dispatch-worker, SDD workspace, brainstorm-server, hook, and split
  contract suites; observe all pass.

## Global Constraints

- No third-party dependency.
- Clean break: no dual-write or fallback reads for legacy runtime paths.
- Historical documents remain untouched.
- Raw and ecosystem-native generated artifacts receive no duplicate template.

---

## US-1: Trace a workflow from one directory

### Task 1: Run path resolver

**Depends on:** none

**Files:**
- Create: `tests/run-paths/run-paths.test.mjs`
- Create: `scripts/run-paths.mjs`
- Create: `assets/run-manifest.schema.json`
- Create: `assets/run-index-template.md`

**Interfaces:**
- Consumes: repository root, topic slug, run ID, phase, task, turn, purpose.
- Produces: initialized run roots and validated phase/task/turn paths.

**task_type:** implementation_coding

- [x] Write tests asserting the exact skeleton, semantic turn path, isolation,
  idempotence, and invalid-input rejection.
- [x] Run `node --test tests/run-paths/run-paths.test.mjs`; expect failure
  because `scripts/run-paths.mjs` does not exist.
- [x] Implement the resolver with `node:fs`, `node:path`, and `node:url`.
- [x] Re-run the test; expect all subtests to pass.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add tests/run-paths/run-paths.test.mjs scripts/run-paths.mjs \
  assets/run-manifest.schema.json assets/run-index-template.md
git commit -m "feat: add run-scoped artifact paths"
```

The worker never runs these commands.

**US-1 Checkpoint:**

Run: `node --test tests/run-paths/run-paths.test.mjs`
Expected: initialization, tracing, isolation, idempotence, and rejection tests pass.

## US-2: Know every authored artifact contract

### Task 2: Artifact schemas and templates

**Depends on:** Task 1

**Files:**
- Create: `assets/message-envelope.schema.json`
- Create: `assets/ledger-entry.schema.json`
- Create: `assets/roadmap.schema.json`
- Create: `skills/project-kickoff/templates/discovery-template.md`
- Create: `skills/brainstorming/templates/document-companion-template.html`
- Create: `skills/subagent-driven-development/templates/task-report-template.md`
- Create: `skills/sprint-retrospective/templates/retrospective-template.md`
- Create: `skills/project-kickoff/templates/constitution-template.md`
- Create: `skills/project-kickoff/templates/tool-instruction-template.md`
- Modify: `scripts/validate-message.mjs`
- Modify: `tests/split/test-validate-message.mjs`

**Interfaces:**
- Consumes: approved template audit and message envelopes.
- Produces: explicit authored-artifact contracts and validation of run metadata.

**task_type:** implementation_coding

- [x] Extend the validation test with required `run_id`, `phase`, and `purpose`
  assertions; run it and observe the missing validation fail.
- [x] Add the schemas/templates and update the validator to consume the message
  schema without adding a dependency.
- [x] Re-run `node tests/split/test-validate-message.mjs`; expect PASS.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add assets skills/project-kickoff skills/brainstorming \
  skills/subagent-driven-development skills/sprint-retrospective \
  scripts/validate-message.mjs tests/split/test-validate-message.mjs
git commit -m "feat: define workflow artifact contracts"
```

The worker never runs these commands.

**US-2 Checkpoint:**

Run: `node tests/split/test-validate-message.mjs`
Expected: valid run-aware envelopes pass and missing run metadata fails.

## US-3: Use the new structure throughout the workflow

### Task 3: Runtime producers

**Depends on:** Task 1, Task 2

**Files:**
- Modify: `scripts/dispatch-worker.mjs`
- Modify: `skills/subagent-driven-development/scripts/sdd-workspace`
- Modify: `skills/subagent-driven-development/scripts/task-brief`
- Modify: `skills/subagent-driven-development/scripts/review-package`
- Modify: `skills/brainstorming/scripts/start-server.sh`
- Modify: focused tests under `tests/dispatch-worker/`, `tests/claude-code/`, and
  `tests/brainstorm-server/`.

**Interfaces:**
- Consumes: `SUPERPOWERS_RUN_ID`, semantic phase/task/turn paths.
- Produces: short artifact filenames inside the correct run directory.

**task_type:** implementation_coding

- [x] Change focused tests to require run-scoped destinations and run them to
  observe legacy-path failures.
- [x] Migrate each producer to the resolver contract.
- [x] Re-run all focused suites; expect PASS.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add scripts/dispatch-worker.mjs skills/subagent-driven-development/scripts \
  skills/brainstorming/scripts tests/dispatch-worker tests/claude-code \
  tests/brainstorm-server
git commit -m "feat: write runtime artifacts by lifecycle"
```

The worker never runs these commands.

### Task 4: Workflow consumers and documentation

**Depends on:** Task 3

**Files:**
- Modify: `skills/dispatch-agent/**`
- Modify: `skills/{brainstorming,project-kickoff,writing-plans,requesting-plan-refine,subagent-driven-development,requesting-code-review,finishing-a-development-branch,sprint-retrospective}/**`
- Modify: `hooks/pre-agent-dispatch`
- Modify: `hooks/post-agent-dispatch`
- Modify: `docs/orchestrator-workflow.md`
- Create/modify: focused split and hook contract tests.

**Interfaces:**
- Consumes: run resolver commands and new durable-document locations.
- Produces: one consistent human and agent path contract.

**task_type:** documentation_knowledge_transfer

- [x] Add a contract test that rejects active legacy runtime and durable-document
  paths; run it to observe failure.
- [x] Update skills, references, hooks, and workflow documentation.
- [x] Re-run focused contract tests; expect PASS.

**Orchestrator Git Bookkeeping (not a worker step):**

```bash
git add skills hooks docs/orchestrator-workflow.md tests
git commit -m "docs: adopt run-scoped file lifecycle"
```

The worker never runs these commands.

**US-3 Checkpoint:**

Run: `bash tests/split/run-all.sh`
Expected: all orchestrator split contract tests pass and the path-policy test
finds no active legacy runtime contract.
