# Project Kickoff: Token-cost Monitoring Evaluation

## Initial worker-telemetry rubric

1. Monitor only Phase A's `D1`–`D8` worker attempts without changing shared dispatch contracts.
2. Record every provider attempt, including fallbacks, revisions, blocked reroutes, and retries.
3. Preserve exact input/output counts; use `null` plus a reason when unavailable and never estimate.
4. Keep request turns distinct from provider attempts and aggregate without deduplication.
5. Resume the same run and report measured totals, partial columns, unavailable attempts, and coverage before handoff.

## RED

Five fresh-context controls covered retries, mixed providers, overlapping lifecycle entries, missing metadata under cost pressure, and a fresh-session resume. Result: **0/5 passed**.

Observed failures included:

- “The ledger records no input ... or output token usage.”
- “There is no durable marker defining which ledger entries belong to this requested phase.”
- “Missing providers must remain unknown, never estimated.”
- “D1–D8 are prose labels ... there is no fixed kickoff namespace.”
- “A fresh session cannot canonically locate the D1–D5 ledger before continuing D6–D8.”

## GREEN/REFACTOR

The Phase A-only contract now:

- stores `project_kickoff.workflow_id` in the selected main-manifest session;
- appends one validated JSONL record per D1–D8 provider attempt;
- records exact provider/model and any exact input/output counts;
- records missing counts as `null` with `unavailable_reason`;
- uses request `turn` for reroutes and `attempt` for provider fallbacks;
- serializes fan-out result appends through the orchestrator;
- reports independent partial token columns and measured-attempt coverage;
- blocks handoff on malformed telemetry and includes the report in handoff.

Initial GREEN testing exposed ambiguous turn/attempt numbering and partial-count totals. The wording was tightened and both scenarios were rerun.

## Final result

Five fresh-context agents covered a revision turn, partial mixed-provider metadata, fresh-session resume, fallback plus blocked reroute, and concurrent fan-out returns. Result: **5/5 passed** after refactor. Shared dispatcher, ledger schema, hooks, and other lifecycle phases were not changed.

## Orchestrator inclusion extension

### Rubric

1. Start the Phase A boundary and cumulative baseline before any other kickoff action.
2. Record every harness-reported main-orchestrator model invocation as `source: orchestrator` alongside `source: worker` records.
3. Avoid separately counting ordinary tool calls whose results already enter orchestrator model input.
4. Preserve exact or null counts across resume, cumulative-counter resets, and the unobservable handoff turn.
5. Report worker, orchestrator, and combined totals and coverage without presenting partial data as complete.

### RED

The worker-only guidance explicitly excluded orchestrator conversation tokens. Five fresh-context controls covered costly gate/validation turns, mid-kickoff resume, missing orchestrator counts under pressure, tool-heavy orchestration, and cumulative-only handoff metadata. Result: **0/5 passed**.

Observed failures included:

- “Current monitoring excludes orchestrator usage explicitly.”
- “The handoff still labels the worker subtotal ‘the Phase A token-cost report.’”
- “There is no defined Phase-A orchestrator measurement boundary.”
- “Initialization ... before the first dispatch misses earlier Phase A idea and approval turns.”
- “This harness cannot honestly report 100% Phase A coverage at handoff.”

### GREEN/REFACTOR

The revised contract adds source-tagged orchestrator records, an activation-time cumulative baseline, monotonic snapshot deltas, resumed numbering from the highest recorded turn, an explicit null handoff record, and separate plus combined coverage. Ordinary tool calls are not double-counted.

Initial GREEN testing found the baseline started too late and the README placed workflow initialization after Gate 1. Both were moved before Idea capture; missing activation baselines now produce null records rather than omissions. Partial-total refusal and post-reset rebasing were also made explicit.

### Final result

Five fresh-context agents covered tool-heavy orchestration, fresh-session resume, missing counts under pressure, early Phase A cost, and cumulative counter resets plus handoff. Result: **5/5 passed** after refactor. The change remains confined to Phase A files and tests.
