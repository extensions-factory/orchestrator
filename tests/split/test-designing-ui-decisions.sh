#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/designing-ui/SKILL.md"
README="$ROOT/skills/designing-ui/README.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for heading in '## Description' '## Inputs' '## Durable Output' '## Human Decisions' '## Handoff'; do
  check "$README" "$heading"
done

check "$SKILL" 'Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace'
check "$SKILL" 'Human Gate — UI decisions and constraints'
check "$SKILL" '`platform`, `layout`, `source`, `component_approach`, and `constraints`'
check "$SKILL" 'Do not write planning inputs or hand off until this approval is recorded'
check "$SKILL" 'return to this gate'
check "$SKILL" 'exactly one session entry'
check "$SKILL" 'Before handoff, reread the selected session entry'

for field in '"designing_ui"' '"workflow_id"' '"platform"' '"layout"' '"source"' '"component_approach"' '"constraints"'; do
  check "$README" "$field"
done

check "$SKILL" '.superpowers/runs/<workflow-id>/designing-ui-token-cost.jsonl'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'measured records / total records'

reject "$SKILL" 'Phase B'
reject "$README" 'Phase B'
reject "$README" 'Standalone, direct-invoke skill'
reject "$README" 'not wired into'

[ "$fail" -eq 0 ] && echo 'PASS test-designing-ui-decisions'
exit "$fail"
