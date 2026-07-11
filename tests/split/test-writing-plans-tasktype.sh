#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/writing-plans/SKILL.md"
fail=0
grep -Fq -- "task_type" "$SKILL" || { echo "[FAIL] template missing task_type field"; fail=1; }
grep -Fq -- "riso-tech:orchestrator-split START" "$SKILL" || { echo "[FAIL] edit not fenced"; fail=1; }
grep -Eqi -- "self-review.*task_type|task_type.*self-review|flag.*task_type" "$SKILL" || { echo "[FAIL] no self-review check for task_type"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS test-writing-plans-tasktype"
exit $fail
