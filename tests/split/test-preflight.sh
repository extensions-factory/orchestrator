#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/dispatch-agent/SKILL.md"
fail=0
check(){ grep -Fq -- "$1" "$SKILL" || { echo "[FAIL] missing: $1"; fail=1; }; }
check "Provider-readiness preflight"
check "codex:setup"          # codex readiness command
check "/agy:setup"           # antigravity readiness command
check "not ready"            # degrade-on-not-ready language
[ "$fail" -eq 0 ] && echo "PASS test-preflight"
exit $fail
