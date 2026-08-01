#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

active=(
  "$ROOT/skills/dispatch-agent"
  "$ROOT/skills/brainstorming"
  "$ROOT/skills/project-kickoff"
  "$ROOT/skills/writing-plans"
  "$ROOT/skills/requesting-plan-refine"
  "$ROOT/skills/receiving-plan-refine"
  "$ROOT/skills/subagent-driven-development"
  "$ROOT/skills/requesting-code-review"
  "$ROOT/skills/finishing-a-development-branch"
  "$ROOT/skills/sprint-retrospective"
  "$ROOT/skills/backlog-refinement"
  "$ROOT/hooks/pre-agent-dispatch"
  "$ROOT/hooks/post-agent-dispatch"
)

absent() {
  local needle="$1"
  if grep -R -Fq -- "$needle" "${active[@]}"; then
    echo "[FAIL] legacy path remains: $needle"
    fail=1
  else
    echo "[PASS] legacy path absent: $needle"
  fi
}

present() {
  local file="$1" needle="$2" label="$3"
  if grep -Fq -- "$needle" "$file"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

absent '.superpowers/<task>'
absent '.superpowers/ledger.jsonl'
absent '.superpowers/sdd'
absent '.superpowers/plan-refine'
absent '.superpowers/brainstorm'
absent 'docs/superpowers/specs/YYYY-MM-DD'
absent 'docs/superpowers/plans/YYYY-MM-DD'

present "$ROOT/skills/dispatch-agent/SKILL.md" \
  '.superpowers/runs/<workflow-id>/<phase-directory>/<task>/turns/<NNN>-<purpose>/' \
  'dispatch skill owns semantic turn directory'
present "$ROOT/skills/dispatch-agent/SKILL.md" \
  'scripts/run-paths.mjs' \
  'dispatch skill initializes and resolves runs'
present "$ROOT/hooks/pre-agent-dispatch" \
  'request.json' \
  'pre-dispatch hook names short request artifact'
present "$ROOT/hooks/post-agent-dispatch" \
  'ledger.jsonl' \
  'post-dispatch hook names run ledger'
present "$ROOT/skills/brainstorming/SKILL.md" \
  'docs/superpowers/features/<feature-slug>/design.md' \
  'design documents use feature directory'
present "$ROOT/skills/writing-plans/SKILL.md" \
  'docs/superpowers/features/<feature-slug>/plan.md' \
  'plans use feature directory'
present "$ROOT/scripts/run-paths.mjs" \
  'assets/run-index-template.md' \
  'run index uses its template'
present "$ROOT/skills/dispatch-agent/SKILL.md" \
  'assets/ledger-entry.schema.json' \
  'ledger uses its schema'
present "$ROOT/skills/brainstorming/SKILL.md" \
  'assets/roadmap.schema.json' \
  'roadmap uses its schema'
present "$ROOT/skills/writing-plans/SKILL.md" \
  'templates/plan-companion-template.html' \
  'plan companion uses the plan review template'
present "$ROOT/skills/project-kickoff/SKILL.md" \
  'templates/discovery-template.md' \
  'discovery uses its template'
present "$ROOT/skills/project-kickoff/SKILL.md" \
  'templates/constitution-template.md' \
  'constitution uses its template'
present "$ROOT/skills/project-kickoff/SKILL.md" \
  'templates/tool-instruction-template.md' \
  'tool instructions use their template'
present "$ROOT/skills/subagent-driven-development/SKILL.md" \
  'templates/task-report-template.md' \
  'task reports use their template'
present "$ROOT/skills/finishing-a-development-branch/SKILL.md" \
  'run-paths.mjs phase --root <repo-root> --run <workflow-id> --phase finish' \
  'PR body uses the run finish phase'
present "$ROOT/skills/sprint-retrospective/SKILL.md" \
  'templates/retrospective-template.md' \
  'retrospective uses its template'

[[ "$fail" -eq 0 ]] || exit 1
echo "PASS test-run-scoped-file-layout"
