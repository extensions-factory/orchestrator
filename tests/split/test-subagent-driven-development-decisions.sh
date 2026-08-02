#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/subagent-driven-development/SKILL.md"
README="$ROOT/skills/subagent-driven-development/README.md"
IMPLEMENTER="$ROOT/skills/subagent-driven-development/prompts/implementer-prompt.md"
REVIEWER="$ROOT/skills/subagent-driven-development/prompts/task-reviewer-prompt.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for heading in '## Description' '## Inputs' '## Durable Output' '## Human Decisions' '## Handoff'; do
  check "$README" "$heading"
done

check "$SKILL" 'Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace'
check "$SKILL" 'exactly one session entry'
check "$SKILL" '`writing_plans.workflow_id`'
check "$SKILL" '`scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`'
check "$SKILL" '`brainstorming.scope`, `brainstorming.exclusions`, and `brainstorming.acceptance_criteria`'
check "$SKILL" 'preserve every other session entry'
check "$SKILL" 'exact approved decision snapshot'
check "$SKILL" 'exact plan path and content hash'
check "$SKILL" 'Every D13–D18 request'
check "$SKILL" 'stale_input'

check "$SKILL" '`decision_change_proposal`'
check "$SKILL" 'Brainstorming Human Gate'
check "$SKILL" "Writing Plans' Final build decision gate"
check "$SKILL" 'do not edit code, the plan, or the manifest'
check "$SKILL" 'revalidate every completed task'

check "$SKILL" '.superpowers/runs/<workflow-id>/subagent-driven-development-progress.jsonl'
check "$SKILL" 'Git history and the current worktree are authoritative'
check "$SKILL" '.superpowers/runs/<workflow-id>/subagent-driven-development-token-cost.jsonl'
check "$SKILL" 'D13, D16, and D18'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'nested Requesting Code Review usage'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'usage becomes visible only after this turn completes'
check "$SKILL" 'measured records / total records'

for prompt in "$IMPLEMENTER" "$REVIEWER"; do
  check "$prompt" '[DECISION_RECORD]'
  check "$prompt" '[DECISION_SNAPSHOT]'
  check "$prompt" '[PLAN_FILE]'
  check "$prompt" '[PLAN_HASH]'
  check "$prompt" 'Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.'
  check "$prompt" 'decision_change_proposal'
done

reject "$SKILL" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$README" '.superpowers/runs/<workflow-id>/manifest.json'
reject "$SKILL" 'Phase D'
reject "$README" 'Phase D'
reject "$README" '../../docs/orchestrator-workflow.md'

[[ "$fail" -eq 0 ]] && echo 'PASS test-subagent-driven-development-decisions'
exit "$fail"
