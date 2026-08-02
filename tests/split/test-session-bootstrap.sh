#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/using-superpowers/SKILL.md"
README="$ROOT/skills/using-superpowers/README.md"
fail=0

check() {
  local file="$1" needle="$2" label="$3"
  if grep -Fq -- "$needle" "$file"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label"
    fail=1
  fi
}

reject() {
  local file="$1" needle="$2" label="$3"
  if grep -Fq -- "$needle" "$file"; then
    echo "[FAIL] $label"
    fail=1
  else
    echo "[PASS] $label"
  fi
}

check "$README" '## Description' 'README documents the skill description'
check "$README" '## Inputs' 'README documents inputs'
check "$README" '## Durable Output' 'README documents the durable output'
check "$README" '## Human Decisions' 'README documents human decisions'
check "$README" '## Handoff' 'README documents the handoff'

check "$SKILL" 'Create Session' 'bootstrap asks whether to create a session'
check "$SKILL" 'Resume Session' 'bootstrap asks whether to resume a session'
check "$SKILL" 'The only manifest lives on `main` at `docs/superpower/manifest.json`' 'main owns the single manifest'
check "$SKILL" 'Git branches and worktrees are the source of truth for resumable sessions' 'Git workspaces identify concurrent sessions'
check "$SKILL" 'Create Session creates a new workspace and appends its workspace entry' 'create appends a session'
check "$SKILL" 'human confirms one exact `workspace.type` and `workspace.target`' 'create never invents its workspace'
check "$SKILL" 'Resume Session selects an existing Git workspace and matches its entry' 'resume matches an existing session'
check "$SKILL" 'Only a mismatch in the selected session blocks' 'unrelated stale sessions do not block valid work'
check "$SKILL" 'MUST NOT overwrite other in-process session entries' 'concurrent sessions remain registered'
check "$SKILL" 'Every lifecycle phase MUST read the manifest from `main`' 'phases read the global manifest'
check "$SKILL" 'select the session entry matching its current branch or worktree' 'phases select their own session entry'
check "$SKILL" 'Read main:docs/superpower/manifest.json before acting' 'worker handoffs carry the main-manifest read instruction'
check "$SKILL" 'workspace.type' 'bootstrap records workspace type'
check "$SKILL" 'workspace.target' 'bootstrap records workspace target'

reject "$SKILL" 'session: create | resume' 'skill does not persist bootstrap actions'
reject "$SKILL" 'Each workspace owns its own' 'skill has no workspace-local manifests'
reject "$SKILL" 'from the current workspace before acting' 'skill never treats workspace copies as authoritative'

check "$README" '"type": "branch"' 'README documents branch workspaces'
check "$README" '"type": "worktree"' 'README documents worktree workspaces'
check "$README" '"sessions": [' 'README documents multiple in-process sessions'
reject "$README" '"session": "create"' 'README does not store create as durable state'
reject "$README" '"session": "resume"' 'README does not store resume as durable state'
reject "$README" 'Each branch or worktree owns its own' 'README has no workspace-local manifests'
reject "$README" '../../docs/orchestrator-workflow.md' 'README has no deleted workflow link'

[ "$fail" -eq 0 ] && echo 'PASS test-session-bootstrap'
exit "$fail"
