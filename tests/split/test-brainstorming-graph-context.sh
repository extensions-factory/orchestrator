#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/brainstorming/SKILL.md"
SECTION="$(sed -n '/^1\. \*\*Explore project context\*\*/,/^2\. \*\*Offer the visual companion/p' "$SKILL")"
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

check 'collect graph context inline and best-effort' 'brainstorming collect is inline and best-effort'
check '`.ua/knowledge-graph.json`' 'canonical graph path is checked first'
check '`.understand-anything/knowledge-graph.json` only when `.understand-anything/` exists' 'legacy graph path is conditional'
check '`project.gitCommitHash` with `git log -1 --format=%H -- .`' 'freshness uses the project-scoped HEAD'
check '`grep_search` the graph for the feature keywords' 'fresh graph is searched by feature keywords'
check 'node names, summaries, and edge targets' 'graph matches seed the required context fields'
check 'Knowledge graph missing or stale; continuing with file exploration.' 'missing or stale graph has a one-line fallback'
check 'malformed, `git log` fails, or the hashes differ' 'invalid freshness inputs fall back'
check 'no matches, continue normal file exploration without error' 'empty graph search is non-fatal'
check 'Never call `/understand`, dispatch a worker, write the graph, or block normal file exploration from this collect step.' 'collect cannot build, dispatch, write, or block'

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "PASS test-brainstorming-graph-context"
