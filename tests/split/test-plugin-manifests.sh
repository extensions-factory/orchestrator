#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
for m in .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json .cursor-plugin/plugin.json .kimi-plugin/plugin.json gemini-extension.json; do
  f="$ROOT/$m"; [ -f "$f" ] || { echo "[SKIP] no $m"; continue; }
  grep -Fq -- "superpowers-orchestrator" "$f" || { echo "[FAIL] $m not renamed to superpowers-orchestrator"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "PASS orchestrator manifests"
exit $fail
