#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/sprint-retrospective/SKILL.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
test -f "$SKILL" || { echo "[FAIL] no sprint-retrospective/SKILL.md"; exit 1; }
check "$SKILL" "name: sprint-retrospective"
check "$SKILL" "finishing-a-development-branch"
check "$SKILL" ".superpowers/ledger.jsonl"
check "$SKILL" "total dispatches"
check "$SKILL" "blocked count"
check "$SKILL" "needs_revision loops"
check "$SKILL" "degradation events"
check "$SKILL" "role: agile_coach"
check "$SKILL" "task_type: retrospective_process_improvement"
check "$SKILL" "context.input_artifacts"
check "$SKILL" "writing-skills"
check "$SKILL" "never edit skills directly"
check "$SKILL" "no worker provider"
check "$SKILL" "action items only"
check "$SKILL" "no code changes"
check "$SKILL" "riso-tech:orchestrator-split — new skill, no upstream counterpart"
[ "$fail" -eq 0 ] && echo "PASS test-sprint-retrospective"
exit $fail
