#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/project-kickoff/SKILL.md"
WORKFLOW="$ROOT/docs/orchestrator-workflow.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
test -f "$SKILL" || { echo "[FAIL] no project-kickoff/SKILL.md"; exit 1; }
check "$SKILL" "name: project-kickoff"
check "$SKILL" "superpowers-orchestrator:dispatch-agent"
check "$SKILL" "business_analyst"
check "$SKILL" "discovery_research"
check "$SKILL" "devops_engineer"
check "$SKILL" "workspace_setup"
check "$SKILL" "tech_lead"
check "$SKILL" "architecture_design"
check "$SKILL" "riso-tech:orchestrator-split — new skill, no upstream counterpart"
check "$SKILL" "Redirect guard"
check "$SKILL" "Red Flags"
check "$SKILL" "Initialize the product roadmap"
check "$SKILL" "docs/superpowers/roadmap.json"
check "$SKILL" "docs/superpowers/ROADMAP.html"
check "$SKILL" 'skills/brainstorming/roadmap.md'
check "$SKILL" 'assets/roadmap.html'
check "$SKILL" 'https://docs.gitignore.io/install/command-line'
check "$SKILL" 'https://www.toptal.com/developers/gitignore/api/list'
check "$SKILL" '`curl --fail --silent --show-error --location`'
check "$SKILL" 'for both the template-list and generation requests'
check "$SKILL" 'repository-root temporary file'
check "$SKILL" 'template-to-stack coverage mapping'
check "$SKILL" 'If `.gitignore` already exists, stop and ask the human'
check "$SKILL" 'labelled commit SHA'
check "$SKILL" 'git show --name-only --format='
check "$SKILL" 'docs/superpowers/specs/YYYY-MM-DD-<topic>-discovery.md'
check "$SKILL" 'stage only `.gitignore`'
check "$SKILL" 'return both commit SHAs'
check "$WORKFLOW" 'generate and commit tech-stack `.gitignore`'
check "$WORKFLOW" "initialize product roadmap"
[ "$fail" -eq 0 ] && echo "PASS test-project-kickoff"
exit $fail
