---
name: worker-healing
description: Use when a worker dispatch fails with a bridge/plugin error—an invalid forwarded CLI flag, a print/response timeout, or a spawn/forward failure—rather than a task-logic failure; routes a repair worker for either codex or antigravity, validates the result, and reminds the human about release. Also usable manually.
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

# Worker Healing

## Purpose

The orchestrator routes work; it never repairs a bridge inline. Use this skill
when a dispatch failed because its bridge mangled or terminated the invocation.

1. **Recognize.** A **bridge bug** is an invalid CLI flag rejected by the
   worker CLI, a print/response timeout that kills healthy work, or a
   spawn/forward failure. A **task-logic failure** is a worker that ran and
   reported it could not complete its task; re-scope or re-dispatch that work.
   This skill applies only to the former.
2. **Locate.** The bridge source is in the separate `codex-plugin-cc` repo,
   not this orchestrator checkout. Its argv, timeout, and spawn logic lives in
   the per-bridge lib builder in the map below.
3. **Route the fix.** Do not edit the bridge. Use
   `superpowers-orchestrator:dispatch-agent` to dispatch a `claude` subagent
   with `task_type: debugging_root_cause`, walking the degradation ladder past
   the broken or suspect provider. Give the worker the failure evidence and
   require it to reproduce the failure, add a failing regression test using
   the matching fake fixture, apply the smallest correct fix in the lib
   builder, and verify the relevant suite. The bridge repository is separate,
   and the repair must not be dispatched through the bridge under repair.
4. **Validate and ledger.** Confirm the worker's regression test and suite
   pass, and confirm the forwarded invocation is no longer mangled. Validate
   the response envelope and record the request/response pair through the
   normal dispatch-agent ledger flow.
5. **Remind the human to release.** Do not release it. In `codex-plugin-cc`,
   release requires `node scripts/bump-version.mjs <version>`, an entry in the
   affected plugin's `CHANGELOG.md`, and a GitHub push. The orchestrator must
   not run the version bump or push.

## Both bridges, one procedure

| Bridge | Lib builder | Fake fixture |
|---|---|---|
| codex | `plugins/codex/scripts/lib/codex.mjs` | `tests/fake-codex-fixture.mjs` |
| antigravity | `plugins/antigravity/scripts/lib/antigravity.mjs` | `tests/fake-antigravity-fixture.mjs` |

The fixture records forwarded flags; the dispatched repair worker uses it to
prove the bridge forwards the corrected invocation.

## Worked example: 2026-07-25

An antigravity dispatch failed twice: `--effort` was unsupported for `Claude
Sonnet 4.6 (Thinking)`, then a five-minute print timeout killed a healthy write
job. The orchestrator treated both as bridge bugs, dispatched a repair worker
to `plugins/antigravity/scripts/lib/antigravity.mjs`, and validated its fix:
guard `--effort` for parenthesized-qualifier models with `/\([^)]*\)/`, raise
`DEFAULT_PRINT_TIMEOUT_MS` from 5m to 15m, and cover it in
`tests/antigravity-runtime.test.mjs`. The bridge shipped as codex-plugin-cc
v3.0.2.
