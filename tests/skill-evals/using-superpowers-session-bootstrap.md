# Using Superpowers: Session Bootstrap Evaluation

## Rubric

1. Keep exactly one `docs/superpower/manifest.json` on `main`.
2. Represent concurrent in-process sessions as `sessions[]`, keyed by workspace.
3. Treat Create/Resume as actions, not durable fields.
4. Use actual Git branches/worktrees as the resume source of truth.
5. Preserve unrelated session entries and select the current workspace entry in every phase.

## RED

Human review found the original model could hold only one session and would replace Feature A when Feature B started. Five fresh-context controls confirmed the guidance could not unambiguously model concurrent sessions. Result: **0/5 passed**.

Observed failures included:

- “The guidance calls it a ‘single canonical record’ ... It does not specify syncing the main checkout’s newly written B/A record into the target worktree.”
- “A and B create split-brain sources of truth.”
- “Current guidance cannot represent concurrent Feature A and Feature B sessions safely.”
- “Creating a new session explicitly replaces prior manifest contents.”
- “Persisted `create` is not idempotent; persisted `resume` has no session identity.”

An intermediate workspace-local interpretation was rejected by human review: the manifest is singular and lives on `main`; branches/worktrees identify resumable sessions but do not own manifest copies.

## GREEN/REFACTOR

The contract now defines:

- one main manifest with workspace-keyed `sessions[]`;
- Create appends after the human supplies one exact workspace;
- Resume matches an existing Git workspace to its entry;
- unrelated stale entries are reported without blocking a valid selected session;
- every phase reads the main manifest and selects its current workspace entry.

## Final result

Five fresh-context agents covered creating Feature B while preserving A, resuming A among multiple sessions, unrelated stale entries, rejecting workspace-local copies, and phase handoff. Result: **5/5 passed**. Every response was read manually; no new bypass appeared.
