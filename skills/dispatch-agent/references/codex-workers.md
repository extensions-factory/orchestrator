# Claude Code → Codex Workers

When working in Claude Code with the `codex` plugin installed, use its
`/codex:*` commands to send work to Codex. Codex works in the same checkout
and machine-local environment, so a worker can inspect, edit, and test the
current repository directly.

### Readiness

Before the first dispatch, run:

```text
/codex:setup
```

This verifies that Codex is installed and authenticated. Do not dispatch when
it reports no ready account. If profiles are configured, setup also reports
which are logged in and enabled.

### Dispatching work

For every dispatch resolved to Codex, use one command only:

```text
/codex:rescue --write --model gpt-5.4-mini --effort medium <request JSON>
```

`--write` is mandatory for every Codex role and task type, including reviews,
diagnosis, research, and retrospectives. Do not replace this with
`/codex:review` or `/codex:adversarial-review` during worker dispatch.

The `--model` and `--effort` flags are optional; omit them to use Codex's
configured defaults. `spark` selects `gpt-5.3-codex-spark`. With multiple
accounts, add `--profile <name>` to pin a run; otherwise a fresh run may use
weighted account rotation.

Give the worker one bounded task. State the problem, relevant paths, required
constraints, acceptance checks, and what it must report. For orchestration,
pass the request JSON unchanged so the worker can return the matching response
JSON. Do not delegate concurrent edits to overlapping files.

Use `--background` for work expected to take more than a moment:

```text
/codex:rescue --write --background <request JSON>
/codex:status
/codex:result
```

`/codex:status [task-id]` shows active and recent jobs.
`/codex:result [task-id]` retrieves the final stored response and, when
available, the Codex session ID. `/codex:cancel [task-id]` stops an active job.

### Continuing a worker

Follow-up work normally continues the latest rescue thread for this repository.
Use `--resume` to require that behavior, or `--fresh` to start a separate
thread:

```text
/codex:rescue --write --resume apply the requested revision
/codex:rescue --write --fresh investigate an unrelated failure
```

Resumed tasks stay on the profile that created them; do not request a different
`--profile`. To continue the session directly in Codex, use the session ID
reported by `/codex:result` with `codex resume <session-id>` (and that
profile's `CODEX_HOME` when applicable).

`/codex:transfer` is not a worker dispatch. It imports the current Claude Code
conversation into a persistent Codex thread and prints the matching
`codex resume` command. Use it when the human wants to continue the whole
conversation in Codex.
