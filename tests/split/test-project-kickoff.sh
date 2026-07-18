#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/project-kickoff/SKILL.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
test -f "$SKILL" || { echo "[FAIL] no project-kickoff/SKILL.md"; exit 1; }
check "$SKILL" "name: project-kickoff"
check "$SKILL" "superpowers-orchestrator:dispatch-agent"
check "$SKILL" "business_analyst"
check "$SKILL" "discovery_research"
check "$SKILL" "devops_engineer"
check "$SKILL" "workspace_setup"
check "$SKILL" "tech_lead"
check "$SKILL" "architecture_design"
check "$SKILL" "riso-tech:orchestrator-split — new skill, no upstream counterpart"
check "$SKILL" "Redirect guard"
check "$SKILL" "Red Flags"
[ "$fail" -eq 0 ] && echo "PASS test-project-kickoff"
exit $fail
