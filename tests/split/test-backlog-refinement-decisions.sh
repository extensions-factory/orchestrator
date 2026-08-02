#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/backlog-refinement/SKILL.md"
README="$ROOT/skills/backlog-refinement/README.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for heading in '## Description' '## Inputs' '## Durable Output' '## Human Decisions' '## Handoff'; do
  check "$README" "$heading"
done

check "$SKILL" 'Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace'
check "$SKILL" 'exactly one session entry'
check "$SKILL" '`workspace.type` and `workspace.target`'
check "$SKILL" 'preserve every other session entry'
check "$SKILL" '`writing_plans.workflow_id`'
check "$SKILL" 'approved decision evidence for each affected item'
check "$SKILL" 'exact roadmap content hash'
check "$SKILL" 'Every D23 request'
check "$SKILL" 'Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.'

check "$SKILL" 'published token-cost baselines'
check "$SKILL" 'measured totals and record/input/output coverage'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'not the sole priority signal'
check "$SKILL" 'unavailable or partial'

check "$SKILL" '`item_id`, current and proposed position'
check "$SKILL" 'decision-record references'
check "$SKILL" 'token-baseline references'
check "$SKILL" 'confidence and unavailable evidence'
check "$SKILL" 'Return only a backlog proposal; never edit `roadmap.json`, `ROADMAP.html`, or product files.'
check "$SKILL" 'restore those exact bytes, reject its response'

check "$SKILL" '.superpowers/runs/<workflow-id>/70-backlog-refinement/refinement-record.json'
check "$SKILL" 'before/after order'
check "$SKILL" 'every addition and grooming-field change'
check "$SKILL" '`approve | revise | reject`'
check "$SKILL" 'before applying approved changes'
check "$SKILL" 'stale_input'
check "$SKILL" 'new proposal and human approval'
check "$SKILL" 'Apply only the exact approved diff'

check "$SKILL" '.superpowers/runs/<workflow-id>/backlog-refinement-token-cost.jsonl'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'historical baseline records are evidence, not current token cost'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'usage becomes visible only after this turn completes'
check "$SKILL" 'measured records / total records'
check "$SKILL" 'input/output field coverage'

reject "$SKILL" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$README" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$SKILL" 'Phase G'
reject "$README" 'Phase G'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-backlog-refinement-decisions'
exit "$fail"
