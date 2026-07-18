# Claude Code → Codex workers

The orchestrator uses the installed `codex` plugin as a synchronous worker
bridge. Resolve the task type first; it selects exactly one command family.

## 1. Readiness

Run `/codex:setup` before the first Codex dispatch in a session. Codex is ready
only when setup reports `ready: true`, or at least one configured profile is
enabled and `loggedIn: true`. Otherwise, continue the superpowers-orchestrator:dispatch-agent degradation
ladder. Do not attempt a worker call while authentication is unavailable.

## 2. Runtime

| Forced command | Exact task types |
|---|---|
| `/codex:review --wait --model <model> --base <base_sha>` | `code_review_quality` |
| `/codex:adversarial-review --wait --model <model> --base <base_sha> "<security focus>"` | `security_review` |
| `/codex:rescue --wait --fresh --write --model <model> --effort <effort> "<prompt>"` | `discovery_research`, `requirements_user_stories`, `backlog_refinement_prioritization`, `sprint_planning`, `architecture_design`, `ui_ux_prototyping`, `implementation_coding`, `debugging_root_cause`, `testing_qa`, `release_deployment`, `workspace_setup`, `monitoring_incident_ops`, `documentation_knowledge_transfer`, `retrospective_process_improvement` |

Use the model and effort emitted by `model-lookup.sh --command` verbatim.
`context.base_sha` is mandatory for both review commands; security review also
uses `context.security_focus` verbatim. Missing input is a malformed request,
so stop before dispatch; do not degrade, use automatic scope detection, or
select another command.

The rescue prompt is the filled inline contract from
`codex-worker-protocol.md` followed by the request JSON. Its fixed flags mean:

- `--wait` keeps the plugin call in the foreground.
- `--fresh` prevents cross-talk with repository/session-latest rescue threads.
- `--write` selects the plugin's workspace-write task sandbox.
- Explicit `--model` and `--effort` carry the routing decision into app-server.
- Without `--profile`, each fresh task uses the plugin scheduler to choose a
  compatible enabled account by configured weight.

Review commands are foreground and read-only. They take the selected model and
exact base commit, but no effort, write, fresh, or rescue prompt flags.

Never use background/status/result/cancel, resume, `--profile`, or transfer.
Never substitute one command family for another.

## 3. Result

For rescue, stdout must be the response JSON. Persist it as
`.superpowers/<task>/turn-<turn>-response.json`, then validate and ledger it.

Review commands return prose rather than a message envelope. Persist stdout
verbatim as `.superpowers/<task>/turn-<turn>-review.md`, then construct the one
response envelope defined by `codex-worker-protocol.md`, validate it, and ledger
the pair. Do not alter or summarize the review artifact.

Any command failure continues the superpowers-orchestrator:dispatch-agent degradation ladder. Never
fabricate output, poll for another result, resume a thread, or substitute rescue
for a failed review command.
