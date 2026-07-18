#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOOKUP="$ROOT/scripts/model-lookup.sh"
SKILL="$ROOT/skills/dispatch-agent/SKILL.md"
WORKERS="$ROOT/skills/dispatch-agent/references/codex-workers.md"
PROTOCOL="$ROOT/skills/dispatch-agent/references/codex-worker-protocol.md"
ROUTING="$ROOT/assets/sdlc-model-routing.json"
RESCUE='/codex:rescue --wait --fresh --write --model <model> --effort <effort> "<prompt>"'
REVIEW='/codex:review --wait --model <model> --base <base_sha>'
SECURITY='/codex:adversarial-review --wait --model <model> --base <base_sha> "<security focus>"'

codex="$(bash "$LOOKUP" --command implementation_coding 1 2>&1 || true)"
grep -Fq 'agent=codex' <<<"$codex"
grep -Fq 'write=true' <<<"$codex"
grep -Fxq '/codex:rescue --wait --fresh --write --model gpt-5.6-terra --effort medium "<prompt>"' <<<"$codex"

review="$(bash "$LOOKUP" --command code_review_quality 2)"
grep -Fq 'write=false' <<<"$review"
grep -Fxq '/codex:review --wait --model gpt-5.6-sol --base <base_sha>' <<<"$review"

security="$(bash "$LOOKUP" --command security_review 3)"
grep -Fq 'write=false' <<<"$security"
grep -Fxq '/codex:adversarial-review --wait --model gpt-5.6-sol --base <base_sha> "<security focus>"' <<<"$security"

while IFS=$'\t' read -r task_type rank model; do
  command="$(bash "$LOOKUP" --command "$task_type" "$rank" | tail -n 1)"
  case "$task_type" in
    code_review_quality)
      [[ "$command" == "/codex:review --wait --model $model --base <base_sha>" ]] || {
        echo "wrong Codex command family for $task_type rank $rank" >&2
        exit 1
      }
      ;;
    security_review)
      [[ "$command" == "/codex:adversarial-review --wait --model $model --base <base_sha> \"<security focus>\"" ]] || {
        echo "wrong Codex command family for $task_type rank $rank" >&2
        exit 1
      }
      ;;
    *)
      case "$command" in
        "/codex:rescue --wait --fresh --write --model $model --effort low \"<prompt>\""|\
        "/codex:rescue --wait --fresh --write --model $model --effort medium \"<prompt>\""|\
        "/codex:rescue --wait --fresh --write --model $model --effort high \"<prompt>\"") ;;
        *) echo "wrong Codex command family for $task_type rank $rank" >&2; exit 1 ;;
      esac
      ;;
  esac
done < <(jq -r '.task_types | to_entries[] | .key as $task | .value.recommended_models[] | select(.provider == "Codex") | [$task, .rank, .model] | @tsv' "$ROUTING")

other="$(bash "$LOOKUP" --command architecture_design 1 2>&1 || true)"
grep -Fq 'agent=claude' <<<"$other"
! grep -Fq '/codex:rescue' <<<"$other"

grep -Fq 'If the resolved `agent` is `codex`' "$SKILL"
grep -Fq "$RESCUE" "$SKILL"
grep -Fq "$REVIEW" "$SKILL"
grep -Fq "$SECURITY" "$SKILL"
grep -Fq '"Claude Code" → claude' "$SKILL"
grep -Fq '"Antigravity CLI" → antigravity' "$SKILL"

grep -Fq "$RESCUE" "$WORKERS"
grep -Fq "$REVIEW" "$WORKERS"
grep -Fq "$SECURITY" "$WORKERS"
grep -Fxq "| \`$REVIEW\` | \`code_review_quality\` |" "$WORKERS"
grep -Fxq "| \`$SECURITY\` | \`security_review\` |" "$WORKERS"
grep -Fxq "| \`$RESCUE\` | \`discovery_research\`, \`requirements_user_stories\`, \`backlog_refinement_prioritization\`, \`sprint_planning\`, \`architecture_design\`, \`ui_ux_prototyping\`, \`implementation_coding\`, \`debugging_root_cause\`, \`testing_qa\`, \`release_deployment\`, \`workspace_setup\`, \`monitoring_incident_ops\`, \`documentation_knowledge_transfer\`, \`retrospective_process_improvement\` |" "$WORKERS"
grep -Fq 'Never use background/status/result/cancel, resume, `--profile`, or transfer.' "$WORKERS"
grep -Fq 'Never substitute one command family for another.' "$WORKERS"
grep -Fq 'Without `--profile`, each fresh task uses the plugin scheduler' "$WORKERS"

grep -Fq 'Missing `base_sha` is a malformed request' "$PROTOCOL"
grep -Fq '.superpowers/<task>/turn-<turn>-review.md' "$PROTOCOL"
grep -Fq 'Persist stdout verbatim' "$PROTOCOL"
grep -Fq 'Review commands do not use the rescue prompt contract' "$PROTOCOL"

while IFS= read -r task_type; do
  count="$(grep -Fc "| \`$task_type\` |" "$PROTOCOL")"
  [[ "$count" -eq 1 ]] || { echo "expected one protocol row for $task_type, got $count" >&2; exit 1; }
done < <(jq -r '.task_types | keys[]' "$ROUTING")

while IFS='|' read -r task_type persona discipline; do
  grep -Fq "| \`$task_type\` | \`$persona\` | \`$discipline\` |" "$PROTOCOL" || {
    echo "wrong protocol contract for $task_type" >&2
    exit 1
  }
done <<'EOF'
architecture_design|tech_lead|verification-before-completion
backlog_refinement_prioritization|product_owner|verification-before-completion
code_review_quality|tech_lead|verification-before-completion
debugging_root_cause|software_engineer|systematic-debugging
discovery_research|business_analyst|verification-before-completion
documentation_knowledge_transfer|technical_writer|verification-before-completion
implementation_coding|software_engineer|test-driven-development
monitoring_incident_ops|sre|systematic-debugging
release_deployment|devops_engineer|verification-before-completion
requirements_user_stories|product_owner|verification-before-completion
retrospective_process_improvement|agile_coach|verification-before-completion
security_review|security_engineer|verification-before-completion
sprint_planning|tech_lead|verification-before-completion
testing_qa|qa_engineer|verification-before-completion
ui_ux_prototyping|ux_ui_designer|verification-before-completion
workspace_setup|devops_engineer|verification-before-completion
EOF
! grep -Fq '`executing-plans`' "$PROTOCOL"
grep -Fq 'Return only a backlog proposal; never edit `roadmap.json`, `ROADMAP.html`, or product files. The orchestrator applies approved changes after human approval.' "$PROTOCOL"
grep -Fq 'Recommend process improvements only; never edit skills, workflows, or product files.' "$PROTOCOL"
grep -Fq '`receiving-code-review` has precedence over the task-type table for D16 and D18.' "$PROTOCOL"
grep -Fq '`software_engineer` | `receiving-code-review` | Review remediation' "$PROTOCOL"

echo 'PASS test-codex-command'
