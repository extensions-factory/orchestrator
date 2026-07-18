#!/usr/bin/env bash
#
# model-lookup.sh
#
# Look up recommended models for an SDLC task type or quick alias.
#
# Usage:
#   ./scripts/model-lookup.sh write_plan
#   ./scripts/model-lookup.sh sprint_planning
#   ./scripts/model-lookup.sh --list
#   ./scripts/model-lookup.sh --command <task_type> [rank]
#
# Requires: bash, jq.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROUTING_FILE="$REPO_ROOT/assets/sdlc-model-routing.json"

usage() {
  sed -n '/^# Usage:/,/^$/s/^# \{0,1\}//p' "$0"
  exit "${1:-0}"
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

command -v jq >/dev/null || die "jq not found in PATH"
[[ -f "$ROUTING_FILE" ]] || die "routing file not found: $ROUTING_FILE"

resolve_task_type() {
  jq -r --arg query "$1" '
    if .task_types[$query] then $query
    elif .quick_lookup[$query] then .quick_lookup[$query]
    else empty end
  ' "$ROUTING_FILE"
}

emit_command() {
  local task_type="$1" rank="${2:-1}"
  local row provider model agent effort
  row="$(jq -r --arg task_type "$task_type" --argjson rank "$rank" '
    .task_types[$task_type].recommended_models[]
    | select(.rank == $rank)
    | [.provider, .model]
    | @tsv
  ' "$ROUTING_FILE")"
  [[ -n "$row" ]] || die "no rank $rank entry for task type: $task_type"
  provider="${row%%$'\t'*}"
  model="${row#*$'\t'}"

  case "$provider" in
    "Codex")           agent="codex" ;;
    "Claude Code")     agent="claude" ;;
    "Antigravity CLI") agent="antigravity" ;;
    *) die "unknown provider: $provider" ;;
  esac

  effort="medium"
  case "$model" in
    *"(High)"*|*"(Thinking)"*|*sol*) effort="high" ;;
    *"(Low)"*|*mini*|*haiku*)        effort="low" ;;
  esac

  echo "agent=$agent"
  echo "model=$model"
  echo "effort=$effort"
  case "$agent" in
    codex)
      case "$task_type" in
        code_review_quality)
          echo "write=false"
          echo "/codex:review --wait --model $model --base <base_sha>"
          ;;
        security_review)
          echo "write=false"
          echo "/codex:adversarial-review --wait --model $model --base <base_sha> \"<security focus>\""
          ;;
        *)
          echo "write=true"
          echo "/codex:rescue --wait --fresh --write --model $model --effort $effort \"<prompt>\""
          ;;
      esac
      ;;
    claude)
      echo "write=false"
      echo "Agent tool: model=$model, prompt=\"ROLE: subagent\\n\" + <request JSON>"
      ;;
    antigravity)
      echo "write=false"
      echo "Human relay: select model \"$model\" and send <request JSON>"
      ;;
  esac
}

case "${1:-}" in
  -h|--help) usage 0 ;;
  --list)
    jq -r '.quick_lookup | to_entries[] | [.key, .value] | @tsv' "$ROUTING_FILE"
    exit 0
    ;;
  --command)
    [[ -n "${2:-}" ]] || usage 2
    TASK_TYPE="$(resolve_task_type "$2")"
    [[ -n "$TASK_TYPE" ]] || die "unknown task type or alias: $2"
    emit_command "$TASK_TYPE" "${3:-1}"
    exit 0
    ;;
  "") usage 2 ;;
esac

QUERY="$1"

TASK_TYPE="$(resolve_task_type "$QUERY")"

[[ -n "$TASK_TYPE" ]] || die "unknown task type or alias: $QUERY"

jq -r --arg task_type "$TASK_TYPE" '
  .task_types[$task_type].recommended_models[]
  | [.rank, .provider, .model, .why]
  | @tsv
' "$ROUTING_FILE"
