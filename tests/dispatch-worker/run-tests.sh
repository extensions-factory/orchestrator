#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== dispatch-worker tests ==="
for test_file in "$SCRIPT_DIR"/test-*.sh; do
  echo
  echo ">>> $test_file"
  bash "$test_file"
done
echo
echo "=== All dispatch-worker tests passed ==="
