#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
has(){ grep -Fq -- "dispatch-agent" "$ROOT/skills/$1/SKILL.md" || { echo "[FAIL] $1 does not route via dispatch-agent"; fail=1; }; }
fenced(){ grep -Fq -- "riso-tech:orchestrator-split START" "$ROOT/skills/$1/SKILL.md" || { echo "[FAIL] $1 edit not fenced"; fail=1; }; }
for s in subagent-driven-development dispatching-parallel-agents requesting-code-review; do has "$s"; fenced "$s"; done
# requesting-code-review must pass author_agent for provider diversity
grep -Fq -- "author_agent" "$ROOT/skills/requesting-code-review/SKILL.md" || { echo "[FAIL] requesting-code-review missing author_agent"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS test-dispatch-routing"
exit $fail
