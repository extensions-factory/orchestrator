#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
grep -Fq -- "superpowers-orchestrator:dispatch-agent" "$ROOT/skills/brainstorming/SKILL.md" || { echo "[FAIL] brainstorming missing namespaced dispatch-agent note"; fail=1; }
grep -Fq -- "superpowers-orchestrator:dispatch-agent" "$ROOT/skills/executing-plans/SKILL.md" || { echo "[FAIL] executing-plans missing namespaced dispatch-agent note"; fail=1; }
for s in brainstorming executing-plans; do
  grep -Fq -- "riso-tech:orchestrator-split START" "$ROOT/skills/$s/SKILL.md" || { echo "[FAIL] $s edit not fenced"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "PASS test-orchestrator-notes"
exit $fail
