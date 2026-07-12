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

# US-2: full 16-role persona list in dispatch-agent
DA="$ROOT/skills/dispatch-agent/SKILL.md"
for role in product_owner scrum_master software_engineer tech_lead qa_engineer ux_ui_designer devops_engineer security_engineer sre engineering_manager product_manager technical_writer business_analyst data_analyst agile_coach stakeholder; do
  grep -Fq -- "\`$role\`" "$DA" || { echo "[FAIL] dispatch-agent missing persona: $role"; fail=1; }
done
persona_count=$(grep -cE '^- `[a-z_]+`' "$DA" || true)
[ "$persona_count" -eq 16 ] || { echo "[FAIL] expected 16 persona lines, got $persona_count"; fail=1; }

# US-3: writing-plans dispatches plan authorship
WP="$ROOT/skills/writing-plans/SKILL.md"
check "$WP" "dispatch-agent"
check "$WP" "tech_lead"
fenced "$WP"

# US-4: finishing-a-development-branch dispatches to devops_engineer
FB="$ROOT/skills/finishing-a-development-branch/SKILL.md"
check "$FB" "dispatch-agent"
check "$FB" "devops_engineer"
fenced "$FB"

[ "$fail" -eq 0 ] && echo "PASS test-dispatch-completeness"
exit $fail
