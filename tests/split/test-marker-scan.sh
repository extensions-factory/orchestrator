#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DECISIONS="$ROOT/../docs/superpowers/MERGE-DECISIONS.md"
fail=0
starts=$(grep -rl "riso-tech:orchestrator-split START" "$ROOT/skills" 2>/dev/null | wc -l | tr -d ' ')
# every START has an END in the same file
while IFS= read -r f; do
  s=$(grep -c "riso-tech:orchestrator-split START" "$f" || true)
  e=$(grep -c "riso-tech:orchestrator-split END" "$f" || true)
  [ "$s" = "$e" ] || { echo "[FAIL] unbalanced fences in $f ($s START / $e END)"; fail=1; }
done < <(grep -rl "riso-tech:orchestrator-split START" "$ROOT/skills" 2>/dev/null)
# decisions doc exists and names each marker type
for rule in "Fenced markdown" "New file" "JSON asset" "Deleted skill"; do
  grep -Fq -- "$rule" "$DECISIONS" || { echo "[FAIL] MERGE-DECISIONS missing rule: $rule"; fail=1; }
done
echo "orchestrator fenced files: $starts"
[ "$fail" -eq 0 ] && echo "PASS test-marker-scan"
exit $fail
