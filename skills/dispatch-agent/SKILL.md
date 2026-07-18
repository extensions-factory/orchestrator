---
name: dispatch-agent
description: Use when the orchestrator is about to hand a task to a worker or reviewer - at any dispatch point in subagent-driven-development, dispatching-parallel-agents, or requesting-code-review, or whenever a task needs routing to a specific model or provider, or a review that must differ from the author's provider.
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

## Purpose

Encodes `SM.request()` + `SM.receive()` from the SDLC orchestration flow. The orchestrator never does the work; it routes the work. This skill is the single codified path for every dispatch.

**Every worker spawn goes through Steps 1–8.** Calling any provider bridge directly without routing lookup and readiness preflight is a protocol violation. Claude remains the final degradation rung; the routing table decides every task and the task type decides the one permitted Codex command.

## The Process

1. **Resolve `task_type`** from the plan annotation (`writing-plans` writes it) or from the role for unplanned work.
2. **Look up the model**: run `${CLAUDE_PLUGIN_ROOT}/scripts/model-lookup.sh <task_type>`, backed by `assets/sdlc-model-routing.json`. Select the rank using the rules below, then run `${CLAUDE_PLUGIN_ROOT}/scripts/model-lookup.sh --command <task_type> <rank>` and use its command template exactly, replacing only its named placeholders; never hand-compose a dispatch command.
   - **`agent`** from `provider` via this map: `"Claude Code" → claude`, `"Codex" → codex`, `"Antigravity CLI" → antigravity`.
   - **`effort`** rule: Antigravity encodes it in the model string (e.g. `"Gemini 3.5 Flash (Medium)"` → `medium`) — parse the parenthesized word; Codex takes an explicit `--effort`; Claude has none. When not otherwise determined, default `medium`, or apply the routing JSON's `selection_rules` (High/Thinking → `high`; Low/mini/haiku → `low`).
   - **Review tasks** (`code_review_quality`, `security_review`): read `author_agent` from `.superpowers/ledger.jsonl` and pick the first recommended model whose mapped `agent` differs (provider diversity). If no other provider is enabled, fall back to a different model on the same agent and note it in the ledger entry.
3. **Build the request JSON** per `${CLAUDE_PLUGIN_ROOT}/assets/message-protocol.json`. Set `task` and `turn` first — they name the file-based exchange folder `.superpowers/<task>/`:
   - `task`: kebab slug, assigned at the FIRST dispatch for a piece of work and reused unchanged by every related dispatch (review, revision, QA). Plan tasks → `task-<N>-<short-slug>` (e.g. `task-3-add-auth`); unplanned work → a short slug of the request.
   - `turn`: 1 + the highest existing turn number in `.superpowers/<task>/` (1 if the folder is empty or absent) — derived from the folder so it survives a crashed or resumed session.
   - Write the request to `.superpowers/<task>/turn-<turn>-request.json` (create the folder if needed).

   Set `message_type: "request"`. Record the diversity decision in `dispatch.provider_diversity`: for a review task set `{author_agent, author_model, rule: "reviewer_agent != author_agent"}`; otherwise set `provider_diversity: null`.

   For `agent: codex`, set `dispatch.persona`, `skill`, and the work contract from the one matching row in `references/codex-worker-protocol.md`. The only precedence rule is `skill: receiving-code-review` for D16/D18; it selects the review-remediation row regardless of `task_type`. Reject any other mismatch instead of choosing a persona or discipline. For other agents, `dispatch.persona` remains the caller's role name.

   For `code_review_quality` and `security_review`, require the exact commit in `context.base_sha`. For `security_review`, also require the complete focus string in `context.security_focus`. Missing either required field makes the request malformed: stop before dispatch and correct the request; never degrade, use automatic/working-tree scope, or select another command.

   Append the matching scope to `context.constraints`:
   - `discovery_research`, `code_review_quality`, and `security_review`: findings and requested artifacts only; no product-file edits.
   - `workspace_setup`: only the exact requested workspace/Git setup operation.
   - `release_deployment`: only the exact requested Git/release operation. Before a destructive release operation, require the recorded constraint `HUMAN_CONFIRMED_DESTRUCTIVE_RELEASE: <operation>`; without it, do not dispatch that operation.
   - Every other task: only requested file/test work; no commit, push, dependency installation, permission change, or unrelated privileged operation.

   If an operation is denied, the worker finishes authorized work and reports it in `output.blocked_ops`. These task-specific scopes replace the generic Git ban; workspace and release dispatches receive only their explicit exception.

### Provider-readiness preflight (before Send)

Before sending, verify the target `agent` is actually reachable — a provider that is installed but not authenticated will hang the call:

- `agent: codex` → run `/codex:setup` before the first Codex dispatch in the session. Ready means `ready: true`, or at least one configured profile is both enabled and `loggedIn: true`. If not ready, degrade. Readiness is authentication only; a permission error does not make Codex unavailable.
- `agent: antigravity` → always ready: the bridge is a HUMAN relay (see Send below), no auth needed.
- `agent: claude` → always ready (the Agent tool needs no external auth).

If the chosen agent is **not ready**, apply the degradation ladder (walk down `recommended_models[]` to the next entry whose mapped agent is ready) rather than emitting a call that blocks.

4. **Send** via the bridge matching `agent`:
   - `claude` → the Agent tool, prompt = `"ROLE: subagent\n" + <request JSON>`.
   - If the resolved `agent` is `codex`, `task_type` selects exactly one command:
     - `code_review_quality` → `/codex:review --wait --model <model> --base <base_sha>`.
     - `security_review` → `/codex:adversarial-review --wait --model <model> --base <base_sha> "<security focus>"`.
     - `discovery_research`, `requirements_user_stories`, `backlog_refinement_prioritization`, `sprint_planning`, `architecture_design`, `ui_ux_prototyping`, `implementation_coding`, `debugging_root_cause`, `testing_qa`, `release_deployment`, `workspace_setup`, `monitoring_incident_ops`, `documentation_knowledge_transfer`, `retrospective_process_improvement` → `/codex:rescue --wait --fresh --write --model <model> --effort <effort> "<prompt>"`, where `<prompt>` is the filled rescue block from `references/codex-worker-protocol.md` prepended to the request JSON.
     Never use background/status/result/cancel, resume, `--profile`, or `/codex:transfer`. Never substitute one command family for another; a failed review command degrades to the next routed provider, not rescue.
   - `antigravity` → HUMAN relay (no CLI bridge yet). The request already sits at `.superpowers/<task>/turn-<turn>-request.json` (Step 3) — tell the human: the exact model string to select (e.g. `Gemini 3.5 Flash (High)`), that file path, and "paste this request into Antigravity/Gemini on that model, then paste the worker's response JSON back here". The human's pasted response IS the worker's final message — validate and route it exactly like any other. When a real `/agy:task` bridge ships, replace this bullet with the CLI call.
5. **Receive** the foreground result; there is no poll/fetch step:
   - Codex rescue stdout is the response JSON; persist it at `.superpowers/<task>/turn-<turn>-response.json`.
   - Codex review/security stdout is not an envelope. Persist it verbatim at `.superpowers/<task>/turn-<turn>-review.md`, then construct the single response envelope specified in `references/codex-worker-protocol.md`, pointing `output.artifacts` to that Markdown file and setting `output.status: done`.
   - A claude worker writes its response via `report-task`; for antigravity, persist the human-relayed response yourself.
6. **Validate** it: `node scripts/validate-message.mjs .superpowers/<task>/turn-<turn>-response.json`. On invalid, reissue once with a format reminder; a second failure is treated as `status: blocked`.
7. **Append** the pair to `.superpowers/ledger.jsonl` as one line:
   `{"ts":"<iso>","task":"<task>","turn":<turn>,"request":{...},"response":{...},"author_agent":"<agent>","author_model":"<model>"}`
   For a human-relayed dispatch add `"via":"human_relay"`.
8. **Route:** `status: done` → forward to the next step; `needs_revision` → re-request the same role with feedback (same `task`, `turn + 1`); `blocked` → answer from context or escalate to the human, then re-request (same `task`, `turn + 1`).

   **Residual ops** — if the response carries `output.blocked_ops` (or `done` work needs committing):
   - Git bookkeeping (commit/push of validated worker output) → the orchestrator runs it inline. This is routing/bookkeeping, not implementation — it does not violate the never-implement rule.
   - Any other denied operation (installing dependencies, permissions, network access, …) → dispatch a claude subagent via this skill to perform exactly that operation, then continue the flow. Never perform it inline.

## Graceful degradation

**Default:** Dispatch to a worker subagent is the DEFAULT, not conditional; different role = different worker.

1. Chosen entry fails or its agent is not ready → walk down `recommended_models[]` in rank order and dispatch to the next entry whose mapped agent is ready. Never jump straight to claude.
2. Bridge/quota failure on codex → rely on codex-plugin-cc failover first, then rule 1. An empty, invalid, or failed foreground return is a bridge failure: never poll, resume, pin a profile, fabricate a response, or switch Codex command families.
3. antigravity is never "not ready" — the human relay is always available. It fails only if the human declines to relay; then apply rule 1.
4. A claude subagent is the ALWAYS-AVAILABLE worker and LAST RESORT (no external auth) — use it only when every non-claude entry in `recommended_models[]` is exhausted.
5. Only when the harness has no subagent capability at all → skip dispatch-agent; the caller runs executing-plans inline. This is a harness property, NOT a fallback for failed workers.

<HARD-GATE>
The ladder always terminates in a dispatch. Because a claude subagent is always available, "no worker could do it" is impossible — the orchestrator NEVER writes code, edits files, or runs tests itself, no matter how many workers failed.

The ladder is pre-authorized: never stop mid-ladder to ask the human's permission. The human appears in the flow only as the antigravity relay mechanism itself, or when the entire ladder is exhausted. "Which fallback should I use?" is a question the ladder already answered.
</HARD-GATE>

| Rationalization | Reality |
|-----------------|---------|
| "Worker failed twice, faster to fix it myself" | Re-dispatch to a claude subagent with the failure context. |
| "It's just a one-line change" | Small change = small dispatch. Scope doesn't waive the rule. |
| "Dispatching costs a round trip" | An orchestrator that implements loses its validation role. |
| "The worker was blocked on permissions" | Route the blocked op per Step 8, don't absorb the whole task. |
| "The Agent tool is one call away, skip the lookup" | Routing IS the job. Steps 1–2 before any spawn, claude included. |
| "This task is obviously claude-shaped" | The routing table decides, not intuition. Rank-1 may be another provider, ready. |
| "Better ask the human which fallback to use" | The ladder already decided. Walk it; ask only when it's exhausted. |
| "The Codex review failed, so retry with rescue" | Command family is fixed by task type. Degrade to the next routed provider. |

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

## File layout

All per-dispatch exchange files live under one folder per task — never flat in `.superpowers/` (flat fixed names collide under parallel dispatch):

```
.superpowers/
├─ ledger.jsonl                    # global, append-only, cross-task
└─ <task>/                         # e.g. task-3-add-auth
   ├─ turn-1-request.json          # implement
   ├─ turn-1-response.json
   ├─ turn-2-request.json          # review
   ├─ turn-2-response.json
   ├─ turn-3-request.json          # revision
   └─ turn-3-response.json
```

One monotonic turn counter per task; every dispatch (implement, review, revision, QA) takes the next turn. What kind of dispatch a turn was is read from `task_type`/`dispatch.persona` inside the envelope, not from the filename. Subsystem folders (`sdd/`, `plan-refine/`, `brainstorm/`) are unaffected.
