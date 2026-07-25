---
title: Worker Healing Skill
date: 2026-07-25
status: draft
---

# Worker Healing Skill — Design Spec

## 1. Overview

Worker dispatches can fail because a bridge mangles a valid job rather than
because the worker failed its task. `worker-healing` gives the orchestrator a
single routing procedure for those bridge failures across codex and antigravity
without making the orchestrator implement the repair.

## 2. Context & Assumptions

- The orchestrator owns routing and validation, not implementation.
- Bridge code lives in the separate `codex-plugin-cc` repository.
- A Claude subagent remains available after the broken provider is bypassed.
- New orchestrator skills live at `skills/<name>/SKILL.md` and use only `name`
  and `description` frontmatter fields.

## 3. Scope

### Goals

- Identify bridge failures separately from task-logic failures.
- Route a regression-tested bridge repair through `dispatch-agent`.
- Cover codex and antigravity with one file map and one procedure.
- Keep release human-owned.

### Non-Goals

- Editing bridge code, running tests in `codex-plugin-cc`, or releasing it from
  the orchestrator.
- Retrying or repairing genuine task-logic failures.
- Adding runtime self-healing code or a separate skill per bridge.

## 4. User Stories

### US-1: Route a bridge repair (Priority: P1)

As an orchestrator, I want to distinguish a bridge failure from a task-logic
failure and dispatch its repair, so the broken bridge is not blamed on the
worker or repaired inline.

**Acceptance criteria:**

- GIVEN an invalid flag, timeout, or spawn/forward failure WHEN the skill runs
  THEN it classifies it as a bridge bug and excludes task-logic failures.
- GIVEN a bridge bug WHEN routing the repair THEN it uses
  `superpowers-orchestrator:dispatch-agent` with a Claude worker and
  `debugging_root_cause` after bypassing the suspect provider.

### US-2: Cover both bridges (Priority: P1)

As an orchestrator, I want one map for both bridge implementations, so the
same repair contract applies to either provider.

**Acceptance criteria:**

- GIVEN either bridge WHEN locating a repair THEN the skill names its lib
  builder and fake fixture.
- GIVEN a repair worker WHEN dispatched THEN it must reproduce, add a failing
  fixture regression, make the smallest lib-builder fix, and run the suite.

### US-3: Preserve human release control (Priority: P2)

As the human release owner, I want a reminder rather than an automated release,
so versioning, changelog, and push remain under my control.

**Acceptance criteria:**

- GIVEN a validated repair WHEN the procedure ends THEN it names the version
  bump, affected changelog, and GitHub push as human actions only.

## 5. Approach

Add one marker-tagged orchestrator skill with a five-step routing workflow:
recognize, locate, route, validate/ledger, and remind. The fix worker operates
in `codex-plugin-cc`; the orchestrator validates the response under its normal
dispatch protocol.

### Alternatives considered

| Option | Why rejected |
|---|---|
| Repair the bridge inline | Violates the orchestrator's routing-only role and risks using the broken bridge. |
| One skill per bridge | Duplicates an otherwise identical procedure. |
| Automatically release after validation | Removes required human release control. |

## 6. Design

### Architecture

`worker-healing` is a documentation skill in this repository. It invokes the
existing `dispatch-agent` workflow, which selects a Claude repair worker after
the failed provider is bypassed; the worker changes and tests the other repo.

### Components & Interfaces

- `skills/worker-healing/SKILL.md`: trigger description, five routing steps,
  bridge map, and canonical incident example.
- `superpowers-orchestrator:dispatch-agent`: dispatches the Claude worker with
  failure context and `task_type: debugging_root_cause`.
- `codex-plugin-cc` fake fixtures: capture forwarded argv for the worker's
  regression test.

### Data Model & Flow

Failure evidence → classify → locate bridge → dispatch Claude repair worker →
validate response and tests → ledger → human release reminder.

### Error Handling

Task-logic failures return to normal re-scope/re-dispatch. Invalid worker
responses use dispatch-agent's validation and revision flow; the orchestrator
does not substitute an inline fix.

### Edge Cases

A timeout after healthy work begins is a bridge failure, not evidence that the
task failed. A repair for either bridge still uses Claude because the original
bridge is broken or suspect.

## 7. Testing Strategy

Run `bash tests/split/test-marker-scan.sh` from the orchestrator root to verify
the new-file marker and merge-decision entry. Parse the YAML frontmatter and
confirm the file path and required codex/antigravity markers with a local
read-only check.

## 8. Success Criteria

- SC-1: `skills/worker-healing/SKILL.md` has valid two-field frontmatter and a
  new-skill marker.
- SC-2: The skill contains the five routing steps, both bridge paths, both fake
  fixtures, and the 2026-07-25 incident.
- SC-3: The procedure dispatches and validates a repair without inline bridge
  edits or release actions.
