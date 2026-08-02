# Brainstorming: Decisions and Token-cost Evaluation

## Rubric

1. Select exactly one current-workspace session from the single manifest on `main`.
2. Require explicit approval of problem, scope, exclusions, approach, and acceptance criteria before detailed design or D9.
3. Persist the approved bundle, reuse complete bundles on resume, and return later changes to the owning gate.
4. Record D9 worker attempts and main-orchestrator invocations with exact-or-null token counts.
5. Verify manifest/design agreement and include source plus combined token coverage at handoff.

## RED

Five controls covered loose assent under time pressure, two-session resume, D9 revision and orchestrator cost, late decision changes, and blanket delegation. Result: **0/5 passed**.

Observed failures included:

- “No normalized problem statement + explicit approval.”
- “Exclusions are absent.”
- “The current skill cannot reliably prevent cross-session or re-decision drift.”
- “All questions, design sections, approvals, validation, and handoff turns are inline and completely unmeasured.”
- “Artifact approval alone [can] change an approved decision.”

## GREEN/REFACTOR

The contract now selects one workspace entry, approves and records the five-field bundle, blocks detailed design/D9 until persistence, and routes later changes back through approval and regeneration. It also records source-tagged D9 and orchestrator telemetry with exact-or-null counts and reports separate plus combined coverage.

Initial GREEN tests exposed a flowchart bypass, ambiguous retry numbering/coverage, and partial-session handling. The flow now includes the gate and manifest write; D9 turns and provider attempts are distinct; resume requires all five fields; empty exclusions require explicit approval of none.

## Final result

Five fresh-context agents covered fast-path pressure, isolated resume, missing token metadata with revision, late exclusion/criteria changes, and partial manifest data plus blanket delegation. Result: **5/5 passed** after refactor.
