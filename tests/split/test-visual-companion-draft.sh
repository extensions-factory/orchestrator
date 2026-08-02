#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DRAFT="$ROOT/skills/visual-companion"
BRAINSTORM="$ROOT/skills/brainstorming"
fail=0
check_file(){ [[ -f "$1" ]] || { echo "[FAIL] missing: ${1#"$ROOT/"}"; fail=1; }; }
check(){ grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }; }
reject(){ grep -Fiq -- "$2" "$1" && { echo "[FAIL] forbidden: $2"; fail=1; } || true; }

for path in \
  "$DRAFT/SKILL.md" \
  "$DRAFT/guide.md" \
  "$DRAFT/scripts/helper.js" \
  "$DRAFT/scripts/server.cjs" \
  "$DRAFT/scripts/start-server.sh" \
  "$DRAFT/scripts/stop-server.sh" \
  "$DRAFT/templates/frame-template.html"; do
  check_file "$path"
done

if [[ -f "$DRAFT/SKILL.md" ]]; then
  check "$DRAFT/SKILL.md" 'name: visual-companion'
  check "$DRAFT/SKILL.md" '# Visual Companion (Draft)'
  check "$DRAFT/SKILL.md" 'only when the human explicitly requests'
  check "$DRAFT/SKILL.md" 'Do not invoke it automatically'
  check "$DRAFT/SKILL.md" '[guide.md](guide.md)'
fi

reject "$BRAINSTORM/SKILL.md" 'visual companion'
reject "$BRAINSTORM/README.md" 'visual companion'
reject "$BRAINSTORM/README.md" '20-design/brainstorm'

[[ ! -e "$BRAINSTORM/visual-companion.md" ]] || { echo '[FAIL] brainstorming still owns visual-companion.md'; fail=1; }
[[ ! -d "$BRAINSTORM/scripts" ]] || { echo '[FAIL] brainstorming still owns companion scripts'; fail=1; }
[[ ! -e "$BRAINSTORM/templates/frame-template.html" ]] || { echo '[FAIL] brainstorming still owns companion frame'; fail=1; }

[[ "$fail" -eq 0 ]] && echo 'PASS test-visual-companion-draft'
exit "$fail"
