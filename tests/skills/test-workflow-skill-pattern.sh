#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PATTERN="$ROOT/skills/writing-skills/workflow-skill-pattern.md"
fail=0

check() {
  grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }
}

if [ ! -f "$PATTERN" ]; then
  echo "[FAIL] no skills/writing-skills/workflow-skill-pattern.md"
  exit 1
fi

rows="$(awk -F'|' '
  /<!-- blocks:start -->/ { inside=1; next }
  /<!-- blocks:end -->/ { inside=0 }
  inside && $2 ~ /^[[:space:]]*[0-9]+[[:space:]]*$/ { count++ }
  END { print count+0 }
' "$PATTERN")"
[ "$rows" -eq 12 ] || { echo "[FAIL] expected 12 block rows, got $rows"; fail=1; }

exclusions="$(awk '
  /<!-- exclude:start -->/ { inside=1; next }
  /<!-- exclude:end -->/ { inside=0 }
  inside && /^[[:space:]]*skills\/[^[:space:]]+\/[[:space:]]*$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")
    print
  }
' "$PATTERN")"
[ "$exclusions" = 'skills/visual-companion/' ] || {
  echo "[FAIL] exclusion fence must contain only skills/visual-companion/"
  fail=1
}

check "$PATTERN" '## Pattern Omissions'
check "$PATTERN" '- `hard-gate` — skill only reads and reports; no irreversible act.'
check "$PATTERN" '- `token-cost-monitoring` — never invokes a model nor dispatches.'
check "$PATTERN" 'the section must be a plain append-only record, writing one line per dispatch or model-invocation event to the run'
check "$PATTERN" 'No analysis or reporting belongs here.'

for rule in 1 2 3 4 5 6; do
  grep -Eq "^\| $rule \|" "$PATTERN" || {
    echo "[FAIL] missing validator rule $rule"
    fail=1
  }
done

[ "$fail" -eq 0 ] && echo 'PASS test-workflow-skill-pattern'
exit "$fail"
