#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REF="$ROOT/../active"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] $1 missing: $2"; fail=1; }; }
same(){ cmp -s "$1" "$2" || { echo "[FAIL] $2 differs from $1"; fail=1; }; }
same_namespaced(){ diff -q <(sed -E 's/superpowers(-orchestrator)?://g' "$1") <(sed -E 's/superpowers(-orchestrator)?://g' "$2") >/dev/null || { echo "[FAIL] $2 differs from $1 beyond its plugin namespace"; fail=1; }; }

same "$REF/skills/brainstorming/spec-template.md" "$ROOT/skills/brainstorming/spec-template.md"
same_namespaced "$REF/skills/brainstorming/roadmap.md" "$ROOT/skills/brainstorming/roadmap.md"
same_namespaced "$REF/skills/writing-plans/plan-template.md" "$ROOT/skills/writing-plans/plan-template.md"
same "$REF/skills/finishing-a-development-branch/pr-body-template.md" "$ROOT/skills/finishing-a-development-branch/pr-body-template.md"
same "$REF/assets/roadmap.html" "$ROOT/assets/roadmap.html"
check "$ROOT/skills/brainstorming/roadmap.md" "roadmap.json"
check "$ROOT/assets/roadmap.html" "data-status=\"released\""
[ "$fail" -eq 0 ] && echo "PASS test-plan-templates"
exit $fail
