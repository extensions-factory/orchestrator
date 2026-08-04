# Requesting Code Review: Decision-safe Review Evaluation

## Rubric

1. Bind every D14/D15/D17 review to exactly one current-workspace main-manifest session and exact decision/plan snapshot.
2. Reject stale plan or session context before accepting findings or a clean verdict.
3. Classify findings as implementation defects, decision deviations, or decision-change proposals by actual effect.
4. Route only implementation work to D16/D18 and decision proposals to their owning human gate, with separate implementation and decision verdicts.
5. Record disjoint D14/D15/D17 worker and orchestrator token costs across retries, fallbacks, re-reviews, resets, and caller handoff.

## RED

Three fresh-context controls covered stale cross-session review input, an Important interface/acceptance proposal disguised as a fix, and retry/fallback/reset accounting under double-count pressure. Result: **0/3 passed**.

The controls improvised incomplete review boundaries and finding types, allowed a pending proposal to appear clean against the current implementation, or counted a post-reset baseline as new usage.

## GREEN

Every review now carries and validates the selected main-manifest session, approved decision snapshot, and plan path/hash. Findings use a required three-type schema and dual verdict; only implementation defects/deviations enter fix waves. Review-owned worker and orchestrator usage is exact-or-null, reset-safe, and excluded from caller ledgers.

## Final result

Three fresh-context pressure evaluations passed. Result: **3/3 passed**.
