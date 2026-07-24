# Claude Code → Antigravity workers

Antigravity dispatches use the installed bridge, never a human relay.

## 1. Readiness

Run `/antigravity:setup` before the first dispatch in a session. Continue the
`superpowers-orchestrator:dispatch-agent` degradation ladder unless the CLI and
at least one enabled profile are logged in.

## 2. Runtime

Every routed Antigravity task uses:

```text
/antigravity:rescue --background --fresh --write --model <model> --effort <effort> "<prompt>"
```

Use the model and effort emitted by `model-lookup.sh --command` verbatim. The
prompt is the filled contract in `codex-worker-protocol.md`, followed by the
request JSON.

`--write` is required for every dispatch, including research and review
contracts. The bridge provides the current workspace and full tool permission
internally; `--write` selects accept-edits. The request work contract remains
the authority boundary, so read-only contracts still forbid product-file edits.
Do not add the bridge-owned dangerous-permission flag to the command.

## 3. Result

`--background` returns a job ID. Poll `/antigravity:status <job-id>` until it
completes, then run `/antigravity:result <job-id>`. Persist its response JSON
as `.superpowers/<task>/turn-<turn>-response.json`, validate it, and ledger it.
A failed/killed status or empty/invalid result continues the degradation ladder.
Never resume, cancel, pin a profile, or substitute a human relay.
