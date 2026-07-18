#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $3"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] $3"; fail=1; } || true; }
before(){
  local first second
  first="$(awk -v needle="$2" 'index($0, needle) { print NR; exit }' "$1")"
  second="$(awk -v needle="$3" 'index($0, needle) { print NR; exit }' "$1")"
  [ -n "$first" ] && [ -n "$second" ] && [ "$first" -lt "$second" ] || {
    echo "[FAIL] $4"
    fail=1
  }
}
git_contract(){
  grep -Eqi -- 'implementation workers? (never|must not|do not) commit|no implementation worker commits?' "$1" || {
    echo "[FAIL] $1 does not prohibit implementation-worker commits"
    fail=1
  }
  grep -Eqi -- 'orchestrator.*(owns|performs|runs).*Git bookkeeping|Git bookkeeping.*orchestrator' "$1" || {
    echo "[FAIL] $1 does not assign Git bookkeeping to the orchestrator"
    fail=1
  }
}

PK="$ROOT/skills/project-kickoff/SKILL.md"
d5="$(grep -F -- '**Dispatch:** `D5`' "$PK" || true)"
d7="$(grep -F -- '**Dispatch:** `D7`' "$PK" || true)"
[[ "$d5" != *commit* ]] || { echo "[FAIL] project-kickoff D5 requires a commit before git init"; fail=1; }
[[ "$d7" == *discovery* ]] || { echo "[FAIL] project-kickoff D7 initial commit does not include discovery"; fail=1; }
[[ "$d7" == *'stage only the discovery document'* ]] || {
  echo "[FAIL] project-kickoff D7 does not limit staging to the discovery document"
  fail=1
}
[[ "$d7" == *'git diff --cached --name-only'*'.superpowers/'* ]] || {
  echo "[FAIL] project-kickoff D7 does not verify staged files exclude .superpowers"
  fail=1
}

WORKFLOW="$ROOT/docs/orchestrator-workflow.md"
workflow_d7="$(grep -F -- 'D7 ' "$WORKFLOW" | head -1 || true)"
[[ "$workflow_d7" == *commit*discovery* ]] || {
  echo "[FAIL] orchestrator workflow D7 does not commit discovery"
  fail=1
}
[[ "$workflow_d7" == *normal*otherwise* ]] || {
  echo "[FAIL] orchestrator workflow D7 omits normal-commit behavior when HEAD exists"
  fail=1
}

WP="$ROOT/skills/writing-plans/SKILL.md"
SDD="$ROOT/skills/subagent-driven-development/SKILL.md"
DA="$ROOT/skills/dispatch-agent/SKILL.md"
for skill in "$WP" "$SDD" "$DA"; do git_contract "$skill"; done
reject "$WP" '- [ ] **Step 5: Commit**' "writing-plans still assigns a commit step to the worker"
PLAN_TEMPLATE="$ROOT/skills/writing-plans/plan-template.md"
reject "$PLAN_TEMPLATE" '- [ ] **Step 5: Commit**' "plan-template still assigns a commit step to the worker"
for plan_contract in "$WP" "$PLAN_TEMPLATE"; do
  check "$plan_contract" 'After a successful worker response or successful inline task execution' \
    "$plan_contract bookkeeping predicate does not cover worker and inline execution"
done
reject "$SDD" 'Implementer subagent implements, tests, commits' "subagent-driven-development still tells implementers to commit"
reject "$SDD" 'returns only status, commits' "subagent-driven-development still expects implementer commits"
IMPLEMENTER="$ROOT/skills/subagent-driven-development/implementer-prompt.md"
reject "$IMPLEMENTER" 'Commit your work' "implementer-prompt still instructs the worker to commit"
reject "$IMPLEMENTER" 'full suite once before committing' "implementer-prompt still schedules the full suite around a worker commit"
reject "$IMPLEMENTER" 'Commits created' "implementer-prompt still requires worker commit SHAs"
d16="$(grep -F -- '**Dispatch:** `D16`' "$SDD" || true)"
d18="$(grep -F -- '**Dispatch:** `D18`' "$SDD" || true)"
[[ "$d16" == *orchestrator*'Git bookkeeping'*D14* ]] || {
  echo "[FAIL] subagent-driven-development D16 does not assign orchestrator Git bookkeeping before D14 re-review"
  fail=1
}
[[ "$d18" == *orchestrator*'Git bookkeeping'*D17* ]] || {
  echo "[FAIL] subagent-driven-development D18 does not assign orchestrator Git bookkeeping before D17 re-review"
  fail=1
}

FB="$ROOT/skills/finishing-a-development-branch/SKILL.md"
before "$FB" 'Run the shared Step 5b recipe on `<base-branch>` now' '# Verify tests on merged result after the roadmap commit' \
  "finishing merge path tests before updating and committing the roadmap"
before "$FB" 'Run the shared Step 5b recipe on the feature branch now' '# Verify tests on feature branch after the roadmap commit' \
  "finishing PR path tests before updating and committing the roadmap"
before "$FB" 'Run the shared Step 5b recipe on the feature branch now' 'git push -u origin <feature-branch>' \
  "finishing PR path pushes before updating and committing the roadmap"

RC="$ROOT/skills/requesting-code-review/SKILL.md"
reject "$RC" 'HEAD~1' "requesting-code-review still suggests HEAD~1"
grep -Eqi -- 'record(ed)? (the )?exact pre-task (commit|SHA)' "$RC" || {
  echo "[FAIL] requesting-code-review does not require recording the exact pre-task SHA"
  fail=1
}
check "$RC" 'MERGE_BASE=$(git merge-base <base-branch> HEAD)' \
  "requesting-code-review does not derive the whole-branch MERGE_BASE from git merge-base"

GW="$ROOT/skills/using-git-worktrees/SKILL.md"
check "$GW" 'git check-ignore -q -- "$LOCATION/"' \
  "using-git-worktrees does not validate the selected location"
check "$GW" 'normalize `LOCATION` to a repository-relative path' \
  "using-git-worktrees does not normalize absolute project-local locations before updating .gitignore"
reject "$GW" 'git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null' \
  "using-git-worktrees still OR-checks unrelated candidate directories"

EP="$ROOT/skills/executing-plans/SKILL.md"
check "$EP" 'Only when the harness has no subagent capability at all' \
  "executing-plans does not limit inline fallback to harnesses without subagents"
check "$DA" 'Only when the harness has no subagent capability at all' \
  "dispatch-agent does not limit inline fallback to harnesses without subagents"
reject "$EP" 'when no worker provider is available' \
  "executing-plans incorrectly treats provider failure as an inline fallback"

check "$SDD" 'Harness has subagent capability?' \
  "subagent-driven-development still selects execution by session placement instead of harness capability"
reject "$SDD" 'executing-plans" [label="no - parallel session"]' \
  "subagent-driven-development still routes parallel sessions to executing-plans when subagents exist"
for handoff in "$WP" "$PLAN_TEMPLATE" "$ROOT/skills/receiving-plan-refine/SKILL.md"; do
  grep -Fqi -- 'when the harness supports subagents' "$handoff" || {
    echo "[FAIL] $handoff does not route execution by harness capability"
    fail=1
  }
done
reject "$WP" 'ask which execution mode' \
  "writing-plans still offers inline execution as a preference instead of a capability fallback"
reject "$ROOT/skills/receiving-plan-refine/SKILL.md" 'Two execution options' \
  "receiving-plan-refine still offers inline execution when subagents may exist"

check "$FB" "Resolve the chosen option's menu selection to a named action" \
  "finishing-a-development-branch does not disambiguate attached and detached menu numbering"
check "$FB" 'detached: 1 = `pr`, 2 = `keep`, 3 = `discard`' \
  "finishing-a-development-branch lacks the detached action mapping"
check "$FB" 'For detached `discard`' \
  "finishing-a-development-branch does not define safe detached discard behavior"
reject "$FB" 'clean up only for Options 1/4' \
  "finishing-a-development-branch cleanup still depends on ambiguous option numbers"

check "$RC" 'D16 fix subagent' \
  "requesting-code-review example does not dispatch D16 for Important findings"
check "$RC" 'D14 re-review' \
  "requesting-code-review example does not re-review Important fixes"
check "$RC" 'record the Minor for D17' \
  "requesting-code-review example does not defer Minor findings to final review"
reject "$RC" 'D16 fix subagent with both findings' \
  "requesting-code-review example sends Minor findings to D16"
reject "$RC" 'Assessment: Ready to proceed' \
  "requesting-code-review example proceeds despite an Important finding"

check "$FB" 'Detached discard confirmation:' \
  "finishing-a-development-branch does not provide a truthful detached discard warning"
check "$FB" '| Action | Merge | Push | Keep Worktree | Delete Branch |' \
  "finishing-a-development-branch quick reference still depends on ambiguous option numbers"
reject "$FB" '| 1. Merge locally |' \
  "finishing-a-development-branch quick reference still maps detached option 1 to merge"

check "$PK" 'git rev-parse --verify HEAD' \
  "project-kickoff determines initial commit from workflow history instead of HEAD existence"
check "$WORKFLOW" 'HEAD is absent' \
  "orchestrator workflow does not define kickoff initial-commit behavior from HEAD existence"

check "$WORKFLOW" 'commit fix and regenerate task review package' \
  "orchestrator workflow omits D16 Git bookkeeping before D14 re-review"
check "$WORKFLOW" 'commit fix wave and regenerate whole-branch review package' \
  "orchestrator workflow omits D18 Git bookkeeping before D17 re-review"

[ "$fail" -eq 0 ] && echo "PASS test-skill-contracts"
exit "$fail"
