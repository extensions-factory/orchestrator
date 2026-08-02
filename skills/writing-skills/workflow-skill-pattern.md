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
