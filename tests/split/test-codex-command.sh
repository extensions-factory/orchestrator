#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOOKUP="$ROOT/scripts/model-lookup.sh"
SKILL="$ROOT/skills/dispatch-agent/SKILL.md"

codex="$(bash "$LOOKUP" --command implementation_coding 1 2>&1 || true)"
grep -Fq 'agent=codex' <<<"$codex"
grep -Fq 'write=true' <<<"$codex"
grep -Fq '/codex:rescue --write --model' <<<"$codex"

other="$(bash "$LOOKUP" --command architecture_design 1 2>&1 || true)"
grep -Fq 'agent=claude' <<<"$other"
! grep -Fq '/codex:rescue' <<<"$other"

grep -Fq 'If the resolved `agent` is `codex`' "$SKILL"
grep -Fq '/codex:rescue --write --model <model> --effort <effort> "<prompt>"' "$SKILL"
grep -Fq '"Claude Code" → claude' "$SKILL"
grep -Fq '"Antigravity CLI" → antigravity' "$SKILL"

echo 'PASS test-codex-command'
