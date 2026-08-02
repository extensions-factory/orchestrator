#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/brainstorming/SKILL.md"
README="$ROOT/skills/brainstorming/README.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for heading in '## Description' '## Inputs' '## Durable Output' '## Human Decisions' '## Handoff'; do
  check "$README" "$heading"
done

check "$SKILL" 'Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace'
check "$SKILL" 'Human Gate — Design decisions'
check "$SKILL" '`problem`, `scope`, `exclusions`, `approach`, and `acceptance_criteria`'
check "$SKILL" 'Do not present design sections or dispatch D9 until this approval is recorded'
check "$SKILL" 'return to this gate'
check "$SKILL" 'exactly one session entry'
check "$SKILL" 'all five decision fields'
check "$SKILL" '`exclusions` may be empty only when the human explicitly approves none'
check "$SKILL" '"Approve decision bundle?"'
check "$SKILL" 'Before handoff, reread the selected session entry'
check "$SKILL" 'Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace'

for field in '"brainstorming"' '"workflow_id"' '"problem"' '"scope"' '"exclusions"' '"approach"' '"acceptance_criteria"'; do
  check "$README" "$field"
done

check "$SKILL" '.superpowers/runs/<workflow-id>/brainstorming-token-cost.jsonl'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" '`turn` is the D9 request envelope turn'
check "$SKILL" '`attempt` starts at 1'
check "$SKILL" 'measured records / total records'

reject "$SKILL" 'Phase B'
reject "$README" 'Phase B'
reject "$README" '../../docs/orchestrator-workflow.md'

[ "$fail" -eq 0 ] && echo 'PASS test-brainstorming-decisions'
exit "$fail"
