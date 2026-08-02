#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/writing-plans/SKILL.md"
README="$ROOT/skills/writing-plans/README.md"
TEMPLATE="$ROOT/skills/writing-plans/templates/plan-template.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for heading in '## Description' '## Inputs' '## Durable Output' '## Human Decisions' '## Handoff'; do
  check "$README" "$heading"
done

check "$SKILL" 'Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace'
check "$SKILL" 'exactly one session entry'
check "$SKILL" '`project_kickoff`, `brainstorming`, and `designing_ui`'
check "$SKILL" 'Human Gate — Final build decision'
check "$SKILL" '`scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`'
check "$SKILL" 'Do not offer Refine or Execute until this approval is recorded'
check "$SKILL" 'return to this gate'
check "$SKILL" 'Before either handoff, reread the selected session entry'

for field in '"writing_plans"' '"workflow_id"' '"scope"' '"exclusions"' '"ordering"' '"files"' '"interfaces"' '"tests"' '"verification"'; do
  check "$README" "$field"
done

check "$SKILL" '.superpowers/runs/<workflow-id>/writing-plans-token-cost.jsonl'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'measured records / total records'
check "$SKILL" 'including same-provider retries and fallbacks'
check "$SKILL" 'input-field and output-field coverage independently'

check "$SKILL" 'Plans must not contain implementation or test source-code blocks'
check "$TEMPLATE" 'No source code belongs in this plan'
reject "$SKILL" 'Complete code in every step'
reject "$SKILL" 'code blocks required for code steps'
reject "$TEMPLATE" '**Step 3: Write minimal implementation**'
reject "$TEMPLATE" 'def test_specific_behavior'

reject "$SKILL" 'Phase C'
reject "$README" 'Phase C'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-writing-plans-decisions'
exit "$fail"
