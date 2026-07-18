#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
has(){ check "$ROOT/skills/$1/SKILL.md" "superpowers-orchestrator:dispatch-agent"; }
fenced(){ check "$ROOT/skills/$1/SKILL.md" "riso-tech:orchestrator-split START"; }
for s in subagent-driven-development dispatching-parallel-agents requesting-code-review; do has "$s"; fenced "$s"; done
RC="$ROOT/skills/requesting-code-review/SKILL.md"
check "$RC" "author_agent"
check "$RC" "security_review"
check "$RC" "security_engineer"
[ "$fail" -eq 0 ] && echo "PASS test-dispatch-routing"
exit $fail
