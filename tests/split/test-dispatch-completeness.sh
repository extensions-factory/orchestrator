#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }
fenced(){ grep -Fq -- "riso-tech:orchestrator-split START" "$1" || { echo "[FAIL] $1 edit not fenced"; fail=1; }; }

# US-1: SM identity injection
US="$ROOT/skills/using-superpowers/SKILL.md"
check "$US" "You are the Orchestrator (Scrum Master)"
fenced "$US"

[ "$fail" -eq 0 ] && echo "PASS test-dispatch-completeness"
exit $fail
