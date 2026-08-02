#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/executing-plans/SKILL.md"
README="$ROOT/skills/executing-plans/README.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for heading in '## Description' '## Inputs' '## Durable Output' '## Human Decisions' '## Handoff'; do
  check "$README" "$heading"
done

check "$SKILL" 'Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace'
check "$SKILL" 'exactly one session entry'
check "$SKILL" '`workspace.type` and `workspace.target`'
check "$SKILL" 'preserve every other session entry'
check "$SKILL" '`writing_plans.workflow_id`'
check "$SKILL" '`scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`'
check "$SKILL" '`brainstorming.scope`, `brainstorming.exclusions`, and `brainstorming.acceptance_criteria`'
check "$SKILL" 'exact approved decision snapshot'
check "$SKILL" 'exact plan path and content hash'

check "$SKILL" 'Before each task'
check "$SKILL" 'before Git bookkeeping'
check "$SKILL" 'after verification'
check "$SKILL" 'before the finishing handoff'
check "$SKILL" 'stale_input'

check "$SKILL" '`decision_change_proposal`'
check "$SKILL" 'Brainstorming Human Gate'
check "$SKILL" "Writing Plans' Final build decision gate"
check "$SKILL" 'do not edit code, the plan, or the manifest'
check "$SKILL" 'revalidate every completed task'

check "$SKILL" '.superpowers/runs/<workflow-id>/executing-plans-progress.jsonl'
check "$SKILL" 'Git history and the current worktree are authoritative'
check "$SKILL" '.superpowers/runs/<workflow-id>/executing-plans-token-cost.jsonl'
check "$SKILL" 'This mode dispatches no workers'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'usage becomes visible only after this turn completes'
check "$SKILL" 'measured records / total records'
check "$SKILL" 'input/output field coverage'
check "$SKILL" 'nested Finishing a Development Branch usage'

reject "$SKILL" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$README" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$SKILL" 'Phase D'
reject "$README" 'Phase D'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-executing-plans-decisions'
exit "$fail"
