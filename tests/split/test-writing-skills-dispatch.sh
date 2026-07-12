#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/writing-skills/SKILL.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }

check "$SKILL" "dispatch-agent"
check "$SKILL" "software_engineer"
check "$SKILL" "validation checklist"
check "$SKILL" "does not author skill content inline"
check "$SKILL" "riso-tech:orchestrator-split"

[ "$fail" -eq 0 ] && echo "PASS test-writing-skills-dispatch"
exit $fail
