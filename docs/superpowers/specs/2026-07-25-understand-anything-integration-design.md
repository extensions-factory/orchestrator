---
title: Understand-Anything Knowledge Graph Integration
date: 2026-07-25
status: draft
---

# Understand-Anything Knowledge Graph Integration — Design Spec

## 1. Overview

The Superpowers orchestrator currently approaches brainstorming by exploring the codebase with file searches alone and finishes branches without updating any project intelligence layer. This spec adds two lightweight integration points with the `understand-anything` plugin's knowledge graph: (1) the brainstorming skill reads a fresh graph to seed design context without requiring a build, and (2) the finishing skill gates and dispatches a graph refresh after code lands. The intended users are orchestrators running Superpowers with the `understand-anything` plugin installed; the outcome is richer brainstorming context and an always-current graph after each integration.

## 2. Context & Assumptions

The `understand-anything` plugin writes a knowledge graph to `.ua/knowledge-graph.json` (canonical) or `.understand-anything/knowledge-graph.json` (legacy, present only when the legacy directory exists). The graph's `project.gitCommitHash` field records the commit at which it was last built. The plugin's `/understand` slash command rebuilds the graph; it is computationally expensive and must never run inline in the orchestrator.

**Assumptions:**

- `understand-anything` is installed on all providers including Codex; no provider pin is needed for the refresh worker.
- "Fresh" means the graph's `project.gitCommitHash` equals the HEAD commit of the working directory as scoped with `-- .` (i.e., git log restricted to the project root to handle monorepos).
- Freshness is checked by comparing `project.gitCommitHash` to the output of `git log -1 --format=%H -- .`.
- Legacy path (`.understand-anything/knowledge-graph.json`) is only considered when the `.understand-anything/` directory exists in the checkout; `.ua/` is always checked first.
- The collect step (Piece 1) is best-effort — it must never block brainstorming or add a dispatch point.
- The refresh step (Piece 2) fires only on merge/PR-finish paths — keep and discard paths skip it.
- The human gate on refresh is mandatory; the orchestrator must not auto-refresh without confirmation.

## 3. Scope

### Goals

- Add a graph-aware context-seeding step to `skills/brainstorming/SKILL.md` at the "Explore project context" checklist item (Piece 1 — COLLECT).
- Add a post-land graph refresh gate and dispatch to `skills/finishing-a-development-branch/SKILL.md` after phase E merge/PR paths complete (Piece 2 — REFRESH).
- Document both changes in `docs/orchestrator-workflow.md` as a new `◆ D` dispatch node in phase E and an `○` inline note at the brainstorming collect step.
- Keep the orchestrator thin: collect is a cheap inline grep; refresh is always dispatched.

### Non-Goals

- Auto-refreshing the graph without a human gate — we do not want silent background rebuilds.
- Modifying how `understand-anything` itself builds the graph — this spec only describes how the orchestrator interacts with what the plugin already produces.
- Supporting graph formats other than the `.ua/knowledge-graph.json` schema the plugin writes today.
- Changing the brainstorming skill's overall structure, Red Flags table, or rationalization-prevention content.
- Implementing the three file changes themselves — those are for the subsequent implementation plan.

## 4. User Stories

### US-1: Graph-aware brainstorming context (Priority: P1)

As an orchestrator beginning a brainstorming session, I want to grep the knowledge graph for the feature's keywords when a fresh graph is present, so that I seed my design context with pre-built node names, summaries, and edges instead of discovering them solely through file exploration.

**Acceptance criteria:**

- GIVEN a knowledge graph exists at `.ua/knowledge-graph.json` (or legacy path) AND `project.gitCommitHash` matches `git log -1 --format=%H -- .` WHEN the orchestrator reaches the "Explore project context" step THEN it greps the graph for the feature's keywords and surfaces relevant node names, summaries, and edges as seed context before proceeding with normal file exploration.
- GIVEN the graph is missing OR stale (hash mismatch) WHEN the orchestrator reaches the "Explore project context" step THEN it notes this in one line and falls back to normal file exploration without dispatching any worker.
- GIVEN the graph exists and is fresh WHEN the grep finds no matching nodes THEN the orchestrator proceeds with normal file exploration without error.
- GIVEN any state WHEN the collect step runs THEN no new dispatch point is introduced and no worker is launched.

### US-2: Post-land knowledge graph refresh gate (Priority: P1)

As an orchestrator completing a merge or PR-finish path, I want to offer a human-gated graph refresh after code lands, so that the knowledge graph reflects the new HEAD before the next brainstorming session.

**Acceptance criteria:**

- GIVEN a branch has just been merged or a PR has just been finished (phase E merge/PR paths) WHEN the orchestrator runs the post-land steps THEN it freshness-checks the graph against the new HEAD.
- GIVEN the graph is stale after merge/PR finish WHEN the freshness check fails THEN the orchestrator presents a yes/no gate to the human before any refresh action.
- GIVEN the human answers yes WHEN the refresh is confirmed THEN the orchestrator dispatches a worker (role: `technical_writer`, task_type: `documentation_knowledge_transfer`) via `superpowers-orchestrator:dispatch-agent` to run `/understand` in the checkout.
- GIVEN the worker returns WHEN the orchestrator validates the response THEN it confirms that `project.gitCommitHash` in the rebuilt graph matches the current HEAD and appends the result to the project ledger.
- GIVEN the human answers no WHEN the gate is declined THEN the orchestrator skips the refresh and continues without error.
- GIVEN a keep or discard path (not merge/PR finish) WHEN phase E completes THEN no refresh gate is presented.
- GIVEN no provider pin is set WHEN the refresh worker is dispatched THEN the standard model-lookup ranking is used (understand-anything is available on all providers).

### US-3: Workflow diagram updated (Priority: P2)

As a developer reading `docs/orchestrator-workflow.md`, I want the diagram to show both new integration points, so that I can understand how graph collection and refresh fit the overall Superpowers flow.

**Acceptance criteria:**

- GIVEN the orchestrator-workflow.md diagram WHEN the document is updated THEN a new `◆ D` dispatch node appears after D19 in the phase E "Finish Branch" subtree, labelled as the conditional refresh dispatch.
- GIVEN the orchestrator-workflow.md diagram WHEN the document is updated THEN an `○` inline note appears at the brainstorming "Explore project context" step indicating the graph-collect behavior.
- GIVEN the diagram is updated WHEN existing legend semantics are examined THEN `○` (inline), `◆ Dn` (dispatch), `◇` (human gate), and `↻` (loop) retain their original meanings.

## 5. Approach

The integration deliberately avoids any architectural change to Superpowers. Both pieces reuse patterns already present in the skills:

- **Piece 1 (COLLECT):** A conditional grep inside an existing checklist item — same pattern as how skills read references files for context. The freshness check is two shell-readable fields; the grep is idiomatic `grep_search`. No new skill, no new dispatch, no structural change.
- **Piece 2 (REFRESH):** A new dispatch node in the finishing skill, guarded by both a path check (merge/PR only) and a human gate — the same pattern used by the existing four-option menu's option 2 (create PR). The worker routing follows the standard dispatch-agent ranking.

### Alternatives considered

| Option | Why rejected |
|--------|--------------|
| Auto-refresh on every branch finish without a gate | Would run expensive graph builds silently; violates the orchestrator's principle that expensive work always has a human checkpoint. |
| Inline graph build during brainstorming | Building is heavy; orchestrator work is thin. Would introduce latency and a failure mode into what is currently a fast, stateless step. |
| A new dedicated skill for graph interaction | Overkill — two small insertions into existing skills are simpler and maintain fewer moving parts than a third skill to invoke. |
| Triggering refresh from a CI hook rather than the finishing skill | Out of scope for Superpowers; requires infrastructure outside the plugin boundary. |
| Reading the full graph JSON rather than grepping | Graph JSON can be large; grepping by keyword is proportional to query intent and matches how `/understand-chat` reads the graph. |

## 6. Design

### Architecture

Two insertion points in existing skills; no new files created by this feature.

```
brainstorming/SKILL.md
  Phase B / checklist item 1 "Explore project context"
    └─ ○ COLLECT: if graph fresh → grep keywords → seed context
                  if graph missing/stale → note + fallback

finishing-a-development-branch/SKILL.md
  Phase E / merge path or PR-finish path (after D19)
    └─ ◇ Human gate: refresh graph?
         ├─ yes → ◆ D(new): dispatch worker → /understand → validate hash → ledger
         └─ no  → continue

docs/orchestrator-workflow.md
  Phase E subtree: new ◆ D node after D19
  Brainstorming subtree: new ○ annotation
```

### Components & Interfaces

**Collect step (inline, brainstorming skill):**

- Input: feature keywords from the brainstorming topic; filesystem paths `.ua/knowledge-graph.json` and `.understand-anything/knowledge-graph.json`.
- Operation: read `project.gitCommitHash` from the graph JSON; compare to `git log -1 --format=%H -- .`; if fresh, `grep_search` the graph JSON for each keyword and extract matching node names, summaries, and edge targets.
- Output: seed context injected into the brainstorming session; one-line note if missing/stale.
- Dependencies: `view_file` or `grep_search` on the graph JSON; `run_command` for `git log`.

**Refresh gate + dispatch (finishing skill):**

- Trigger: merge/PR-finish path only; keep/discard paths do not trigger.
- Gate: human yes/no confirmation.
- Dispatch payload: `role: technical_writer`, `task_type: documentation_knowledge_transfer`, command `/understand` in the checkout, no provider pin.
- Validation: after worker returns, read `project.gitCommitHash` from `.ua/knowledge-graph.json`; compare to current HEAD; append result to ledger.
- Dependencies: `invoke_subagent` (via `dispatch-agent` skill); `view_file` on the graph JSON; ledger append.

### Data Model & Flow

The knowledge graph JSON is authored by the `understand-anything` plugin; this spec does not change its schema. The fields this integration reads:

```json
{
  "project": {
    "gitCommitHash": "<sha>"
  },
  "nodes": [
    { "name": "...", "summary": "...", "edges": [...] }
  ]
}
```

**Freshness check flow:**

```
graph_hash = graph.project.gitCommitHash
head_hash  = git log -1 --format=%H -- .
fresh      = (graph_hash == head_hash)
```

### Error Handling

| Scenario | Handling |
|----------|----------|
| Graph file does not exist | Note "no graph found" in one line; fall back to normal file exploration (collect) or skip refresh gate (finish). |
| Graph JSON is malformed | Treat as missing; note the parse error; continue with fallback. |
| `git log` fails (e.g. not a git repo) | Treat graph as stale; note in one line; continue with fallback. |
| Worker dispatched for refresh returns `blocked` or `needs_revision` | Orchestrator notes the failure in the ledger; does not retry automatically; surfaces to human. |
| Refresh worker succeeds but hash still stale | Orchestrator notes the mismatch in the ledger; surfaces to human for investigation. |

### Edge Cases

- **Monorepo:** The `-- .` scope on `git log` limits hash comparison to the project root, preventing false-fresh readings when only other packages changed.
- **Legacy path co-existence:** If both `.ua/knowledge-graph.json` and `.understand-anything/knowledge-graph.json` exist, `.ua/` takes precedence. Legacy path is only checked if `.understand-anything/` directory is present.
- **Keep/discard paths in finishing skill:** The gate is skipped entirely; no freshness check is performed.
- **Graph already fresh after merge:** Freshness check passes; no gate is shown; finishing continues normally.
- **Empty grep results:** Not an error; the orchestrator proceeds to normal file exploration without comment.

## 7. Testing Strategy

**US-1 — Collect:**

- Manual scenario: start brainstorming with a fresh graph → verify seed context surfaces in session notes.
- Manual scenario: start brainstorming with a stale graph → verify the one-line note appears and no dispatch occurs.
- Manual scenario: start brainstorming with no graph → verify one-line note appears and fallback proceeds.
- Inspection check: review the brainstorming skill diff to confirm no new dispatch point was introduced.

**US-2 — Refresh:**

- Manual scenario: finish a branch via merge path with stale graph → verify gate appears; answer yes → verify worker dispatched; verify hash matches HEAD after return; verify ledger entry.
- Manual scenario: finish a branch via merge path with stale graph → gate appears; answer no → verify skip, no worker dispatched.
- Manual scenario: finish a branch via keep path → verify gate is absent.
- Manual scenario: finish a branch via discard path → verify gate is absent.
- Inspection check: review the finishing skill diff to confirm gate only fires on merge/PR paths.

**US-3 — Diagram:**

- Inspection: open `docs/orchestrator-workflow.md` after the implementation plan is executed; verify new `◆ D` node appears after D19; verify `○` annotation at brainstorming collect step; verify legend semantics unchanged.

## 8. Success Criteria

- SC-1: When a fresh knowledge graph is present, the orchestrator's brainstorming session notes contain at least one graph-derived node name or summary without any manual graph read by the human.
- SC-2: No new dispatch point is introduced into the brainstorming flow; the collect step adds zero orchestrator turns.
- SC-3: After a merge or PR finish on a project with understand-anything installed, the human is presented with a yes/no graph-refresh gate before the session ends.
- SC-4: On yes, a refresh worker is dispatched and returns; the graph's `project.gitCommitHash` matches the merged HEAD within the same session.
- SC-5: Keep and discard finishing paths complete without presenting the refresh gate.
- SC-6: `docs/orchestrator-workflow.md` contains the new `◆ D` node and `○` annotation with no change to existing legend symbols.
