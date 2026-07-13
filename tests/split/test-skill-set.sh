#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
expected="backlog-refinement brainstorming dispatch-agent dispatching-parallel-agents executing-plans finishing-a-development-branch project-kickoff requesting-code-review sprint-retrospective subagent-driven-development using-git-worktrees using-superpowers writing-plans writing-skills"
actual="$(cd "$ROOT/skills" && ls -d */ | sed 's#/##' | sort | tr '\n' ' ' | sed 's/ $//')"
exp_sorted="$(echo "$expected" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')"
if [ "$actual" = "$exp_sorted" ]; then echo "PASS orchestrator skill set"; else
  echo "[FAIL] orchestrator skills mismatch"; echo "  expected: $exp_sorted"; echo "  actual:   $actual"; exit 1; fi
