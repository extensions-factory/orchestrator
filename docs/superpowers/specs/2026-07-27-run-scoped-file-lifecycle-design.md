---
title: Run-scoped file lifecycle
date: 2026-07-27
status: approved
---

# Run-scoped File Lifecycle — Design Spec

## 1. Overview

The orchestrator currently spreads workflow artifacts across flat
`.superpowers/` subdirectories and date-prefixed documentation folders. A
human cannot start from one path and trace discovery, design, planning,
execution, review, finishing, and retrospective evidence. This change gives
each workflow a stable run directory and a human-readable lifecycle.

## 2. Context & Assumptions

- This is an approved clean break; new workflow code does not dual-write old
  paths.
- Existing historical documents are not moved.
- Durable product documentation remains tracked under `docs/superpowers/`.
- Runtime evidence remains ignored under `.superpowers/runs/`.
- Node.js and POSIX shell are already project requirements; no dependency is
  added.

## 3. Scope

### Goals

- Put all operational artifacts for one workflow under
  `.superpowers/runs/<workflow-id>/`.
- Order lifecycle phases with stable numeric directory prefixes.
- Keep durable project and feature documents in predictable tracked paths.
- Give authored artifacts an explicit template or schema.
- Preserve raw provider output and ecosystem-native scaffold output without
  redundant templates.
- Reject legacy runtime paths after migration.

### Non-Goals

- Moving historical specs and plans already committed to this repository.
- Defining templates for stack-generated source code, Git internals, provider
  raw output, or the external knowledge graph.
- Adding a database, dependency, background service, or compatibility layer.

## 4. User Stories

### US-1: Trace a workflow from one directory (Priority: P1)

As a maintainer, I want one run directory ordered by lifecycle phase, so that I
can inspect a workflow without searching the repository.

**Acceptance criteria:**

- GIVEN a new workflow WHEN its run is initialized THEN
  `.superpowers/runs/<workflow-id>/manifest.json`, `README.md`,
  `ledger.jsonl`, and numbered phase directories exist.
- GIVEN a task dispatch WHEN its turn path is resolved THEN its files live
  under the matching phase, task, and semantic turn directory.
- GIVEN two workflow IDs WHEN they create the same task slug THEN their files
  do not collide.

### US-2: Know the contract for every authored artifact (Priority: P1)

As a contributor, I want each human-authored artifact to name a template or
schema, so that output shape is reviewable and consistent.

**Acceptance criteria:**

- GIVEN the template audit WHEN an authored artifact is produced THEN it maps
  to an existing or newly added template/schema.
- GIVEN a deterministic or externally generated artifact WHEN it is recorded
  THEN it is explicitly marked generated and does not receive a duplicate
  prose template.
- GIVEN a message or ledger entry WHEN validation runs THEN the machine-readable
  contract rejects missing run metadata.

### US-3: Use the new structure throughout the workflow (Priority: P1)

As an orchestrator user, I want every producer and consumer to use the same
path contract, so that documentation and runtime behavior cannot drift.

**Acceptance criteria:**

- GIVEN dispatch, SDD, brainstorm, plan-refine, hooks, or retrospective logic
  WHEN it references workflow artifacts THEN it uses the run-scoped layout.
- GIVEN a new design or plan WHEN it is written THEN it uses the durable
  project/feature path rather than the legacy `specs/` or `plans/` path.
- GIVEN the repository contract suite WHEN it runs THEN no active workflow
  contract requires a legacy runtime path.

## 5. Approach

Add one dependency-free path resolver that validates workflow IDs, phase names,
task slugs, turn numbers, and purposes. It initializes the run skeleton and is
the only executable source of run paths. Existing scripts call it or follow
paths supplied by it; skills and hooks document the same commands.

### Alternatives considered

| Option | Why rejected |
|--------|--------------|
| Put durable and runtime files together | Mixes tracked knowledge with ignored worker evidence. |
| Keep old paths and generate an index | Leaves the fragmented paths authoritative. |
| Support old and new layouts indefinitely | Dual writes and fallback reads create drift and ambiguous recovery. |

## 6. Design

### Architecture

```text
docs/superpowers/
├── project/{discovery.md,scaffold-design.md}
├── features/<feature-slug>/{design.md,design.html,plan.md,plan.html}
├── roadmap.json
└── ROADMAP.html

.superpowers/runs/<workflow-id>/
├── manifest.json
├── README.md
├── ledger.jsonl
├── 10-discovery/
├── 20-design/
├── 30-plan/
├── 40-execution/tasks/
├── 50-finish/
└── 60-retrospective/
```

### Components & Interfaces

- `scripts/run-paths.mjs`: initializes and resolves validated run paths.
- `assets/run-manifest.schema.json`: run metadata contract.
- `assets/message-envelope.schema.json`: dispatch envelope contract including
  `run_id`, `phase`, and `purpose`.
- `assets/ledger-entry.schema.json`: append-only dispatch-pair contract.
- `skills/*/templates/`: output contracts for discovery, document companions,
  task reports, retrospectives, constitutions, and tool instruction pointers.
- `skills/*/prompts/`: reusable worker and reviewer instructions.

### Data Model & Flow

The first artifact-producing phase initializes a workflow ID shaped as
`YYYYMMDDTHHMMSSZ-<topic-slug>`. The ID is reused for every dispatch and helper
call. A turn path is:

```text
<run>/<phase-directory>/<task>/turns/<NNN>-<purpose>/
```

Execution inserts `tasks/` before `<task>`.

The request and response envelope repeat `run_id`, `phase`, and `purpose`.
`manifest.json` is the current lifecycle state and artifact index;
`ledger.jsonl` is the append-only dispatch history.

### Error Handling

- Reject malformed workflow IDs, phase names, task slugs, turn numbers, and
  purposes before creating directories.
- Refuse legacy runtime paths rather than silently falling back.
- Create a run idempotently only when its topic and existing manifest agree.
- Keep provider raw output even when response parsing fails.

### Edge Cases

- Separate workflow IDs isolate identical task slugs.
- Worktrees receive separate run roots because repository roots differ.
- Parallel turns use distinct numeric/purpose directories.
- A missing runtime run ID is a hard, actionable error.

## 7. Testing Strategy

- Unit-test run initialization, path resolution, rejection, isolation, and
  idempotence with Node's standard library.
- Update dispatch-worker tests for semantic turn directories and short
  filenames.
- Update SDD and brainstorm shell tests for run-scoped destinations.
- Add contract scans proving active skills and hooks no longer prescribe
  legacy paths.
- Run the focused suites followed by `tests/split/run-all.sh` and the relevant
  Claude Code, dispatch-worker, brainstorm-server, and hook suites.

## 8. Success Criteria

- SC-1: One run root contains the complete operational lifecycle.
- SC-2: Every authored artifact in the audit maps to a template or schema.
- SC-3: Runtime path creation has one executable source of truth.
- SC-4: Focused and aggregate contract suites pass with no legacy runtime path
  requirements.
