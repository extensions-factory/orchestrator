# Designing UI: Decisions and Token-cost Evaluation

## Rubric

1. Select exactly one current-workspace session from the single manifest on `main`.
2. Require explicit approval of platform, layout, source, component approach, and constraints before planning input.
3. Persist the approved bundle, preserve other sessions, and return later decision changes to the owning gate.
4. Record every main-orchestrator invocation with exact-or-null token counts without misclassifying ordinary tools.
5. Verify manifest/design agreement, report token coverage, and preserve exactly-once planning ownership at handoff.

## RED

Five controls covered quick layout assent, direct and sub-flow handoff, multi-session resume, Figma/ReUI token accounting, and late UI decision changes. Result: **0/5 passed**.

Observed failures included:

- “No required slots exist for component approach, accessibility constraints, or responsive behavior.”
- “No instruction reads `main:docs/superpower/manifest.json`.”
- “The orchestrator can therefore use all named tools and hand off with zero token records.”
- “No instruction regenerates or reapproves affected design sections after a changed decision.”
- The README contradicted the live brainstorming sub-flow.

## GREEN/REFACTOR

The contract now selects one workspace entry, approves and records the five-field UI bundle, blocks planning input until persistence, and routes later decision changes through approval and regeneration. It records each main-orchestrator invocation with exact-or-null counts, treats Figma and ReUI as ordinary tools, and validates the record against the written design before the correct owner invokes `writing-plans` once.

Fresh tests also covered blanket delegation, partial current-session state beside a complete old session, cumulative counter reset, final-turn accounting, and changes to component approach plus responsive constraints. No remaining scenario-specific loophole was found.

## Final result

Five fresh-context evaluations passed after refactor. Result: **5/5 passed**.
