---
name: dispatch-agent
description: Use when the orchestrator is about to hand a task to a worker or reviewer - at any dispatch point in subagent-driven-development, dispatching-parallel-agents, or requesting-code-review, or whenever a task needs routing to a specific model or provider, or a review that must differ from the author's provider.
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

## Purpose

Encodes `SM.request()` + `SM.receive()` from the SDLC orchestration flow. The orchestrator never does the work; it routes the work. This skill is the single codified path for every dispatch.

## The Process

1. **Resolve `task_type`** from the plan annotation (`writing-plans` writes it) or from the role for unplanned work.
2. **Look up the model** in `assets/sdlc-model-routing.json` by `task_type`. Each `recommended_models[]` entry is `{rank, provider, model, why}`. Take the rank-1 entry, then derive the two protocol fields the JSON does not store directly:
   - **`agent`** from `provider` via this map: `"Claude Code" → claude`, `"Codex" → codex`, `"Antigravity CLI" → antigravity`.
   - **`effort`** rule: Antigravity encodes it in the model string (e.g. `"Gemini 3.5 Flash (Medium)"` → `medium`) — parse the parenthesized word; Codex takes an explicit `--effort`; Claude has none. When not otherwise determined, default `medium`, or apply the routing JSON's `selection_rules` (High/Thinking → `high`; Low/mini/haiku → `low`).
   - **Review tasks** (`code_review_quality`, `security_review`): read `author_agent` from `.superpowers/ledger.jsonl` and pick the first recommended model whose mapped `agent` differs (provider diversity). If no other provider is enabled, fall back to a different model on the same agent and note it in the ledger entry.
3. **Build the request JSON** per `assets/message-protocol.json`. Set `dispatch.persona` to the **role name** (e.g. `software_engineer`) — a short string, never a prompt-file's contents. Any role prompt file (e.g. `implementer-prompt.md`) is pasted into the spawn prompt body, not into `dispatch.persona`. Record the diversity decision in `dispatch.provider_diversity`: for a review task set `{author_agent, author_model, rule: "reviewer_agent != author_agent"}`; otherwise set `provider_diversity: null`. Set `message_type: "request"`.

### Provider-readiness preflight (before Send)

Before sending, verify the target `agent` is actually reachable — a provider that is installed but not authenticated will hang the call:

- `agent: codex` → run the Codex readiness check (`codex:setup`, i.e. `node <codex-plugin>/scripts/codex-companion.mjs setup --json`). Ready when `ready: true` OR at least one enabled profile in `profiles.json` shows `loggedIn: true`. If not ready, do NOT call `codex exec` — degrade.
- `agent: antigravity` → always ready: the bridge is a HUMAN relay (see Send below), no auth needed.
- `agent: claude` → always ready (the Agent tool needs no external auth).

If the chosen agent is **not ready**, apply the degradation ladder (walk down `recommended_models[]` to the next entry whose mapped agent is ready) rather than emitting a call that blocks.

4. **Send** via the bridge matching `agent`:
   - `claude` → the Agent tool, prompt = `"ROLE: subagent\n" + <request JSON>`.
   - `codex` → `/codex:rescue --model <model> --effort <effort> "<request JSON>"`.
   - `antigravity` → HUMAN relay (no CLI bridge yet). Write the request JSON to `.superpowers/relay-request.json`, then tell the human: the exact model string to select (e.g. `Gemini 3.5 Flash (High)`), the file path, and "paste this request into Antigravity/Gemini on that model, then paste the worker's response JSON back here". The human's pasted response IS the worker's final message — validate and route it exactly like any other. When a real `/agy:task` bridge ships, replace this bullet with the CLI call.
5. **Await** the worker's final message (the response JSON) and write it to `.superpowers/last-response.json`.
6. **Validate** it: `node scripts/validate-message.mjs .superpowers/last-response.json`. On invalid, reissue once with a format reminder; a second failure is treated as `status: blocked`.
7. **Append** the pair to `.superpowers/ledger.jsonl` as one line:
   `{"ts":"<iso>","request":{...},"response":{...},"author_agent":"<agent>","author_model":"<model>"}`
   For a human-relayed dispatch add `"via":"human_relay"`.
8. **Route:** `status: done` → forward to the next step; `needs_revision` → re-request the same role with feedback; `blocked` → answer from context or escalate to the human, then re-request.

## Graceful degradation

**Default:** Dispatch to a worker subagent is the DEFAULT, not conditional; different role = different worker.

1. Chosen entry fails or its agent is not ready → walk down `recommended_models[]` in rank order and dispatch to the next entry whose mapped agent is ready. Never jump straight to claude.
2. Bridge/quota failure on codex → rely on codex-plugin-cc failover first, then rule 1.
3. antigravity is never "not ready" — the human relay is always available. It fails only if the human declines to relay; then apply rule 1.
4. A claude subagent is the LAST-RESORT worker (always available, no external auth) — use it only when every non-claude entry in `recommended_models[]` is exhausted.
5. Only when the harness has no subagent capability at all → skip dispatch-agent; the caller runs executing-plans inline.

## Role personas (the `dispatch.persona` role name; canonical list — mirrored read-only in intake-task)

- `product_owner` — owns and orders the Product Backlog; defines requirements and acceptance criteria; write no code.
- `scrum_master` — facilitates Scrum events and removes impediments; do not implement or decide product scope.
- `software_engineer` — write production code under TDD; do not skip tests or refactor beyond scope.
- `tech_lead` — review only; give feedback, do not rewrite.
- `qa_engineer` — verify acceptance criteria with real execution and show evidence; write no production code.
- `ux_ui_designer` — designs UX flows, wireframes, and prototypes; do not implement backend logic.
- `devops_engineer` — builds and maintains CI/CD, deployments, and workspace/environment setup; do not design product features.
- `security_engineer` — report vulnerabilities with severity; do not fix.
- `sre` — owns monitoring, incident response, and postmortems; do not implement product features.
- `engineering_manager` — oversees delivery cadence, technical quality, and sprint planning; do not write production code.
- `product_manager` — defines product vision/roadmap and prioritizes the ART backlog; write no code.
- `technical_writer` — writes developer docs, ADRs, changelogs, and handoff notes; do not write production code.
- `business_analyst` — elicits business requirements and translates them into user stories; write no code.
- `data_analyst` — analyzes data and delivery metrics into findings; do not write production code.
- `agile_coach` — coaches process improvement across teams; do not implement or decide product scope.
- `stakeholder` — provides business context and feedback on Increments; do not implement or write requirements.

## Ledger

`.superpowers/ledger.jsonl` is append-only, one pair per line. Create it on first dispatch if absent. It is the source of truth for `author_agent` in provider-diversity lookups.
