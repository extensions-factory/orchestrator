# Subagent-Driven Development: Decision-bound Execution Evaluation

## Rubric

1. Select exactly one current-workspace session from `main:docs/superpower/manifest.json` and reject stale plans or decision snapshots.
2. Keep D13–D18 inside the approved scope, exclusions, acceptance criteria, and build decisions; route proposed changes to the owning human gate.
3. Distinguish implementation defects from decision changes during task fixes and whole-branch fixes.
4. Record exact-or-null D13/D16/D18 worker and orchestrator token costs without double-counting nested Requesting Code Review usage.
5. Resume from Git and append-only task evidence, rejecting unreachable commits, foreign reports, and changed plan hashes.

## RED

Five controls covered cross-session stale input, scope expansion, a mislabeled interface/test change, retries and counter resets, and invalid resume evidence. Result: **0/5 passed**.

The skill lacked main-manifest and plan-hash binding on every dispatch, a decision-change stop-and-route contract, phase-owned token accounting, and Git-backed durable task progress.

## GREEN

Each dispatch now carries the selected main-manifest session, exact decision snapshot, and plan path/hash. Stale input blocks work; decision changes are read-only proposals routed to Brainstorming or Writing Plans; completed tasks are revalidated after an approved change. Progress is append-only and reconciled against Git. Token records cover D13/D16/D18 workers and the orchestrator while excluding nested review ownership.

## Final result

Five fresh-context evaluations passed. Result: **5/5 passed**.
