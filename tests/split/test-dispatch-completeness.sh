#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }
fenced(){ grep -Fq -- "riso-tech:orchestrator-split START" "$1" || { echo "[FAIL] $1 edit not fenced"; fail=1; }; }
dispatch_lines(){
  awk -v id="\`$2\`" '
    $0 == "<!-- riso-tech:orchestrator-split START -->" {
      if ((getline dispatch) <= 0 || dispatch !~ /^\*\*Dispatch:\*\*/) next
      if ((getline end) <= 0 || end != "<!-- riso-tech:orchestrator-split END -->") next
      if (index(dispatch, id)) print dispatch
    }
  ' "$1"
}
check_dispatch(){
  local file="$1" id="$2" lines line expected matches
  shift 2
  lines="$(dispatch_lines "$file" "$id")"
  if [ -z "$lines" ]; then
    echo "[FAIL] $file missing adjacent START / **Dispatch:** for $id / END block"
    fail=1
    return
  fi
  while IFS= read -r line; do
    matches=1
    for expected in "$@"; do
      case "$line" in *"$expected"*) ;; *) matches=0 ;; esac
    done
    [ "$matches" -eq 1 ] && return
  done <<EOF
$lines
EOF
  echo "[FAIL] $file $id has no dispatch block containing: $*"
  fail=1
}

# US-1: SM identity injection
US="$ROOT/skills/using-superpowers/SKILL.md"
check "$US" "You are the Orchestrator (Scrum Master)"
fenced "$US"

# US-2: full 16-role persona list in dispatch-agent
DA="$ROOT/skills/dispatch-agent/SKILL.md"
for role in product_owner scrum_master software_engineer tech_lead qa_engineer ux_ui_designer devops_engineer security_engineer sre engineering_manager product_manager technical_writer business_analyst data_analyst agile_coach stakeholder; do
  grep -Fq -- "\`$role\`" "$DA" || { echo "[FAIL] dispatch-agent missing persona: $role"; fail=1; }
done
persona_count=$(grep -cE '^- `[a-z_]+`' "$DA" || true)
[ "$persona_count" -eq 16 ] || { echo "[FAIL] expected 16 persona lines, got $persona_count"; fail=1; }

# US-3: writing-plans dispatches plan authorship
WP="$ROOT/skills/writing-plans/SKILL.md"
check "$WP" "dispatch-agent"
check "$WP" "tech_lead"
fenced "$WP"

# US-4: finishing-a-development-branch dispatches to devops_engineer
FB="$ROOT/skills/finishing-a-development-branch/SKILL.md"
check "$FB" "dispatch-agent"
check "$FB" "devops_engineer"
fenced "$FB"

# US-5: using-git-worktrees dispatches to devops_engineer
GW="$ROOT/skills/using-git-worktrees/SKILL.md"
check "$GW" "dispatch-agent"
check "$GW" "devops_engineer"
fenced "$GW"

# US-6: brainstorming write-up dispatch is phase-parameterized; live conversation stays inline
BS="$ROOT/skills/brainstorming/SKILL.md"
check "$BS" "business_analyst"
check "$BS" "product_owner"
check "$BS" "never talks to the human"
fenced "$BS"

# Lifecycle tree: every D1-D22 dispatch is an exact three-line marker block.
PK="$ROOT/skills/project-kickoff/SKILL.md"
check_dispatch "$PK" D1 "four distinct dispatches" "role: business_analyst" "task_type: discovery_research" "research domains"
check_dispatch "$PK" D2 "four distinct dispatches" "role: business_analyst" "task_type: discovery_research" "research domains"
check_dispatch "$PK" D3 "four distinct dispatches" "role: business_analyst" "task_type: discovery_research" "research domains"
check_dispatch "$PK" D4 "four distinct dispatches" "role: business_analyst" "task_type: discovery_research" "research domains"
check_dispatch "$PK" D5 "role: business_analyst" "task_type: discovery_research" "discovery document"
check_dispatch "$PK" D6 "role: devops_engineer" "task_type: workspace_setup" "git init"
check_dispatch "$PK" D7 "role: devops_engineer" "task_type: workspace_setup" "initial commit"
check_dispatch "$PK" D8 "role: tech_lead" "task_type: architecture_design" "scaffold spec"
check_dispatch "$BS" D9 "phase-matched role" "phase-matched task_type" "spec, HTML companion, and roadmap"

check_dispatch "$WP" D10 "role: tech_lead" "task_type: sprint_planning" "plan and HTML companion"
PR="$ROOT/skills/requesting-plan-refine/SKILL.md"
check_dispatch "$PR" D11 "role: tech_lead" "task_type: code_review_quality" "independent plan review" "refine loop"
check_dispatch "$GW" D12 "role: devops_engineer" "task_type: workspace_setup" "created worktree path"

SDD="$ROOT/skills/subagent-driven-development/SKILL.md"
RC="$ROOT/skills/requesting-code-review/SKILL.md"
check_dispatch "$SDD" D13 "role: software_engineer" "plan task's task_type" "implement and test" "every plan task"
check_dispatch "$RC" D14 "role: tech_lead" "task_type: code_review_quality" "base_sha" "task review" "re-review"
check_dispatch "$RC" D15 "role: security_engineer" "task_type: security_review" "base_sha" "security_focus" "only when" "security-sensitive"
check_dispatch "$SDD" D16 "role: software_engineer" "plan task's task_type" "skill: receiving-code-review" "Critical/Important findings" "D14"
check_dispatch "$RC" D17 "role: tech_lead" "task_type: code_review_quality" "base_sha" "whole-branch review" "D18"
check_dispatch "$SDD" D18 "role: software_engineer" "task_type: implementation_coding" "skill: receiving-code-review" "one fix wave" "D17"

check_dispatch "$FB" D19 "role: devops_engineer" "task_type: release_deployment" "selected finish path" "context.constraints" "HUMAN_CONFIRMED_DESTRUCTIVE_RELEASE: <operation>" "exact discard confirmation" "chosen option"
SR="$ROOT/skills/sprint-retrospective/SKILL.md"
check_dispatch "$SR" D20 "role: agile_coach" "task_type: retrospective_process_improvement" "process review"
WS="$ROOT/skills/writing-skills/SKILL.md"
check_dispatch "$WS" D21 "role: software_engineer" "task_type: implementation_coding" "human-approved skill improvement" "writing-skills"
BR="$ROOT/skills/backlog-refinement/SKILL.md"
check_dispatch "$BR" D22 "role: product_owner" "task_type: backlog_refinement_prioritization" "propose ordering and grooming" "human approves"

[ "$fail" -eq 0 ] && echo "PASS test-dispatch-completeness"
exit $fail
