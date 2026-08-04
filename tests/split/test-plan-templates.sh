#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REF="$ROOT/../active"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }
same(){ cmp -s "$1" "$2" || { echo "[FAIL] $2 differs from $1"; fail=1; }; }
same_namespaced(){ diff -q <(sed -E 's/superpowers(-orchestrator)?://g' "$1") <(sed -E 's/superpowers(-orchestrator)?://g' "$2") >/dev/null || { echo "[FAIL] $2 differs from $1 beyond its plugin namespace"; fail=1; }; }
strip_upstream_commit(){ awk '
  /^> \*\*For agentic workers:\*\* REQUIRED SUB-SKILL:/ { next }
  /^- \[ \] \*\*Step 5: Commit\*\*$/ { skip=1; next }
  skip && /^```$/ { skip=0; next }
  !skip
' "$1"; }
strip_orchestrator_override(){ awk '
  $0 == "<!-- riso-tech:orchestrator-split START -->" {
    if ((getline line) > 0 && (line == "**Orchestrator Git Bookkeeping (not a worker step):**" || line ~ /^> \*\*For agentic workers:\*\* REQUIRED SUB-SKILL:/ || line ~ /^\*\*task_type:\*\*/)) {
      while ((getline) > 0 && $0 != "<!-- riso-tech:orchestrator-split END -->") {}
      next
    }
    print
    print line
    next
  }
  { print }
' "$1"; }
normalize_doc_paths(){
  sed -E \
    -e 's#docs/superpowers/specs/YYYY-MM-DD-<topic>-design\.md#<SPEC_PATH>#g' \
    -e 's#docs/superpowers/features/<feature-slug>/design\.md#<SPEC_PATH>#g' \
    -e 's#docs/superpowers/plans/YYYY-MM-DD-<feature-name>\.md#<PLAN_PATH>#g' \
    -e 's#docs/superpowers/features/<feature-slug>/plan\.md#<PLAN_PATH>#g'
}
normalize_plan_steps(){
  awk '
    /^- \[ \] \*\*Step 1:/ { print "<PLAN_STEPS>"; skip=1; next }
    skip && /^\*\*US-1 Checkpoint:\*\*/ { skip=0; print; next }
    !skip
  '
}
same_plan_template(){ diff -q <(strip_upstream_commit "$1" | normalize_plan_steps | sed -E 's/superpowers(-orchestrator)?://g' | normalize_doc_paths) <(strip_orchestrator_override "$2" | normalize_plan_steps | sed -E 's/superpowers(-orchestrator)?://g' | normalize_doc_paths) >/dev/null || { echo "[FAIL] $2 differs from $1 beyond its orchestrator task instructions, Git override, document paths, and plugin namespace"; fail=1; }; }
same_pr_template(){ diff -q <(normalize_doc_paths < "$1") <(normalize_doc_paths < "$2") >/dev/null || { echo "[FAIL] $2 differs from $1 beyond document paths"; fail=1; }; }

same "$REF/skills/brainstorming/spec-template.md" "$ROOT/skills/brainstorming/templates/spec-template.md"
same_namespaced "$REF/skills/brainstorming/roadmap.md" "$ROOT/skills/brainstorming/roadmap.md"
same_plan_template "$REF/skills/writing-plans/plan-template.md" "$ROOT/skills/writing-plans/templates/plan-template.md"
check "$ROOT/skills/writing-plans/templates/plan-template.md" "**Orchestrator Git Bookkeeping (not a worker step):**"
same_pr_template "$REF/skills/finishing-a-development-branch/pr-body-template.md" "$ROOT/skills/finishing-a-development-branch/templates/pr-body-template.md"
same "$REF/assets/roadmap.html" "$ROOT/assets/roadmap.html"
roadmap_feature_parity(){
  diff -u \
    <(awk '/<div class="card">/{card=1; next} card && /<\/div>/{card=0} card && /<li>/{gsub(/.*<li>|<\/li>.*/, ""); print}' "$1" | sort) \
    <(awk '/<section class="section" data-section>/{section=1; next} section && /<\/section>/{section=0} section && /<h2>/{gsub(/.*<h2>|<\/h2>.*/, ""); print}' "$1" | sort) \
    >/dev/null || { echo "[FAIL] $1 card and section feature names differ"; fail=1; }
}
roadmap_feature_parity "$ROOT/docs/superpowers/ROADMAP.html"
check "$ROOT/skills/brainstorming/roadmap.md" "roadmap.json"
check "$ROOT/assets/roadmap.html" "data-status=\"released\""
[ "$fail" -eq 0 ] && echo "PASS test-plan-templates"
exit $fail
