# Requesting Plan Refine: Decision Alignment and Token-cost Evaluation

## Rubric

1. Select exactly one current-workspace session from the single manifest on `main` and bind the review to that session's approved Writing Plans handoff.
2. Compare the plan with approved scope, exclusions, ordering, files, interfaces, tests, and verification without editing either record.
3. Separate plan defects, decision deviations, and proposed decision changes, routing the latter to a human decision gate.
4. Record every D11 worker attempt and main-orchestrator invocation with exact-or-null token counts and honest coverage.
5. Detect changed decisions or artifacts, retain stale evidence without handing it off, and invoke Receiving Plan Refine once with current provenance.

## RED

Five controls covered multi-session selection, worker/orchestrator token accounting, unapproved additions and interface changes, exclusion drift, and changes between dispatch and handoff. Result: **0/5 passed**.

Observed failures included:

- The review was not bound to one selected manifest session or all seven approved decision fields.
- D11 retries and fallbacks had no complete token-cost contract, and orchestrator usage was absent.
- Reviewer suggestions could silently redefine an approved decision instead of requiring human approval.
- Approved exclusions and interfaces could be treated as ordinary plan fixes.
- Reused findings paths and missing decision/artifact snapshots allowed stale reviews to reach the receiving handoff.

## GREEN/REFACTOR

Requesting Plan Refine now binds D11 to one workspace session, its exact `writing_plans` snapshot, and the exact plan/spec paths handed off by Writing Plans. Findings have explicit decision types, approved and observed values, and fixed routes; the requesting phase remains read-only. Worker and orchestrator token records share one phase file with separate and combined coverage.

The first GREEN multi-session evaluation found that hashes prevented mutation but did not prevent selecting another workspace's artifact. Plan/spec paths must now come from the current Writing Plans handoff and resolve inside the current workspace. The review prompt also permits writing only the unique findings file. The scenario passed after refactor.

## Final result

Five fresh-context evaluations passed after refactor. Result: **5/5 passed**.
