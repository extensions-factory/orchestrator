#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/requesting-code-review/SKILL.md"
README="$ROOT/skills/requesting-code-review/README.md"
PROMPT="$ROOT/skills/requesting-code-review/prompts/code-reviewer.md"
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
check "$SKILL" '`brainstorming.scope`, `brainstorming.exclusions`, and `brainstorming.acceptance_criteria`'
check "$SKILL" 'exact approved decision snapshot'
check "$SKILL" 'exact plan path and content hash'
check "$SKILL" 'Every D14, D15, and D17 request'
check "$SKILL" 'stale_input'

check "$SKILL" '`implementation_defect`'
check "$SKILL" '`decision_deviation`'
check "$SKILL" '`decision_change_proposal`'
check "$SKILL" 'actual effect, not its severity or label'
check "$SKILL" 'Only implementation defects and decision deviations'
check "$SKILL" 'Brainstorming Human Gate'
check "$SKILL" "Writing Plans' Final build decision gate"
check "$SKILL" 'D14/D15/D17 remain read-only'
check "$SKILL" 'revalidate every completed task'

check "$SKILL" '.superpowers/runs/<workflow-id>/requesting-code-review-token-cost.jsonl'
check "$SKILL" 'D14, D15, and D17'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'caller execution ledger'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'usage becomes visible only after this turn completes'
check "$SKILL" 'measured records / total records'
check "$SKILL" 'input/output field coverage'

for value in '[DECISION_RECORD]' '[DECISION_SNAPSHOT]' '[PLAN_FILE]' '[PLAN_HASH]'; do
  check "$PROMPT" "$value"
done
check "$PROMPT" 'Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.'
check "$PROMPT" '`implementation_defect` | `decision_deviation` |'
check "$PROMPT" '`decision_change_proposal`'
check "$PROMPT" '`implementation_fix` | `align_implementation` |'
check "$PROMPT" '`human_decision_required`'

reject "$SKILL" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$README" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$SKILL" 'Phase D'
reject "$README" 'Phase D'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-requesting-code-review-decisions'
exit "$fail"
