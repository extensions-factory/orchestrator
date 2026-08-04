# Project Kickoff: Decision Gates Evaluation

## Rubric

1. Select the current workspace's entry from the single manifest on `main` and preserve other sessions.
2. Require human approval of the idea and research direction before `D1`–`D4`.
3. Require human approval of stack, standards, and AI tools before `D6`–`D8`.
4. Record all five decisions under the selected session's `project_kickoff` object.
5. Reread the entry before handoff, reject missing or changed decisions, and give a fresh session the workspace-selection instruction.

## RED

Five fresh-context controls tested automatic track selection, delegated setup choices, a fresh `writing-plans` session, blanket delegation, and two concurrent sessions. Result: **0/5 passed**.

Observed failures included:

- “Nothing written to `main:docs/superpower/manifest.json`.”
- “Idea not approved as interpreted.”
- “Stack, standards, and AI tools [are] chat-only.”
- “No completeness check prevents handoff with missing decisions.”
- “It never reads `main:docs/superpower/manifest.json` or selects `sessions[]` by the current workspace.”

## GREEN/REFACTOR

The revised contract now:

- selects the current workspace entry and reuses complete approved bundles on resume;
- gates research on approved `idea` and `research_direction`;
- gates setup/scaffolding on approved `stack`, `standards`, and `ai_tools`;
- preserves other sessions while updating `project_kickoff`;
- accepts `ai_tools: []` when the human chooses none;
- sends changed decisions back through their gate and regenerates affected downstream artifacts;
- rereads all five fields and passes the exact workspace-aware manifest instruction at handoff.

The first GREEN pass exposed two loopholes: “none” could make `ai_tools` empty, and a late stack change could leave a stale scaffold. Both were closed and their scenarios rerun.

## Final result

Five fresh-context agents covered early research dispatch, delegated setup choices, fresh-session handoff, concurrent session isolation/resume, and late stack changes with no AI tools. Result: **5/5 passed** after refactor. Every response was read manually; no scoped bypass remained.
