#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/finishing-a-development-branch/SKILL.md"
SECTION="$(sed -n '/^### Step 4b: Post-Land Knowledge Graph Refresh/,/^### Step 5: Execute Choice/p' "$SKILL")"
fail=0

check() {
  local needle="$1"
  local label="$2"
  if grep -Fq -- "$needle" <<< "$SECTION"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

check 'After D19 returns `done` for `merge` or `pr`' 'refresh starts only after a landed finish path'
check 'For `keep` or `discard`, skip this entire step' 'keep and discard skip freshness and gate'
check 'use `.ua/knowledge-graph.json` first' 'canonical graph path has precedence'
check 'legacy path only when `.understand-anything/` exists' 'legacy graph path is conditional'
check 'compare `project.gitCommitHash` with `git log -1 --format=%H -- .`' 'post-land freshness uses scoped HEAD'
check 'If the graph is absent or malformed, skip the gate' 'absent or malformed graph degrades silently'
check 'If the graph is already fresh, continue without a gate' 'fresh graph avoids unnecessary work'
check 'Knowledge graph is stale. Refresh it now? (yes/no)' 'stale graph presents the exact human gate'
check 'On `no`, skip the refresh and continue without error.' 'declined refresh is non-fatal'
check 'On `yes`, proceed to the D20 dispatch.' 'confirmed refresh proceeds to dispatch block'
check '**Dispatch:** `D20`' 'D20 dispatch block is present'
check 'riso-tech:orchestrator-split START' 'D20 dispatch block is fenced with orchestrator-split markers'
check '`role: technical_writer`' 'refresh worker role is technical_writer'
check '`task_type: documentation_knowledge_transfer`' 'refresh task type is documentation knowledge transfer'
check 'no provider pin' 'standard model ranking remains active'
check 'run `/understand` in the checkout' 'worker rebuild command is explicit'
check 'validate the worker response' 'worker envelope is validated'
check 'matches the current scoped HEAD' 'rebuilt graph is checked against landed HEAD'
check 'append one result to the project ledger' 'refresh outcome is recorded'
check 'Do not retry automatically' 'refresh failures are surfaced without retry'

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "PASS test-finishing-graph-refresh"
