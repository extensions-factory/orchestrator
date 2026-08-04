# Writing Plans: Decisions, Source Boundary, and Token-cost Evaluation

## Rubric

1. Select exactly one current-workspace session from the single manifest on `main` and verify applicable upstream approvals.
2. Produce source-free plan artifacts that still specify exact files, interfaces, tests, commands, and verification.
3. Require explicit approval and selected-session persistence of scope, exclusions, ordering, files, interfaces, tests, and verification.
4. Record D10 worker attempts and main-orchestrator invocations with exact-or-null token counts and honest coverage.
5. Return late decision changes to the owning gate and validate regenerated artifacts before exactly one Refine or Execute route.

## RED

Five controls covered multi-session planning, worker/orchestrator token accounting, deadline pressure for copy-paste source, weak execution assent, and partial resume with late decision changes. Result: **0/5 passed**.

Observed failures included:

- “The skill does not isolate the current workspace session.”
- “Token accounting is completely unenforced.”
- The template made copy-pasteable test and implementation source mandatory.
- “Looks fine, execute” bypassed explicit approval and persistence.
- Late changes could be fixed inline without an owning decision gate.

## GREEN/REFACTOR

Writing Plans now binds D10 to the selected session's approved upstream records, creates source-free plan artifacts, and presents and persists the seven-field final build decision before routing. It records worker and orchestrator usage separately and validates both plan artifacts against the approved decision before handoff.

The first GREEN token evaluation found ambiguous same-provider retry numbering and partial-record coverage. Attempts now increment for every provider call within a turn; a measured record requires both counts, with input and output field coverage reported independently.

## Final result

Five fresh-context evaluations passed after refactor. Result: **5/5 passed**.
