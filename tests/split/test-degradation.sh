#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/dispatch-agent/SKILL.md"
fail=0
check(){ grep -Fq -- "$1" "$SKILL" || { echo "[FAIL] missing: $1"; fail=1; }; }
check "codex-plugin-cc failover"
check 'walk down `recommended_models[]`' # rank-order next-ready fallback
check "claude subagent"    # fallback target
check "executing-plans"    # last-resort inline
[ "$fail" -eq 0 ] && echo "PASS test-degradation"
exit $fail
