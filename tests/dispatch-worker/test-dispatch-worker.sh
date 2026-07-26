#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/dispatch-agent/SKILL.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
check() {
  local needle="$1"
  grep -Fq -- "$needle" "$SKILL" || fail "missing skill contract: $needle"
}

check 'Step 4a: Read the provider rescue doc'
check '<plugin-root>/<provider>/<ver>/commands/rescue.md'
check 'flag surface, effort enum, model aliases, plugin root, and profile policy'
check 'Cache this read once per provider per session.'
check 'Ignore the entire "Execution mode" section.'
check '`none|minimal|low|medium|high|xhigh`'
check '`low|medium|high`'

echo "PASS test-dispatch-worker"
