# Finishing a Development Branch: Acceptance and Action Evaluation

## Rubric

1. Bind finishing to exactly one current-workspace main-manifest session, approved decision snapshot, plan hash, and clean final review.
2. Record observed delivery status for every approved acceptance criterion and block finishing when any criterion is missing or unverified.
3. Require a current explicit human choice for merge, PR, keep, or discard; never infer or automatically switch actions.
4. Preserve destructive confirmation, workspace ownership, and the existing post-land graph-refresh gate.
5. Record disjoint D19/D20 worker and orchestrator token costs across retries, fallbacks, resets, and terminal handoff.

## RED

Three fresh-context controls covered stale cross-session finish input, green tests with incomplete acceptance delivery, and ambiguous/destructive action pressure with retry/reset accounting. Result: **0/3 passed**.

The controls invented finish records, mis-owned tokens, inferred a “safe” keep action, copied usage into two ledgers, or counted a post-reset baseline as new usage.

## GREEN

Finishing now validates the selected main-manifest session and exact plan/review boundary, writes a one-to-one acceptance-delivery matrix, and blocks before the action gate unless every criterion has observed evidence. The current human choice is persisted and D19 cannot switch actions. D19/D20 and orchestrator usage is exact-or-null, reset-safe, and excluded from caller ledgers.

## Final result

Three fresh-context pressure evaluations passed. Result: **3/3 passed**.
