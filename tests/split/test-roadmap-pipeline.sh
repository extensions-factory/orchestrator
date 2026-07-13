#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/brainstorming/SKILL.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }

check "$SKILL" "riso-tech:orchestrator-split START"
check "$SKILL" "riso-tech:orchestrator-split END"
check "$SKILL" "following \`skills/brainstorming/spec-template.md\`, generate the HTML companion"
check "$SKILL" "role: business_analyst"
check "$SKILL" "role: product_owner"
check "$SKILL" "role: tech_lead"
check "$SKILL" "role: technical_writer"
check "$SKILL" "self-contained HTML companion at the same path with a \`.html\` extension"
check "$SKILL" "docs/superpowers/roadmap.json"
check "$SKILL" "docs/superpowers/ROADMAP.html"
check "$SKILL" "one entry per User Story"
check "$SKILL" "5. **Template check:**"

RELEASE="$ROOT/skills/finishing-a-development-branch/SKILL.md"
check "$RELEASE" "riso-tech:orchestrator-split START"
check "$RELEASE" "riso-tech:orchestrator-split END"
check "$RELEASE" "role: devops_engineer"
check "$RELEASE" "task_type: release_deployment"
check "$RELEASE" "pr-body-template.md"
check "$RELEASE" "gh pr create --body-file"
check "$RELEASE" "### Step 5b: Update Product Roadmap"
check "$RELEASE" "Runs for Options 1 (merge) and 2 (PR) only"
check "$RELEASE" "status: released"
check "$RELEASE" "../brainstorming/roadmap.md"
[ "$fail" -eq 0 ] && echo "PASS test-roadmap-pipeline"
exit $fail
