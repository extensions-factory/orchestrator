#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/finishing-a-development-branch/SKILL.md"
README="$ROOT/skills/finishing-a-development-branch/README.md"
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
check "$SKILL" '`brainstorming.acceptance_criteria`'
check "$SKILL" 'exact approved decision snapshot'
check "$SKILL" 'exact plan path and content hash'
check "$SKILL" 'clean D17'
check "$SKILL" 'stale_input'

check "$SKILL" '.superpowers/runs/<workflow-id>/50-finish/finish-record.json'
check "$SKILL" '`delivered | not_delivered | unverified`'
check "$SKILL" 'one entry for every approved acceptance criterion'
check "$SKILL" '`all_delivered` is true only when every criterion is `delivered`'
check "$SKILL" 'Tests passing and a clean review do not substitute'
check "$SKILL" 'Do not present the finish-action gate'
check "$SKILL" 'Brainstorming Human Gate'

check "$SKILL" 'exact action selected at this gate'
check "$SKILL" 'Never infer an action from prior conversation'
check "$SKILL" 'write `selected_action`'
check "$SKILL" 'D19 executes only that named action'
check "$SKILL" 'never switches actions automatically'
check "$SKILL" 'new finish-action gate'
check "$SKILL" 'HUMAN_CONFIRMED_DESTRUCTIVE_RELEASE'

check "$SKILL" 'Every D19 and D20 request'
check "$SKILL" 'Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.'
check "$SKILL" '.superpowers/runs/<workflow-id>/finishing-a-development-branch-token-cost.jsonl'
check "$SKILL" 'D19 and D20'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'caller execution ledger'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'usage becomes visible only after this turn completes'
check "$SKILL" 'measured records / total records'
check "$SKILL" 'input/output field coverage'

reject "$SKILL" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$README" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$SKILL" 'Phase E'
reject "$README" 'Phase E'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-finishing-branch-decisions'
exit "$fail"
