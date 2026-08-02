# Using Git Worktrees: Session Continuity and Token-cost Evaluation

## Rubric

1. Bind setup to exactly one selected main-manifest session and Git workspace, rejecting ambient sessions and slug guesses.
2. Preserve the caller workflow ID and `main:docs/superpower/manifest.json` through creation, recreation, reuse, fallback, and handoff.
3. Make D12 create only the selected target, return the created worktree path and immutable context, and block mismatches before entering it.
4. Record every D12 worker call and main-orchestrator invocation with exact-or-null token counts and honest coverage.
5. Reconcile pruned or competing Git branches without reopening the Session Gate's completed choice, then prove the entered workspace matches it.

## RED

Five controls covered conflicting in-process sessions, a D12 metadata mismatch, retries/fallback/resume token accounting, pruned worktree recreation beside a similar branch, and declined/sandbox in-place fallback. Result: **0/5 passed**.

Observed failures included:

- Existing isolation was reused without selecting the matching manifest entry or preserving its workflow ID.
- D12 validated only path existence and could accept another workflow or a copied manifest path.
- No worker/orchestrator token-cost contract existed.
- Slug-order matching could recreate the wrong branch or target.
- In-place fallbacks returned generic readiness without selected-session context.

## GREEN/REFACTOR

Using Git Worktrees now treats the selected session as authority for identity and Git as authority for resumability. D12 carries and echoes the unchanged workflow/main-manifest context, creates only the selected target, and is validated before `cd`. Every outcome rereads the main manifest and returns the workspace, workflow, decision path, baseline, and phase token report.

The first GREEN pruned-worktree evaluation found that an older Step 0.5 rule still asked the human to reselect when another slug-similar branch existed. Exact selected targets now win, unrelated matches are only reported, and D12 owns pruned recreation. The scenario passed after refactor.

## Final result

Five fresh-context evaluations passed after refactor. Result: **5/5 passed**.
