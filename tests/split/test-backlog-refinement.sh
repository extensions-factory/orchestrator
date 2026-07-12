#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/backlog-refinement/SKILL.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
test -f "$SKILL" || { echo "[FAIL] no backlog-refinement/SKILL.md"; exit 1; }
check "$SKILL" "name: backlog-refinement"
check "$SKILL" "docs/superpowers/roadmap.json"
check "$SKILL" "slug, epic, feature, title, description, status, spec, plan, created, completed"
check "$SKILL" "role: product_owner"
check "$SKILL" "task_type: backlog_refinement_prioritization"
check "$SKILL" "dispatch-agent"
check "$SKILL" "ROADMAP.html"
check "$SKILL" "no worker provider"
check "$SKILL" "Never invents scope"
check "$SKILL" "riso-tech:orchestrator-split — new skill, no upstream counterpart"
[ "$fail" -eq 0 ] && echo "PASS test-backlog-refinement"
exit $fail
