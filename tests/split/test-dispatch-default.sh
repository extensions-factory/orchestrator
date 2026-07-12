#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }
absent(){ ! grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 must not contain: $2"; fail=1; }; }

for skill in brainstorming writing-plans backlog-refinement finishing-a-development-branch using-git-worktrees sprint-retrospective; do
  SKILL="$ROOT/skills/$skill/SKILL.md"
  absent "$SKILL" "today's behavior"
  check "$SKILL" "no subagent capability"
done

[ "$fail" -eq 0 ] && echo "PASS test-dispatch-default"
exit $fail
