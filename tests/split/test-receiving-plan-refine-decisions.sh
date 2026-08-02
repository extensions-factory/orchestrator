#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/receiving-plan-refine/SKILL.md"
README="$ROOT/skills/receiving-plan-refine/README.md"
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
check "$SKILL" 'exact handed-off plan, spec, and findings paths'
check "$SKILL" 'compare the current hashes with the handed-off hashes before reading findings'
check "$SKILL" 'Hash the findings file before reading it'
check "$SKILL" 'resolution-<turn>.md'
check "$SKILL" 'last completed after-plan hash'
check "$SKILL" 'allow its verified intended result'
check "$SKILL" 'Before each plan edit, durably record `applying`'
check "$SKILL" 'HTML hash'
check "$SKILL" 'stable `handoff_id`'
check "$SKILL" 'downstream idempotency key'

check "$SKILL" '`plan_defect`'
check "$SKILL" '`decision_deviation`'
check "$SKILL" '`decision_change_proposal`'
check "$SKILL" 'regardless of its reported type or route'
check "$SKILL" '`human_decision_required`'
check "$SKILL" "Writing Plans' Final build decision gate"
check "$SKILL" 'never edits the manifest'
check "$SKILL" 'reread the selected session entry'

check "$SKILL" '.superpowers/runs/<workflow-id>/receiving-plan-refine-token-cost.jsonl'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'This phase dispatches no workers'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'usage becomes visible only after this turn completes'
check "$SKILL" 'measured records / total records'

reject "$SKILL" 'If it holds up: fix it directly in the plan file'
reject "$README" 'plan-refine/findings.md'
reject "$SKILL" 'Phase C'
reject "$README" 'Phase C'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-receiving-plan-refine-decisions'
exit "$fail"
