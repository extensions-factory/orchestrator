#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/writing-plans/SKILL.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }

check "$SKILL" "riso-tech:orchestrator-split START"
check "$SKILL" "riso-tech:orchestrator-split END"
check "$SKILL" "skills/writing-plans/plan-template.md"
check "$SKILL" "rendering checkboxes as a readable checklist"
check "$SKILL" "## Organize Tasks Under User Stories"
check "$SKILL" "complete vertical slice"
check "$SKILL" "## Foundation Section (Optional)"
check "$SKILL" "US IDs MUST reuse the spec's User Story IDs"
check "$SKILL" "**US-N Checkpoint:**"
check "$SKILL" "**Spec:** \`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md\`"
check "$SKILL" "## Expected Outcome"
check "$SKILL" "**Depends on:** [Task M | Foundation | none]"
check "$SKILL" "**4. Template check:**"
check "$SKILL" "**5. Traceability check:**"
check "$SKILL" "1. Refine — get an independent review pass"
check "$SKILL" "superpowers:requesting-plan-refine"
[ "$fail" -eq 0 ] && echo "PASS test-plan-restructure"
exit $fail
