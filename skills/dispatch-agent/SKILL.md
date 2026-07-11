---
name: dispatch-agent
description: Use when the orchestrator needs to hand a task to a worker - resolves the right model and provider for the task_type, builds the request envelope, spawns the worker, awaits and validates the response, and logs the request/response pair to the ledger. Invoked by subagent-driven-development, dispatching-parallel-agents, and requesting-code-review at every dispatch point.
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
4. **Send** via the bridge matching `agent`:
   - `claude` → the Agent tool, prompt = `"ROLE: subagent\n" + <request JSON>`.
   - `codex` → `/codex:rescue --model <model> --effort <effort> "<request JSON>"`.
   - `antigravity` → `/agy:task --model <model> "<request JSON>"` (bridge not yet available; if unreachable, degrade per graceful-degradation below).
5. **Await** the worker's final message (the response JSON) and write it to `.superpowers/last-response.json`.
6. **Validate** it: `node scripts/validate-message.mjs .superpowers/last-response.json`. On invalid, reissue once with a format reminder; a second failure is treated as `status: blocked`.
7. **Append** the pair to `.superpowers/ledger.jsonl` as one line:
   `{"ts":"<iso>","request":{...},"response":{...},"author_agent":"<agent>","author_model":"<model>"}`
8. **Route:** `status: done` → forward to the next step; `needs_revision` → re-request the same role with feedback; `blocked` → answer from context or escalate to the human, then re-request.

## Graceful degradation

1. Bridge/quota failure on codex → rely on codex-plugin-cc failover.
2. If failover yields nothing → retry on agent: claude.
3. No bridge for the chosen agent (e.g. antigravity) → dispatch to a claude subagent instead.
4. No worker provider at all → skip dispatch-agent; the caller runs executing-plans inline (today's behavior).

## Role personas (the `dispatch.persona` role name; canonical list — mirrored read-only in intake-task)

- `software_engineer` — write production code under TDD; do not skip tests or refactor beyond scope.
- `tech_lead` — review only; give feedback, do not rewrite.
- `qa_engineer` — verify acceptance criteria with real execution and show evidence; write no production code.
- `security_engineer` — report vulnerabilities with severity; do not fix.
- `product_manager` / `business_analyst` — deliver findings/requirements; write no code.

## Ledger

`.superpowers/ledger.jsonl` is append-only, one pair per line. Create it on first dispatch if absent. It is the source of truth for `author_agent` in provider-diversity lookups.
