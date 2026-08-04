# Visual Companion Draft Split Evaluation

## Rubric

1. Normal brainstorming never offers or loads Visual Companion.
2. Only a human request naming Visual Companion discovers the draft skill.
3. The draft owns its guide, scripts, helper, server, and frame template.
4. Runtime and resource tests target the standalone package.
5. Brainstorming retains no active-flow documentation or runtime ownership.

## RED

Five fresh-context evaluations covered automatic brainstorming offers, explicit discovery, runtime/test coupling, generic visual prompts, and postponed integration. Result: **0/5 passed**.

Observed failures included:

- “Reaching a qualifying visual question automatically triggers the companion offer.”
- “No standalone Visual Companion skill is discoverable.”
- “Nearly every `tests/brainstorm-server/*` test hard-codes” the brainstorming path.
- Generic layout and diagram prompts could activate the embedded flow without naming it.
- Brainstorming owned the guide, scripts, template, lifecycle, and runtime tree.

## GREEN/REFACTOR

Visual Companion is now a standalone draft with an explicit-name-only trigger and self-owned resources. Brainstorming no longer mentions or offers it, and all runtime/resource tests use the new package paths.

The first GREEN pass found one stale `20-design/brainstorm/<session-id>` branch in brainstorming's runtime tree. Removing it and adding a regression assertion closed the ownership loophole.

## Final result

Five fresh-context evaluations passed after refactor. Result: **5/5 passed**.
