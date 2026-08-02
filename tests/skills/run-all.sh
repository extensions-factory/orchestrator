#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
fail=0
for t in "$DIR"/test-*.sh; do echo "== $(basename "$t")"; bash "$t" || fail=1; done
[ "$fail" -eq 0 ] && echo "ALL SKILL TESTS PASS"
exit $fail
