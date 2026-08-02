# Workflow Skill Structural Pattern Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development when the harness supports subagents; use superpowers-orchestrator:executing-plans only when the harness has no subagent capability. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** `docs/superpowers/features/workflow-skill-pattern/design.md`

**Goal:** Define one canonical workflow-skill structure and enforce it with a data-driven Bash validator and regression runner.

**Architecture:** `skills/writing-skills/workflow-skill-pattern.md` is the sole runtime source for block identities, markers, tiers, omission conditions, and exclusions. `tests/skills/test-workflow-skill-pattern.sh` parses that document with awk, interprets the parsed marker syntax generically, validates fixture or repository skill trees with grep/awk, and exercises every rule without migrating existing skills.

**Tech Stack:** Bash, grep, awk, Markdown, HTML

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- US-1: skill authors and tooling can read one normative document containing the approved 12-block table and the sole exclusion list.
- US-2: the structural validator can check every non-excluded `skills/*/SKILL.md`, emit exact rule violations, and return a non-zero status for invalid input.
- US-3: conditional omissions pass only when the corresponding README records the block ID inside an exact `## Pattern Omissions` section, and stale records fail.
- US-4: `skills/writing-skills/SKILL.md` directs authors to the canonical pattern instead of maintaining a competing structure template.
- US-5: the test suite proves a stripped or empty block table triggers a loud rule-6 failure.
- US-6: one runner discovers all `tests/skills/test-*.sh` scripts, runs every one, accumulates failures, and prints a success summary only when all pass.

### Artifacts

- `skills/writing-skills/workflow-skill-pattern.md` — normative block table, block guidance, omission format, validator rules, and fenced exclusion list.
- `skills/writing-skills/SKILL.md` — existing structure section reduced to the canonical pointer sentence.
- `tests/skills/test-workflow-skill-pattern.sh` — data-driven validator plus structural contract fixtures for rules 1–6.
- `tests/skills/run-all.sh` — aggregate skill-test runner matching the split-test idiom.

### How to see it working

- Run `bash tests/skills/run-all.sh`; expect `PASS test-workflow-skill-pattern` followed by `ALL SKILL TESTS PASS` once US-1, US-2, US-5, and US-6 are implemented.
- Run `bash tests/split/run-all.sh`; expect `ALL ORCHESTRATOR SPLIT TESTS PASS`, proving this sub-project did not regress the existing split tests.

## Global Constraints

- Implementation is bash + grep + awk only, matching the tests/split/*.sh convention. No new tooling, no new dependency, no new file format.
- The validator script must hold zero block knowledge of its own — every block id, marker, tier, and omit-when condition is parsed from workflow-skill-pattern.md at run time, never hardcoded in the script.
- This plan's tasks never touch skills/*/README.md (other than the pattern doc's own home directory) or any skill's SKILL.md body content — migrating the 18 in-scope skills is sub-project B and out of scope here.

---

## US-1: Pattern doc with normative fenced block table and exclusion fences

### Task 1: Establish the canonical pattern document

**Depends on:** none

**Files:**
- Create: `skills/writing-skills/workflow-skill-pattern.md`
- Modify: none
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: the approved table, omission format, block-10 constraint, validator rules, and D10 exclusion from `docs/superpowers/features/workflow-skill-pattern/design.md`.
- Produces: `workflow-skill-pattern.md` fences `<!-- blocks:start -->` / `<!-- blocks:end -->` and `<!-- exclude:start -->` / `<!-- exclude:end -->`, consumed at runtime by `parse_blocks(pattern_doc)` and `parse_exclusions(pattern_doc)` in Task 2.

**task_type:** documentation_knowledge_transfer

- [ ] **Step 1: Write the failing document-contract test**

Create `tests/skills/test-workflow-skill-pattern.sh` with this complete content:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PATTERN="$ROOT/skills/writing-skills/workflow-skill-pattern.md"
fail=0

check() {
  grep -Fq -- "$2" "$1" || { echo "[FAIL] missing: $2"; fail=1; }
}

if [ ! -f "$PATTERN" ]; then
  echo "[FAIL] no skills/writing-skills/workflow-skill-pattern.md"
  exit 1
fi

rows="$(awk -F'|' '
  /<!-- blocks:start -->/ { inside=1; next }
  /<!-- blocks:end -->/ { inside=0 }
  inside && $2 ~ /^[[:space:]]*[0-9]+[[:space:]]*$/ { count++ }
  END { print count+0 }
' "$PATTERN")"
[ "$rows" -eq 12 ] || { echo "[FAIL] expected 12 block rows, got $rows"; fail=1; }

exclusions="$(awk '
  /<!-- exclude:start -->/ { inside=1; next }
  /<!-- exclude:end -->/ { inside=0 }
  inside && /^[[:space:]]*skills\/[^[:space:]]+\/[[:space:]]*$/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")
    print
  }
' "$PATTERN")"
[ "$exclusions" = 'skills/visual-companion/' ] || {
  echo "[FAIL] exclusion fence must contain only skills/visual-companion/"
  fail=1
}

check "$PATTERN" '## Pattern Omissions'
check "$PATTERN" '- `hard-gate` — skill only reads and reports; no irreversible act.'
check "$PATTERN" '- `token-cost-monitoring` — never invokes a model nor dispatches.'
check "$PATTERN" 'the section must be a plain append-only record, writing one line per dispatch or model-invocation event to the run'
check "$PATTERN" 'No analysis or reporting belongs here.'

for rule in 1 2 3 4 5 6; do
  grep -Eq "^\\| $rule \\|" "$PATTERN" || {
    echo "[FAIL] missing validator rule $rule"
    fail=1
  }
done

[ "$fail" -eq 0 ] && echo 'PASS test-workflow-skill-pattern'
exit "$fail"
```

- [ ] **Step 2: Run the document-contract test to verify RED**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 1 with `[FAIL] no skills/writing-skills/workflow-skill-pattern.md`.

- [ ] **Step 3: Write the complete normative pattern document**

Create `skills/writing-skills/workflow-skill-pattern.md` with this complete content; the fenced 12-row table is copied character for character from the approved request:

````markdown
# Follow the Workflow Skill Structural Pattern

Workflow skills expose the same process at three fidelities: a Checklist is the trackable contract, a Process Flow shows gates and loops, and The Process provides the prose elaboration. Authors use the canonical blocks below so a reader can move between those views without encountering different steps.

## Canonical Blocks

The table is normative. Its `id` values join this document to README omission records, and its validator markers are parsed directly by the structural validator.

<!-- blocks:start -->
| # | id | Block | Validator marker | Tier | Omit when |
|---|---|---|---|---|---|
| 1 | frontmatter | Frontmatter | `name:` + `description:` inside a `---` fence | Mandatory | — |
| 2 | title | Title | `^# ` verb phrase | Mandatory | — |
| 3 | purpose | Purpose | non-heading paragraph directly after the title | Mandatory | — |
| 4 | hard-gate | Hard gate | `<HARD-GATE>` | Conditional | no irreversible act precedes an approval |
| 5 | anti-pattern | Anti-pattern | `## Anti-Pattern: "` | Conditional | baseline testing surfaced no dominant rationalization |
| 6 | checklist | Checklist | `## Checklist` | Mandatory | — |
| 7 | process-flow | Process flow | `## Process Flow` plus a ```dot fence | Conditional | workflow strictly linear — no gates, no loops back |
| 8 | the-process | The process | `## The Process` | Mandatory | — |
| 9 | after-artifact | After the artifact | `## After ` | Conditional | skill produces no durable artifact |
| 10 | token-cost-monitoring | Token-cost monitoring | `## Token-cost Monitoring` | Conditional | skill never invokes a model nor dispatches |
| 11 | red-flags | Red flags | `## Red Flags` | Conditional | skill enforces no discipline an agent could rationalize past |
| 12 | key-principles | Key principles | `## Key Principles` | Mandatory | — |
<!-- blocks:end -->

Mandatory blocks cannot be omitted. Conditional blocks may be omitted only when the skill's README records the matching block ID and reason in the exact format below.

## Block Guidance

1. Frontmatter supplies the discoverable `name` and trigger-only `description` inside the opening YAML fence.
2. Title names the action in a level-one verb-phrase heading.
3. Purpose is the first non-heading paragraph after the title and states the skill's job directly.
4. Hard gate prevents an irreversible action until its approval or prerequisite is satisfied.
5. Anti-pattern names the dominant rationalization found during baseline testing and counters it.
6. Checklist gives the ordered, trackable contract for completing the workflow.
7. Process flow presents non-linear gates, branches, and loops in a `dot` fence.
8. The process elaborates the checklist without adding or removing steps.
9. After the artifact defines the required handoff or follow-up after a durable output is written.
10. Token-cost monitoring records model or dispatch events at the minimized fidelity below.
11. Red flags identify signals that the agent is rationalizing past the workflow's discipline.
12. Key principles close with the compact rules that govern the whole workflow.

## Recording Pattern Omissions

Use this exact README section shape. Each bullet joins to the canonical table through the backticked block ID and gives the skill-specific reason.

```markdown
## Pattern Omissions

- `hard-gate` — skill only reads and reports; no irreversible act.
- `token-cost-monitoring` — never invokes a model nor dispatches.
```

When block 10 (`token-cost-monitoring`) is present, its content expectation under this pattern is minimized: the section must be a plain append-only record, writing one line per dispatch or model-invocation event to the run's JSONL file. No analysis or reporting belongs here. This is an explicit contrast with `skills/brainstorming/SKILL.md`'s current elaborate `## Token-cost monitoring` section, which tracks per-source (worker and orchestrator) records, computes coverage percentages, and carries "never label a partial subtotal complete" language — that style is specific to brainstorming and is not carried into this pattern.

## Validator Rules

| Rule | Condition | Result |
|---|---|---|
| 1 | Mandatory block absent | FAIL — no omission possible |
| 2 | Conditional absent, README lists its id | pass |
| 3 | Conditional absent, README does not list it (or no README) | FAIL |
| 4 | Conditional PRESENT but README lists it as omitted | FAIL — stale record |
| 5 | Present blocks out of table order | FAIL |
| 6 | Block table unparseable or zero rows | FAIL loudly, never pass-by-default |

Every violation is emitted as exactly `skills/<name>: rule<N> <block-id>`. Validation exits non-zero when any violation occurs and exits zero only when no violation occurs.

## Exclusions

The validator reads the only exclusion set from this fence.

<!-- exclude:start -->
skills/visual-companion/
<!-- exclude:end -->
````

- [ ] **Step 4: Run the focused test to verify GREEN**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 0 with `PASS test-workflow-skill-pattern`.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add skills/writing-skills/workflow-skill-pattern.md tests/skills/test-workflow-skill-pattern.sh
git commit -m "docs: define workflow skill pattern"
```

The worker never runs these commands.

**US-1 Checkpoint:**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 0; the output is `PASS test-workflow-skill-pattern`; the parser-facing table has exactly 12 rows between the block fences; the exclusion fence contains only `skills/visual-companion/`; no validator logic contains a block identity; after Task 4, the same command also confirms the D1 pointer in `skills/writing-skills/SKILL.md`.

## US-2: Structural validator script that parses the doc and checks all in-scope skills

### Task 2: Implement the data-driven structural validator

**Depends on:** Task 1

**Files:**
- Create: none
- Modify: `tests/skills/test-workflow-skill-pattern.sh`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `workflow-skill-pattern.md` table rows with pipe-delimited columns `#`, `id`, `Block`, `Validator marker`, `Tier`, and `Omit when`, plus the fenced exclusion paths.
- Produces: `parse_blocks(pattern_doc)` emitting tab-delimited `id`, `validator_marker`, `tier`, and `omit_when` rows; `validate_tree(pattern_doc, repo_root)` emitting exact `skills/<name>: rule<N> <block-id>` lines and returning 0 only for a violation-free tree; CLI `--validate <pattern-doc> <repo-root>`.

**task_type:** implementation_coding

- [ ] **Step 1: Add concrete failing fixtures for validator rules 1–5**

Before the final PASS/exit lines in `tests/skills/test-workflow-skill-pattern.sh`, add this complete fixture harness. The temporary table deliberately uses synthetic IDs so the validator itself still gets all real block knowledge only from the runtime document:

```bash
validate_tree() {
  echo '[FAIL] validate_tree not implemented' >&2
  return 99
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FIXTURE_PATTERN="$TMP/workflow-skill-pattern.md"

cat > "$FIXTURE_PATTERN" <<'EOF'
<!-- blocks:start -->
| # | id | Block | Validator marker | Tier | Omit when |
|---|---|---|---|---|---|
| 1 | mandatory-1 | Mandatory one | `## Mandatory One` | Mandatory | — |
| 2 | conditional-1 | Conditional one | `## Conditional One` | Conditional | not needed |
| 3 | mandatory-2 | Mandatory two | `## Mandatory Two` | Mandatory | — |
| 4 | conditional-2 | Conditional two | `## Conditional Two` | Conditional | not needed |
| 5 | mandatory-3 | Mandatory three | `## Mandatory Three` | Mandatory | — |
| 6 | conditional-3 | Conditional three | `## Conditional Three` | Conditional | not needed |
| 7 | mandatory-4 | Mandatory four | `## Mandatory Four` | Mandatory | — |
| 8 | conditional-4 | Conditional four | `## Conditional Four` | Conditional | not needed |
| 9 | mandatory-5 | Mandatory five | `## Mandatory Five` | Mandatory | — |
| 10 | conditional-5 | Conditional five | `## Conditional Five` | Conditional | not needed |
| 11 | mandatory-6 | Mandatory six | `## Mandatory Six` | Mandatory | — |
| 12 | conditional-6 | Conditional six | `## Conditional Six` | Conditional | not needed |
<!-- blocks:end -->
<!-- exclude:start -->
skills/excluded/
<!-- exclude:end -->
EOF

make_case() {
  local root="$1"
  mkdir -p "$root/skills/demo" "$root/skills/excluded"
  cat > "$root/skills/demo/SKILL.md" <<'EOF'
## Mandatory One
## Mandatory Two
## Mandatory Three
## Mandatory Four
## Mandatory Five
## Mandatory Six
EOF
  cat > "$root/skills/demo/README.md" <<'EOF'
## Pattern Omissions

- `conditional-1` — not needed.
- `conditional-2` — not needed.
- `conditional-3` — not needed.
- `conditional-4` — not needed.
- `conditional-5` — not needed.
- `conditional-6` — not needed.
EOF
  printf '%s\n' '# deliberately invalid but excluded' > "$root/skills/excluded/SKILL.md"
}

expect_violation() {
  local root="$1" expected="$2" output
  if output="$(validate_tree "$FIXTURE_PATTERN" "$root" 2>&1)"; then
    echo "[FAIL] expected violation: $expected"
    fail=1
    return
  fi
  printf '%s\n' "$output" | grep -Fxq -- "$expected" || {
    echo "[FAIL] missing violation: $expected"
    fail=1
  }
}

GOOD="$TMP/good"
make_case "$GOOD"
if ! output="$(validate_tree "$FIXTURE_PATTERN" "$GOOD" 2>&1)"; then
  echo "[FAIL] rule2/all-present fixture rejected: $output"
  fail=1
elif [ -n "$output" ]; then
  echo "[FAIL] valid fixture emitted output: $output"
  fail=1
fi

RULE1="$TMP/rule1"
make_case "$RULE1"
awk '$0 != "## Mandatory Two"' "$RULE1/skills/demo/SKILL.md" > "$RULE1/skill.tmp"
mv "$RULE1/skill.tmp" "$RULE1/skills/demo/SKILL.md"
expect_violation "$RULE1" 'skills/demo: rule1 mandatory-2'

RULE3="$TMP/rule3"
make_case "$RULE3"
rm "$RULE3/skills/demo/README.md"
expect_violation "$RULE3" 'skills/demo: rule3 conditional-1'

RULE4="$TMP/rule4"
make_case "$RULE4"
awk '{ print; if ($0 == "## Mandatory One") print "## Conditional One" }' \
  "$RULE4/skills/demo/SKILL.md" > "$RULE4/skill.tmp"
mv "$RULE4/skill.tmp" "$RULE4/skills/demo/SKILL.md"
expect_violation "$RULE4" 'skills/demo: rule4 conditional-1'

RULE5="$TMP/rule5"
make_case "$RULE5"
cat > "$RULE5/skills/demo/SKILL.md" <<'EOF'
## Mandatory Two
## Mandatory One
## Mandatory Three
## Mandatory Four
## Mandatory Five
## Mandatory Six
EOF
expect_violation "$RULE5" 'skills/demo: rule5 mandatory-2'
```

- [ ] **Step 2: Run the fixture suite to verify RED**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: non-zero exit with `[FAIL] validate_tree not implemented`; the rule fixtures cannot pass through the stub.

- [ ] **Step 3: Replace the stub with the complete parser and validator**

Replace only the `validate_tree` stub from Step 1 with this complete implementation. It parses every table field at runtime; the marker interpreter recognizes table syntax shapes, not block IDs or literal block names:

```bash
parse_blocks() {
  local pattern_doc="$1"
  awk -F'|' '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    /<!-- blocks:start -->/ { inside=1; next }
    /<!-- blocks:end -->/ { inside=0 }
    inside && $2 ~ /^[[:space:]]*[0-9]+[[:space:]]*$/ {
      id=trim($3)
      marker=trim($5)
      tier=trim($6)
      omit_when=trim($7)
      if (id == "" || marker == "" || (tier != "Mandatory" && tier != "Conditional")) bad=1
      printf "%s\t%s\t%s\t%s\n", id, marker, tier, omit_when
      rows++
    }
    END {
      if (bad || rows < 12) {
        print "skills/writing-skills: rule6 block-table" > "/dev/stderr"
        exit 1
      }
    }
  ' "$pattern_doc"
}

parse_exclusions() {
  local pattern_doc="$1"
  awk '
    /<!-- exclude:start -->/ { inside=1; next }
    /<!-- exclude:end -->/ { inside=0 }
    inside && /^[[:space:]]*skills\/[^[:space:]]+\/[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      print
    }
  ' "$pattern_doc"
}

marker_line() {
  local skill_file="$1" marker="$2" first second first_line token
  local tokens=()

  while IFS= read -r token; do
    [ -n "$token" ] && tokens[${#tokens[@]}]="$token"
  done < <(printf '%s\n' "$marker" | awk -F'`' '{ for (i=2; i<=NF; i+=2) if ($i != "") print $i }')

  if [ "${#tokens[@]}" -eq 0 ]; then
    awk '
      /^# / { after_title=1; next }
      after_title && /^[[:space:]]*$/ { next }
      after_title {
        if ($0 !~ /^#/) print NR
        exit
      }
    ' "$skill_file"
    return
  fi

  if [[ "$marker" == *" inside a "* ]] && [ "${#tokens[@]}" -ge 3 ]; then
    awk -v first="${tokens[0]}" -v second="${tokens[1]}" -v fence="${tokens[2]}" '
      $0 == fence && !inside { inside=1; fence_line=NR; next }
      $0 == fence && inside { if (have_first && have_second) print fence_line; exit }
      inside && index($0, first) == 1 { have_first=1 }
      inside && index($0, second) == 1 { have_second=1 }
    ' "$skill_file"
    return
  fi

  first="${tokens[0]}"
  if [[ "$marker" == *" plus a "* ]]; then
    second="${marker#* plus a }"
    second="${second%% *}"
    first_line="$(grep -nF -- "$first" "$skill_file" | awk -F: 'NR == 1 { print $1 }')"
    [ -n "$first_line" ] || return 1
    awk -v start="$first_line" -v needle="$second" '
      NR >= start && index($0, needle) { print start; exit }
    ' "$skill_file"
    return
  fi

  if [[ "$first" == ^* ]]; then
    grep -nE -- "$first" "$skill_file" | awk -F: 'NR == 1 { print $1 }'
  else
    grep -nF -- "$first" "$skill_file" | awk -F: 'NR == 1 { print $1 }'
  fi
}

omits_block() {
  local readme="$1" id="$2"
  [ -f "$readme" ] && grep -Fq -- "- \`$id\` — " "$readme"
}

validate_tree() {
  local pattern_doc="$1" repo_root="$2" rows exclusions
  local skill_file skill_dir readme id marker tier omit_when line omitted last_line
  local fail=0

  if ! rows="$(parse_blocks "$pattern_doc")"; then
    return 1
  fi
  exclusions="$(parse_exclusions "$pattern_doc")"

  for skill_file in "$repo_root"/skills/*/SKILL.md; do
    [ -f "$skill_file" ] || continue
    skill_dir="${skill_file#"$repo_root"/}"
    skill_dir="${skill_dir%/SKILL.md}"
    printf '%s\n' "$exclusions" | grep -Fxq -- "$skill_dir/" && continue
    readme="$repo_root/$skill_dir/README.md"
    last_line=0

    while IFS=$'\t' read -r id marker tier omit_when; do
      line="$(marker_line "$skill_file" "$marker" || true)"
      omitted=0
      omits_block "$readme" "$id" && omitted=1

      if [ -z "$line" ]; then
        if [ "$tier" = "Mandatory" ]; then
          echo "$skill_dir: rule1 $id"
          fail=1
        elif [ "$omitted" -eq 0 ]; then
          echo "$skill_dir: rule3 $id"
          fail=1
        fi
        continue
      fi

      if [ "$tier" = "Conditional" ] && [ "$omitted" -eq 1 ]; then
        echo "$skill_dir: rule4 $id"
        fail=1
      fi

      if [ "$line" -lt "$last_line" ]; then
        echo "$skill_dir: rule5 $id"
        fail=1
      else
        last_line="$line"
      fi
    done < <(printf '%s\n' "$rows")
  done

  return "$fail"
}
```

Add this CLI branch immediately after the validator functions and before the fixture harness:

```bash
if [ "${1:-}" = '--validate' ]; then
  [ "$#" -eq 3 ] || {
    echo 'usage: test-workflow-skill-pattern.sh --validate <pattern-doc> <repo-root>' >&2
    exit 2
  }
  validate_tree "$2" "$3"
  exit $?
fi
```

- [ ] **Step 4: Run the fixture suite to verify GREEN**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 0 with `PASS test-workflow-skill-pattern`; the good fixture proves rule 2 and the all-present success path, while the invalid fixtures assert exact rule 1, 3, 4, and 5 output lines. Rule 6 is implemented by `parse_blocks` and receives its stripped-table self-check in Task 5.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/skills/test-workflow-skill-pattern.sh
git commit -m "test: add workflow pattern validator"
```

The worker never runs these commands.

**US-2 Checkpoint:**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 0 with `PASS test-workflow-skill-pattern`; a valid non-excluded fixture emits no violations, the excluded invalid fixture is ignored, mandatory absence emits `skills/demo: rule1 mandatory-2`, a documented conditional absence passes, an undocumented conditional absence emits `skills/demo: rule3 conditional-1`, a stale omission emits `skills/demo: rule4 conditional-1`, and out-of-order blocks emit `skills/demo: rule5 mandatory-2`. `parse_blocks` emits `id`, `validator_marker`, `tier`, and `omit_when` for all 12 pipe-delimited rows and rejects fewer than 12 rows with rule 6.

## US-3: README `## Pattern Omissions` section format specified and enforced by rules 2–4

### Task 3: Restrict omission records to the exact README section

**Depends on:** Task 2

**Files:**
- Create: none
- Modify: `tests/skills/test-workflow-skill-pattern.sh`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `omits_block(readme, id)` and the exact bullet prefix ``- `<id>` — `` from Task 2.
- Produces: section-scoped `omits_block(readme, id)` behavior that reads only between `## Pattern Omissions` and the next level-two heading.

**task_type:** implementation_coding

- [ ] **Step 1: Add the failing out-of-section and no-README cases**

Add these complete cases after the existing rule-5 fixture in `tests/skills/test-workflow-skill-pattern.sh`:

```bash
OUTSIDE="$TMP/outside-section"
make_case "$OUTSIDE"
cat > "$OUTSIDE/skills/demo/README.md" <<'EOF'
# Demo

- `conditional-1` — this bullet is outside the omission section.

## Pattern Omissions

- `conditional-2` — not needed.
- `conditional-3` — not needed.
- `conditional-4` — not needed.
- `conditional-5` — not needed.
- `conditional-6` — not needed.
EOF
expect_violation "$OUTSIDE" 'skills/demo: rule3 conditional-1'

STALE_SCOPED="$TMP/stale-scoped"
make_case "$STALE_SCOPED"
awk '{ print; if ($0 == "## Mandatory One") print "## Conditional One" }' \
  "$STALE_SCOPED/skills/demo/SKILL.md" > "$STALE_SCOPED/skill.tmp"
mv "$STALE_SCOPED/skill.tmp" "$STALE_SCOPED/skills/demo/SKILL.md"
expect_violation "$STALE_SCOPED" 'skills/demo: rule4 conditional-1'
```

- [ ] **Step 2: Run the focused test to verify RED**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: non-zero exit with `[FAIL] expected violation: skills/demo: rule3 conditional-1` because the naive whole-file grep incorrectly accepts the out-of-section bullet.

- [ ] **Step 3: Replace whole-file omission matching with section-scoped awk**

Replace `omits_block` with this complete implementation:

```bash
omits_block() {
  local readme="$1" id="$2"
  [ -f "$readme" ] || return 1
  awk -v id="$id" '
    /^## Pattern Omissions$/ { inside=1; next }
    inside && /^## / { exit }
    inside && index($0, "- `" id "` — ") == 1 { found=1 }
    END { exit !found }
  ' "$readme"
}
```

- [ ] **Step 4: Run the omission fixtures to verify GREEN**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 0 with `PASS test-workflow-skill-pattern`; a valid omission bullet passes rule 2, a bullet outside the exact section and a missing README both emit rule 3, and a present block listed inside the section emits rule 4.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/skills/test-workflow-skill-pattern.sh
git commit -m "test: enforce scoped pattern omissions"
```

The worker never runs these commands.

**US-3 Checkpoint:**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 0 with `PASS test-workflow-skill-pattern`; the pattern doc contains the exact README example, valid backticked IDs inside `## Pattern Omissions` satisfy rule 2, stale in-section IDs trigger rule 4, out-of-section IDs do not count, and an absent README triggers rule 3.

## US-4: writing-skills/SKILL.md generic structure section replaced by a pointer

### Task 4: Replace the competing structure template with the canonical pointer

**Depends on:** Task 1

**Files:**
- Create: none
- Modify: `skills/writing-skills/SKILL.md`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: canonical document path `skills/writing-skills/workflow-skill-pattern.md` from Task 1.
- Produces: the exact single-sentence body under `## SKILL.md Structure`, consumed by skill authors and asserted by `check_pointer_section(skill_file)`.

**task_type:** documentation_knowledge_transfer

- [ ] **Step 1: Add the failing exact-body assertion**

Add this complete helper beside the other assertion helpers in `tests/skills/test-workflow-skill-pattern.sh`:

```bash
check_pointer_section() {
  local skill_file="$1" expected actual
  expected='See `skills/writing-skills/workflow-skill-pattern.md` for the canonical block structure all workflow skills must follow.'
  actual="$(awk '
    /^## SKILL.md Structure$/ { inside=1; next }
    inside && /^## / { exit }
    inside && NF { print }
  ' "$skill_file")"
  [ "$actual" = "$expected" ] || {
    echo '[FAIL] ## SKILL.md Structure must contain only the canonical pointer'
    fail=1
  }
}
```

Add this invocation before the final PASS/exit lines:

```bash
check_pointer_section "$ROOT/skills/writing-skills/SKILL.md"
```

- [ ] **Step 2: Run the focused test to verify RED**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: non-zero exit with `[FAIL] ## SKILL.md Structure must contain only the canonical pointer`.

- [ ] **Step 3: Apply the exact diff-equivalent section replacement**

Apply this exact before/after diff; no line outside the `## SKILL.md Structure` body changes:

````diff
 ## SKILL.md Structure
-
-**Frontmatter (YAML):**
-- Two required fields: `name` and `description` (see [agentskills.io/specification](https://agentskills.io/specification) for all supported fields)
-- Max 1024 characters total
-- `name`: Use letters, numbers, and hyphens only (no parentheses, special chars)
-- `description`: Third-person, describes ONLY when to use (NOT what it does)
-  - Start with "Use when..." to focus on triggering conditions
-  - Include specific symptoms, situations, and contexts
-  - **NEVER summarize the skill's process or workflow** (see SDO section for why)
-  - Keep under 500 characters if possible
-
-```markdown
----
-name: Skill-Name-With-Hyphens
-description: Use when [specific triggering conditions and symptoms]
----
-
-# Skill Name
-
-## Overview
-What is this? Core principle in 1-2 sentences.
-
-## When to Use
-[Small inline flowchart IF decision non-obvious]
-
-Bullet list with SYMPTOMS and use cases
-When NOT to use
-
-## Core Pattern (for techniques/patterns)
-Before/after code comparison
-
-## Quick Reference
-Table or bullets for scanning common operations
-
-## Implementation
-Inline code for simple patterns
-Link to file for heavy reference or reusable tools
-
-## Common Mistakes
-What goes wrong + fixes
-
-## Real-World Impact (optional)
-Concrete results
-```
-
+
+See `skills/writing-skills/workflow-skill-pattern.md` for the canonical block structure all workflow skills must follow.
+
 ## Skill Discovery Optimization (SDO)
````

- [ ] **Step 4: Run the exact-body and regression tests to verify GREEN**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 0 with `PASS test-workflow-skill-pattern`.

Run: `bash tests/split/run-all.sh`

Expected: exit 0 with `ALL ORCHESTRATOR SPLIT TESTS PASS`.

Run: `bash tests/skills/test-workflow-skill-pattern.sh --validate skills/writing-skills/workflow-skill-pattern.md . 2>&1 | grep -q '^skills/writing-skills:'`

Expected: exit 0 from grep, proving `skills/writing-skills/SKILL.md` is included rather than exempt; its remaining structural violations are intentionally resolved only by the separately specified sub-project B migration.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add skills/writing-skills/SKILL.md tests/skills/test-workflow-skill-pattern.sh
git commit -m "docs: point writing skills to pattern"
```

The worker never runs these commands.

**US-4 Checkpoint:**

Run: `bash tests/skills/test-workflow-skill-pattern.sh && bash tests/split/run-all.sh`

Expected: both commands exit 0; the first prints `PASS test-workflow-skill-pattern` and proves the `## SKILL.md Structure` body is exactly the pointer sentence with no competing list or format; the second prints `ALL ORCHESTRATOR SPLIT TESTS PASS`. The Task 4 `--validate` probe separately proves `skills/writing-skills/SKILL.md` is included rather than exempt.

## US-5: Validator self-check fixture proving rule 6 fails loudly

### Task 5: Add the stripped-table self-check

**Depends on:** Task 2

**Files:**
- Create: none
- Modify: `tests/skills/test-workflow-skill-pattern.sh`
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: `parse_blocks(pattern_doc)` and `validate_tree(pattern_doc, repo_root)` from Task 2.
- Produces: `self_check_rule6(pattern_doc, fixture_root, temp_dir)` returning 0 only when a stripped table is rejected and the exact loud message `skills/writing-skills: rule6 block-table` is observed.

**task_type:** testing_qa

- [ ] **Step 1: Add a failing call to the required self-check fixture**

Add this exact invocation after the good fixture is created and before the rule-1 fixture:

```bash
self_check_rule6 "$PATTERN" "$GOOD" "$TMP" || fail=1
```

- [ ] **Step 2: Run the focused test to verify RED**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: non-zero exit with `self_check_rule6: command not found`.

- [ ] **Step 3: Implement the complete stripped-table self-check**

Add this function above the fixture harness:

```bash
self_check_rule6() {
  local pattern_doc="$1" fixture_root="$2" temp_dir="$3"
  local stripped="$temp_dir/stripped-workflow-skill-pattern.md" output

  awk '
    /<!-- blocks:start -->/ { print; inside=1; next }
    /<!-- blocks:end -->/ { inside=0; print; next }
    !inside { print }
  ' "$pattern_doc" > "$stripped"

  if output="$(validate_tree "$stripped" "$fixture_root" 2>&1)"; then
    echo '[FAIL] rule6 accepted a stripped block table'
    return 1
  fi

  printf '%s\n' "$output" | grep -Fxq -- 'skills/writing-skills: rule6 block-table' || {
    echo '[FAIL] rule6 did not emit the loud block-table failure'
    return 1
  }
}
```

- [ ] **Step 4: Run the self-check and regression suites to verify GREEN**

Run: `bash tests/skills/test-workflow-skill-pattern.sh`

Expected: exit 0 with `PASS test-workflow-skill-pattern`; the stripped real table produces a non-zero nested validator status and the exact loud rule-6 line, while the valid real table still parses at least 12 rows.

Run: `bash tests/split/run-all.sh`

Expected: exit 0 with `ALL ORCHESTRATOR SPLIT TESTS PASS`.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/skills/test-workflow-skill-pattern.sh
git commit -m "test: prove block parser fails closed"
```

The worker never runs these commands.

**US-5 Checkpoint:**

Run: `bash tests/skills/test-workflow-skill-pattern.sh && bash tests/split/run-all.sh`

Expected: both commands exit 0; the first prints `PASS test-workflow-skill-pattern`, proves a stripped or zero-row table is rejected with `skills/writing-skills: rule6 block-table`, and proves the real table yields at least 12 parsed rows; the second prints `ALL ORCHESTRATOR SPLIT TESTS PASS`.

## US-6: tests/skills/run-all.sh wired in tests/split/run-all.sh style

### Task 6: Add the aggregate skill-test runner

**Depends on:** Task 2, Task 3, Task 4, Task 5

**Files:**
- Create: `tests/skills/run-all.sh`
- Modify: none
- Test: `tests/skills/test-workflow-skill-pattern.sh`

**Interfaces:**
- Consumes: same-directory `test-*.sh` scripts, including `test-workflow-skill-pattern.sh`.
- Produces: `bash tests/skills/run-all.sh`, which executes every matching shell test in glob order, accumulates failure status in `fail`, prints `ALL SKILL TESTS PASS` only on success, and exits with the accumulated code.

**task_type:** testing_qa

- [ ] **Step 1: Run the absent aggregate entry point to verify RED**

Run: `bash tests/skills/run-all.sh`

Expected: non-zero exit with `No such file or directory`.

- [ ] **Step 2: Create the runner by reusing the split runner's exact shell idiom**

Create `tests/skills/run-all.sh` with this complete content:

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
fail=0
for t in "$DIR"/test-*.sh; do echo "== $(basename "$t")"; bash "$t" || fail=1; done
[ "$fail" -eq 0 ] && echo "ALL SKILL TESTS PASS"
exit $fail
```

- [ ] **Step 3: Run both aggregate suites to verify GREEN and no regression**

Run: `bash tests/skills/run-all.sh`

Expected: exit 0; output includes `== test-workflow-skill-pattern.sh`, `PASS test-workflow-skill-pattern`, and final summary `ALL SKILL TESTS PASS`.

Run: `bash tests/split/run-all.sh`

Expected: exit 0 with final summary `ALL ORCHESTRATOR SPLIT TESTS PASS`.

**Orchestrator Git Bookkeeping (not a worker step):**

After a successful worker response or successful inline task execution with passing tests, the orchestrator runs this before generating the task review package:

```bash
git add tests/skills/run-all.sh
git commit -m "test: add skill test runner"
```

The worker never runs these commands.

**US-6 Checkpoint:**

Run: `bash tests/skills/run-all.sh && bash tests/split/run-all.sh`

Expected: both commands exit 0; the skill runner executes every same-directory `test-*.sh` in glob order without short-circuiting, prints `ALL SKILL TESTS PASS`, and the unchanged split runner prints `ALL ORCHESTRATOR SPLIT TESTS PASS`.
