#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/using-git-worktrees/SKILL.md"
README="$ROOT/skills/using-git-worktrees/README.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for heading in '## Description' '## Inputs' '## Durable Output' '## Human Decisions' '## Handoff'; do
  check "$README" "$heading"
done

check "$SKILL" 'Read `main:docs/superpower/manifest.json`'
check "$SKILL" 'exactly one session entry'
check "$SKILL" '`workspace.type` and `workspace.target`'
check "$SKILL" 'preserve every other session entry'
check "$SKILL" 'Git branches and worktrees are the source of truth'
check "$SKILL" 'continue with the exact selected branch'
check "$SKILL" 'let D12 recreate that branch at the exact selected target'
check "$SKILL" 'DECISION_RECORD=main:docs/superpower/manifest.json'
check "$SKILL" 'WORKFLOW_ID=<caller-workflow-id>'
check "$SKILL" 'must not initialize or replace either value'

check "$SKILL" 'created worktree path'
check "$SKILL" 'role: devops_engineer'
check "$SKILL" 'task_type: workspace_setup'
check "$SKILL" 'pass `WORKFLOW_ID` and `DECISION_RECORD`'
check "$SKILL" 'return both values unchanged'
check "$SKILL" 'mismatch is blocked'
check "$SKILL" 'reread the main manifest after entering the workspace'

check "$SKILL" '.superpowers/runs/<workflow-id>/using-git-worktrees-token-cost.jsonl'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'usage becomes visible only after this turn completes'
check "$SKILL" 'measured records / total records'

reject "$SKILL" "today's behavior"
reject "$SKILL" 'workspace-local manifest'
reject "$README" 'workspace-local manifest'
reject "$SKILL" 'Phase D'
reject "$README" 'Phase D'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-using-git-worktrees-decisions'
exit "$fail"
