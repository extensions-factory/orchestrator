#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/writing-plans/SKILL.md"
TEMPLATE="$ROOT/skills/writing-plans/templates/plan-template.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }

check "$SKILL" "riso-tech:orchestrator-split START"
check "$SKILL" "riso-tech:orchestrator-split END"
check "$SKILL" "skills/writing-plans/templates/plan-template.md"
check "$SKILL" "rendering checkboxes as a readable checklist"
check "$SKILL" "## Organize Tasks Under User Stories"
check "$SKILL" "complete vertical slice"
check "$SKILL" "## Foundation Section (Optional)"
check "$SKILL" "US IDs MUST reuse the spec's User Story IDs"
check "$SKILL" "**US-N Checkpoint:**"
check "$SKILL" "**Spec:** \`docs/superpowers/features/<feature-slug>/design.md\`"
check "$SKILL" "## Expected Outcome"
check "$TEMPLATE" "**Depends on:** [Task M | Foundation | none]"
check "$SKILL" "**4. Template check:**"
check "$SKILL" "**5. Traceability check:**"
check "$SKILL" "1. Refine — get an independent review pass"
check "$SKILL" "superpowers-orchestrator:requesting-plan-refine"
check "$TEMPLATE" "**task_type:**"

task_schema_count="$(grep -Fhc -- "### Task N: [Component Name]" "$SKILL" "$TEMPLATE" | awk '{ total += $1 } END { print total }')"
[[ "$task_schema_count" -eq 1 ]] || {
  echo "[FAIL] task schema must have one source of truth; found $task_schema_count copies"
  fail=1
}
[ "$fail" -eq 0 ] && echo "PASS test-plan-restructure"
exit $fail
