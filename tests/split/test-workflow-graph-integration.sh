#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKFLOW="$ROOT/docs/orchestrator-workflow.md"
SR="$ROOT/skills/sprint-retrospective/SKILL.md"
WS="$ROOT/skills/writing-skills/SKILL.md"
BR="$ROOT/skills/backlog-refinement/SKILL.md"
TC="$ROOT/tests/split/test-dispatch-completeness.sh"
fail=0

check() {
  local needle="$1"
  local label="$2"
  if grep -Fq -- "$needle" "$WORKFLOW"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

check_file() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if grep -Fq -- "$needle" "$file"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

before() {
  local first second
  first="$(awk -v needle="$1" 'index($0, needle) { print NR; exit }' "$WORKFLOW")"
  second="$(awk -v needle="$2" 'index($0, needle) { print NR; exit }' "$WORKFLOW")"
  if [[ -n "$first" && -n "$second" && "$first" -lt "$second" ]]; then
    echo "[PASS] $3"
  else
    echo "[FAIL] $3"
    fail=1
  fi
}

check '- `◆ Dn` — dispatch point; always routes through `superpowers-orchestrator:dispatch-agent`' 'dispatch legend is unchanged'
check '- `○` — orchestrator action performed inline' 'inline legend is unchanged'
check '- `◇` — human approval gate' 'human-gate legend is unchanged'
check '- `↻` — loop back to an earlier step' 'loop legend is unchanged'
check '○ collect fresh graph matches inline; missing, stale, malformed, or no matches → normal file exploration' 'brainstorming shows the inline collect note'
check '◆ D20 refresh knowledge graph [conditional]' 'phase E shows the conditional refresh dispatch'
check 'role: technical_writer' 'workflow shows the refresh role'
check 'task_type: documentation_knowledge_transfer' 'workflow shows the refresh task type'
check '◆ D21 process review' 'retrospective dispatch is renumbered'
check '◆ D22 edit skill' 'skill-edit dispatch is renumbered'
check '◆ D23 propose ordering and grooming' 'backlog dispatch is renumbered'
before '◆ D19 execute the selected finish path' '◆ D20 refresh knowledge graph [conditional]' 'refresh dispatch appears after D19'

d20_count="$(grep -Fc -- '◆ D20 ' "$WORKFLOW")"
if [[ "$d20_count" -eq 1 ]]; then
  echo "[PASS] D20 is unique"
else
  echo "[FAIL] D20 is unique"
  fail=1
fi

# B1: skill files carry their new dispatch IDs
check_file "$SR" '**Dispatch:** `D21`' 'sprint-retrospective carries D21'
check_file "$WS" '**Dispatch:** `D22`' 'writing-skills carries D22'
check_file "$BR" '**Dispatch:** `D23`' 'backlog-refinement carries D23'

# B2: test-dispatch-completeness.sh pins the updated IDs and adds D20 assertion
check_file "$TC" 'check_dispatch "$SR" D21' 'dispatch-completeness updated SR to D21'
check_file "$TC" 'check_dispatch "$WS" D22' 'dispatch-completeness updated WS to D22'
check_file "$TC" 'check_dispatch "$BR" D23' 'dispatch-completeness updated BR to D23'
check_file "$TC" 'check_dispatch "$FB" D20' 'dispatch-completeness has new D20 for finishing-branch'

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "PASS test-workflow-graph-integration"
