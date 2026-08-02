# Receiving Plan Refine: Decisions, Resume, and Token-cost Evaluation

## Rubric

1. Bind findings to exactly one current-workspace session, approved decision snapshot, and current artifact hashes before reading them.
2. Apply only corrections that preserve or restore all seven approved decision fields, regardless of reviewer labels.
3. Persist every finding's disposition and route proposed decision changes to Writing Plans' owning human gate.
4. Record every receiving-phase orchestrator invocation with exact-or-null token counts and honest coverage, without importing D11 costs.
5. Recover safely after partial edits, validate plan/HTML/decision consistency, and send one current downstream handoff.

## RED

Five controls covered conflicting in-process sessions, partial/reset token counters, mislabelled decision changes, mixed finding types under execution pressure, and context loss before handoff. Result: **0/5 passed**.

Observed failures included:

- Receiving read findings before selecting the current manifest session or checking hashes.
- “If it holds up: fix it directly” allowed technically attractive scope and interface changes to bypass approval.
- No durable per-finding resolution, pending human-decision state, or Writing Plans route existed.
- No receiving orchestrator usage was recorded.
- Reused findings paths and missing checkpoints made partial resume and stale handoff unsafe.

## GREEN/REFACTOR

Receiving now validates the selected session and handed-off identities before findings, judges edits by their actual effect on the complete approved bundle, and journals every disposition. Approval-preserving corrections synchronize and validate the plan artifacts; decision changes block Refine/Execute and return to Writing Plans. Receiving-only orchestrator usage has exact-or-null records and independent field coverage.

The first GREEN resume evaluation found that receiver-authored edits could be mistaken for external drift and that the handoff lacked durable deduplication. A write-ahead `resolution-<turn>.md` now checkpoints each edit, plan/HTML hashes, regeneration state, and a stable downstream idempotency key. A second pass exposed the crash window after mutation but before checkpoint completion; resume now accepts and verifies exactly one trailing `applying` result before advancing it.

## Final result

Five fresh-context evaluations passed after refactor. Result: **5/5 passed**.
