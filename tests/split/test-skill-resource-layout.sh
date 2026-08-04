#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

expect() {
  local path="$1"
  if [[ -f "$ROOT/$path" ]]; then
    echo "[PASS] $path"
  else
    echo "[FAIL] missing: $path"
    fail=1
  fi
}

templates=(
  skills/brainstorming/templates/document-companion-template.html
  skills/visual-companion/templates/frame-template.html
  skills/brainstorming/templates/spec-template.md
  skills/finishing-a-development-branch/templates/pr-body-template.md
  skills/project-kickoff/templates/constitution-template.md
  skills/project-kickoff/templates/ci-stub-templates.md
  skills/project-kickoff/templates/discovery-template.md
  skills/project-kickoff/templates/tool-instruction-template.md
  skills/sprint-retrospective/templates/retrospective-template.md
  skills/subagent-driven-development/templates/task-report-template.md
  skills/writing-plans/templates/plan-template.md
  skills/writing-plans/templates/plan-companion-template.html
)

prompts=(
  skills/brainstorming/prompts/spec-document-reviewer-prompt.md
  skills/requesting-code-review/prompts/code-reviewer.md
  skills/requesting-plan-refine/prompts/plan-reviewer.md
  skills/subagent-driven-development/prompts/implementer-prompt.md
  skills/subagent-driven-development/prompts/task-reviewer-prompt.md
  skills/writing-plans/prompts/plan-document-reviewer-prompt.md
)

for path in "${templates[@]}" "${prompts[@]}"; do expect "$path"; done

if find "$ROOT/skills" -mindepth 2 -maxdepth 2 -type f \
  \( -name '*-template.*' -o -name '*-prompt.md' \) | grep -q .; then
  echo "[FAIL] flat skill template or prompt remains"
  fail=1
else
  echo "[PASS] no flat skill templates or prompts"
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "PASS test-skill-resource-layout"
