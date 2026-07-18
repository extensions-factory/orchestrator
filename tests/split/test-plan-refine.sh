#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REQUEST="$ROOT/skills/requesting-plan-refine/SKILL.md"
RECEIVE="$ROOT/skills/receiving-plan-refine/SKILL.md"
TEMPLATE="$ROOT/skills/requesting-plan-refine/plan-reviewer.md"
REF="$ROOT/../active/skills/requesting-plan-refine/plan-reviewer.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }
absent(){ ! grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 must not contain: $2"; fail=1; }; }

test -f "$REQUEST" || { echo "[FAIL] no requesting-plan-refine/SKILL.md"; exit 1; }
test -f "$RECEIVE" || { echo "[FAIL] no receiving-plan-refine/SKILL.md"; exit 1; }
cmp -s "$REF" "$TEMPLATE" || { echo "[FAIL] plan-reviewer.md differs from active"; fail=1; }
check "$REQUEST" "riso-tech:orchestrator-split — new skill, no upstream counterpart"
check "$REQUEST" "Dispatch the plan reviewer via \`superpowers-orchestrator:dispatch-agent\`"
check "$REQUEST" "role: tech_lead"
check "$REQUEST" "task_type: code_review_quality"
check "$REQUEST" ".superpowers/ledger.jsonl"
check "$REQUEST" "provider diversity"
check "$REQUEST" "[plan-reviewer.md](plan-reviewer.md)"
absent "$REQUEST" "START SDLC: code_review_quality"
absent "$REQUEST" "DISPATCH: role=Plan Reviewer"
check "$RECEIVE" "riso-tech:orchestrator-split — new skill, no upstream counterpart"
check "$RECEIVE" "Inline validation:"
check "$RECEIVE" "VALIDATE-equivalent judgment call"
check "$RECEIVE" "never dispatched"
absent "$RECEIVE" "START SDLC: code_review_quality"
absent "$RECEIVE" "DISPATCH: inline"
[ "$fail" -eq 0 ] && echo "PASS test-plan-refine"
exit $fail
