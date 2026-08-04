#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/project-kickoff/SKILL.md"
README="$ROOT/skills/project-kickoff/README.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }
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
check "$SKILL" 'docs/superpowers/project/discovery.md'
check "$SKILL" 'stage only `.gitignore`'
check "$SKILL" 'return both commit SHAs'

check "$README" '## Description'
check "$README" '## Inputs'
check "$README" '## Durable Output'
check "$README" '## Human Decisions'
check "$README" '## Handoff'

check "$SKILL" 'Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace'
check "$SKILL" 'Human Gate 1 — Idea and research direction'
check "$SKILL" 'Do not dispatch D1–D4 until this approval is recorded'
check "$SKILL" 'Human Gate 2 — Stack, standards, and AI tools'
check "$SKILL" 'Do not dispatch D6–D8 until this approval is recorded'
check "$SKILL" 'Before handoff, reread the selected session entry'
check "$SKILL" 'Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace'
check "$SKILL" 'On resume, reuse complete approved decision bundles already recorded there'
check "$SKILL" 'regenerate and reapprove affected scaffold artifacts'

check "$SKILL" '## Token-cost Monitoring'
check "$SKILL" 'project_kickoff.workflow_id'
check "$SKILL" '.superpowers/runs/<workflow-id>/project-kickoff-token-cost.jsonl'
check "$SKILL" 'after every `D1`–`D8` provider attempt'
check "$SKILL" 'including retries, revisions, blocked results, and provider fallbacks'
check "$SKILL" '`unavailable_reason`'
check "$SKILL" 'Do not estimate missing token counts'
check "$SKILL" 'measured attempts / total attempts'
check "$SKILL" '`turn` is the request envelope'
check "$SKILL" '`attempt` starts at 1'
check "$SKILL" 'Sum input and output columns independently'
check "$SKILL" 'append one line at a time'
check "$SKILL" '"source":"worker"'
check "$SKILL" '"source":"orchestrator"'
check "$SKILL" 'after each harness-reported orchestrator model turn'
check "$SKILL" 'from project-kickoff activation through handoff'
check "$SKILL" 'worker, orchestrator, and combined'
check "$SKILL" 'before any other project-kickoff action'
check "$SKILL" 'max recorded orchestrator turn + 1'
check "$SKILL" 'each harness-reported main-orchestrator model invocation'
check "$SKILL" 'Refuse to label any partial subtotal as a complete project-kickoff total'
check "$README" 'orchestrator model turns'
check "$README" 'combined project-kickoff totals'
reject "$SKILL" 'not orchestrator conversation tokens'
reject "$README" 'not other lifecycle phases, orchestrator conversation tokens'
reject "$SKILL" 'Phase A'
reject "$README" 'Phase A'
check "$README" '## Token-cost Monitoring'
check "$README" 'project-kickoff-token-cost.jsonl'

check "$README" '"project_kickoff"'
check "$README" '"idea"'
check "$README" '"research_direction"'
check "$README" '"stack"'
check "$README" '"standards"'
check "$README" '"ai_tools"'
reject "$README" '../../docs/orchestrator-workflow.md'
[ "$fail" -eq 0 ] && echo "PASS test-project-kickoff"
exit $fail
