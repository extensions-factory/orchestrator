#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

check() {
  grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }
}

before() {
  local first second
  first="$(grep -nF -- "$2" "$1" | head -n1 | cut -d: -f1 || true)"
  second="$(grep -nF -- "$3" "$1" | head -n1 | cut -d: -f1 || true)"
  [[ -n "$first" && -n "$second" && "$first" -lt "$second" ]] || {
    echo "[FAIL] $1 must place '$2' before '$3'"
    fail=1
  }
}

DISCOVERY="$ROOT/skills/project-kickoff/templates/discovery-template.md"
CONSTITUTION="$ROOT/skills/project-kickoff/templates/constitution-template.md"
TOOL="$ROOT/skills/project-kickoff/templates/tool-instruction-template.md"
RETRO="$ROOT/skills/sprint-retrospective/templates/retrospective-template.md"
COMPANION="$ROOT/skills/brainstorming/templates/document-companion-template.html"
FRAME="$ROOT/skills/visual-companion/templates/frame-template.html"
PLAN_COMPANION="$ROOT/skills/writing-plans/templates/plan-companion-template.html"
PLAN_SAMPLE="$ROOT/docs/superpowers/template-samples/plan-sample.html"
WRITING_PLANS="$ROOT/skills/writing-plans/SKILL.md"

check "$DISCOVERY" "## Review at a glance"
check "$DISCOVERY" "**Decision needed:**"
before "$DISCOVERY" "## Recommendation" "## Evidence"

check "$CONSTITUTION" "## Project at a glance"
check "$CONSTITUTION" "## Required commands"
before "$CONSTITUTION" "## Required commands" "## Standards"

check "$TOOL" "# <Tool> Instructions"
check "$TOOL" "## Before changing code"

check "$RETRO" "## Review at a glance"
check "$RETRO" "**Decision needed:**"
before "$RETRO" "## Approved actions" "## Measured outcomes"

check "$COMPANION" 'href="#main-content"'
check "$COMPANION" '<main id="main-content"'
check "$COMPANION" 'max-width: 75ch'
check "$COMPANION" ':focus-visible'
check "$COMPANION" '@media print'

check "$FRAME" '<html lang="en">'
check "$FRAME" 'href="#main-content"'
check "$FRAME" '<main class="main" id="main-content"'
check "$FRAME" 'class="status-region" role="status" aria-live="polite"'
check "$FRAME" ':focus-visible'

check "$PLAN_COMPANION" '<aside class="outline"'
check "$PLAN_COMPANION" 'id="plan-progress"'
check "$PLAN_COMPANION" 'className = "task-card"'
check "$PLAN_COMPANION" 'classList.add("checkpoint")'
check "$PLAN_COMPANION" '@media print'
check "$PLAN_COMPANION" '<!-- SAMPLE PLAN CONTENT START'
check "$PLAN_COMPANION" 'data-plan-sample'
check "$PLAN_COMPANION" '<h1>Account Lockout Implementation Plan</h1>'
check "$PLAN_COMPANION" '<strong>task_type:</strong> implementation_coding'
check "$PLAN_COMPANION" '<!-- SAMPLE PLAN CONTENT END -->'
check "$PLAN_COMPANION" '{{CONTENT}}'
check "$WRITING_PLANS" 'skills/writing-plans/templates/plan-companion-template.html'
check "$WRITING_PLANS" 'remove the sample plan block'

task_type_count="$(grep -Fc -- '<strong>task_type:</strong>' "$PLAN_SAMPLE" || true)"
[[ "$task_type_count" -eq 3 ]] || {
  echo "[FAIL] $PLAN_SAMPLE must show task_type on all 3 sample tasks"
  fail=1
}

[[ "$fail" -eq 0 ]] || exit 1
echo "PASS test-human-facing-templates"
