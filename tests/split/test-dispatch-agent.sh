#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/dispatch-agent/SKILL.md"
fail=0
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
test -f "$SKILL" || { echo "[FAIL] no dispatch-agent/SKILL.md"; exit 1; }
check "$SKILL" "name: dispatch-agent"
check "$SKILL" "sdlc-model-routing.json"
check "$SKILL" "message-protocol.json"
check "$SKILL" ".superpowers/ledger.jsonl"
check "$SKILL" "provider_diversity"
check "$SKILL" "Claude Code"          # provider->agent map present
check "$SKILL" "codex-plugin-cc failover"
check "$SKILL" "claude subagent"
check "$SKILL" "executing-plans"
check "$SKILL" "riso-tech:orchestrator-split"
[ "$fail" -eq 0 ] && echo "PASS test-dispatch-agent"
exit $fail
