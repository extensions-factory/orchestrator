#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOOKUP="$ROOT/scripts/model-lookup.sh"
SKILL="$ROOT/skills/dispatch-agent/SKILL.md"
WORKERS="$ROOT/skills/dispatch-agent/references/antigravity-workers.md"
WORKFLOW="$ROOT/docs/orchestrator-workflow.md"
ROUTING="$ROOT/assets/sdlc-model-routing.json"

while IFS=$'\t' read -r task_type rank model; do
  output="$(bash "$LOOKUP" --command "$task_type" "$rank")"
  effort="medium"
  case "$model" in
    *"(High)"*|*"(Thinking)"*) effort="high" ;;
    *"(Low)"*) effort="low" ;;
  esac
  grep -Fqx "agent=antigravity" <<<"$output"
  grep -Fqx "write=true" <<<"$output"
  grep -Fqx "/antigravity:rescue --background --fresh --write --model $model --effort $effort \"<prompt>\"" <<<"$output"
done < <(jq -r '.task_types | to_entries[] | .key as $task | .value.recommended_models[] | select(.provider == "Antigravity CLI") | [$task, .rank, .model] | @tsv' "$ROUTING")

while IFS=$'\t' read -r task_type rank; do
  output="$(bash "$LOOKUP" --command "$task_type" "$rank")"
  grep -Fqx 'agent=claude' <<<"$output"
  grep -Fqx 'write=true' <<<"$output"
done < <(jq -r '.task_types | to_entries[] | .key as $task | .value.recommended_models[] | select(.provider == "Claude Code") | [$task, .rank] | @tsv' "$ROUTING")

grep -Fq '/antigravity:setup' "$SKILL"
grep -Fq '/antigravity:rescue --background --fresh --write --model <model> --effort <effort> "<prompt>"' "$SKILL"
grep -Fq '/antigravity:status' "$SKILL"
grep -Fq '/antigravity:result' "$SKILL"
grep -Fq 'permissionMode: bypassPermissions' "$SKILL"
grep -Fq 'full tool permission' "$WORKERS"
grep -Fq '/antigravity:rescue --background --fresh --write' "$WORKFLOW"
! grep -Fq 'HUMAN relay' "$SKILL"
! grep -Fq 'Human relay' "$WORKFLOW"

echo 'PASS test-antigravity-command'
