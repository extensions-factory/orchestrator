#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/requesting-plan-refine/SKILL.md"
README="$ROOT/skills/requesting-plan-refine/README.md"
PROMPT="$ROOT/skills/requesting-plan-refine/prompts/plan-reviewer.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for heading in '## Description' '## Inputs' '## Durable Output' '## Human Decisions' '## Handoff'; do
  check "$README" "$heading"
done

check "$SKILL" 'Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace'
check "$SKILL" 'exactly one session entry'
check "$SKILL" '`writing_plans.workflow_id`'
check "$SKILL" '`scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`'
check "$SKILL" 'preserve every session entry'
check "$SKILL" 'exact plan and spec paths from the current Writing Plans handoff'
check "$SKILL" 'inside the current workspace root'
check "$SKILL" 'Before handoff, reread the selected session entry'
check "$SKILL" 'redispatch D11'

check "$PROMPT" '## Approved Decision Record'
check "$PROMPT" 'decision_deviation'
check "$PROMPT" 'decision_change_proposal'
check "$PROMPT" 'align_plan'
check "$PROMPT" 'human_decision_required'
check "$PROMPT" 'Do not edit the plan, the spec, the manifest, or any other file'
check "$PROMPT" '{WORKSPACE_ROOT}'
check "$PROMPT" 'approved value'
check "$PROMPT" 'observed plan value'

check "$SKILL" '.superpowers/runs/<workflow-id>/requesting-plan-refine-token-cost.jsonl'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'measured records / total records'

reject "$PROMPT" 'missing code in a code step'
reject "$SKILL" 'docs/superpowers/plans/'
reject "$SKILL" 'docs/superpowers/specs/'
reject "$README" 'plan-refine/findings.md'
reject "$SKILL" 'Phase C'
reject "$README" 'Phase C'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-requesting-plan-refine-decisions'
exit "$fail"
