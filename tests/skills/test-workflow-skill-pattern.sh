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
  grep -Eq "^\| $rule \|" "$PATTERN" || {
    echo "[FAIL] missing validator rule $rule"
    fail=1
  }
done

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

if [ "${1:-}" = '--validate' ]; then
  [ "$#" -eq 3 ] || {
    echo 'usage: test-workflow-skill-pattern.sh --validate <pattern-doc> <repo-root>' >&2
    exit 2
  }
  validate_tree "$2" "$3"
  exit $?
fi

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

[ "$fail" -eq 0 ] && echo 'PASS test-workflow-skill-pattern'
exit "$fail"
