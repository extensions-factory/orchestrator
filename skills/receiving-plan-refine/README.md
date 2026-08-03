# Receiving Plan Refine

## Description

Evaluates independent plan-review findings, applies only approval-preserving corrections, and prevents proposed build-decision changes from bypassing their human gate.

## Inputs

- The current workspace and its exactly matching session in the single `main:docs/superpower/manifest.json`.
- The complete approved `writing_plans` record and workflow ID.
- Exact current-workspace plan/spec paths and hashes plus the unique findings path handed off by Requesting Plan Refine; author/reviewer provenance comes from the active run ledger.
- Exact per-invocation or comparable cumulative token metadata exposed by the harness/provider.

## Durable Output

Each review turn keeps its immutable `findings-<turn>.md` and writes a matching `resolution-<turn>.md` with write-ahead finding dispositions, plan/HTML hashes, regeneration state, and one stable handoff ID. Approval-preserving corrections update the tracked `plan.md` and synchronized `plan.html`. Receiving-only orchestrator usage is stored separately.

## Token-cost Monitoring

`.superpowers/runs/<workflow-id>/receiving-plan-refine-token-cost.jsonl` records every receiving-phase orchestrator invocation with exact-or-null counts. D11 worker and Requesting Plan Refine costs remain in their owning phase. Reports show measured totals and separate full-record, input-field, and output-field coverage.

## Human Decisions

Receiving never changes the approved scope, exclusions, ordering, files, interfaces, tests, verification, or manifest. Any proposed edit whose actual effect would change an approved value is recorded as `human_decision_required` and routed to Writing Plans' Final build decision gate. Refine and Execute remain blocked until that gate resolves it.

## Handoff

After rereading the selected session and revalidating current artifacts, Receiving sends exactly one route: Writing Plans for a decision proposal, Requesting Plan Refine for another review, or the capability-selected execution workflow. The handoff carries workspace, workflow, decision, artifact, findings/resolution, provenance, and receiving token-cost context.

## Legend

- `○` — inline orchestrator validation or correction
- `◇` — human workflow choice or decision gate
- `↻` — request another independent refine pass

## Lifecycle Tree

```text
RECEIVE PLAN-REFINE FINDINGS
│
├── ○ Start token boundary and select current manifest session
│   └── require exact writing_plans snapshot + handed-off paths/hashes
│
├── ○ Validate decision and artifact freshness before reading findings
│   ├── decision stale → Writing Plans decision gate
│   └── artifact stale → Requesting Plan Refine ↻
│
├── ○ Evaluate each finding by its actual decision effect
│   ├── plan_defect preserving approval → apply plan_fix
│   ├── decision_deviation → align_plan to approved value
│   ├── invalid → decline with evidence
│   └── decision change → human_decision_required
│
├── ○ Write unique resolution-<turn>.md
│   ├── checkpoint each edit before and after mutation
│   └── regenerate, hash, and validate plan.html when plan.md changed
│
├── ◇ Any human_decision_required item?
│   ├── yes → Writing Plans' Final build decision gate
│   └── no  → human chooses Refine or Execute
│
├── ○ Report receiving orchestrator token usage and coverage
│
└── exactly one current handoff with stable idempotency key
    ├── Refine → requesting-plan-refine ↻
    ├── Execute + subagents → subagent-driven-development
    └── Execute without subagent capability → executing-plans
```

## File Lifecycle Tree

```text
PLAN-REFINE RECEIVER FILES
│
├── Skill package [tracked]
│   └── skills/receiving-plan-refine/{SKILL.md,README.md}
│
├── Authoritative inputs [read-only]
│   ├── main:docs/superpower/manifest.json
│   │   └── sessions[current workspace].writing_plans
│   └── .superpowers/runs/<workflow-id>/30-plan/plan-refine/
│       └── findings-<turn>.md
│
├── Receiving evidence [ignored]
│   └── .superpowers/runs/<workflow-id>/
│       ├── receiving-plan-refine-token-cost.jsonl
│       └── 30-plan/plan-refine/resolution-<turn>.md
│
└── Corrected artifacts [tracked]
    └── docs/superpowers/features/<feature-slug>/
        ├── plan.md
        └── plan.html
```

## Pattern Omissions

- `hard-gate` — approval-preserving corrections may be applied without a new approval; the existing skill text cannot derive a gate that prevents every irreversible act.
- `anti-pattern` — baseline testing surfaced no dominant rationalization; no existing skill text can supply one without new content.

## Pattern Migration Notes

- `purpose` — DERIVED from the existing `## Overview` prose, moved to sit directly under the title.
- `checklist` — DERIVED from `## Overview`, `## Bind the Current Review`, `## Evaluate and Record`, and `## Handoff`, no new requirements.
- `the-process` — DERIVED from `## Overview`, `## Bind the Current Review`, `## Evaluate and Record`, and `## Handoff`, no new requirements.
- `key-principles` — DERIVED from `## Overview`, `## Bind the Current Review`, `## Evaluate and Record`, and `## Handoff`, no new requirements.

### Migration evidence

- Scenario: `reviewer-authority-vs-approved-decision` (authored from scratch)
- Baseline (pre-migration): 4/4 PASS
- After (post-migration): 4/4 PASS — no regression (gate: after >= baseline)
- Contamination audit: clean — no pressure-scenario wording entered the skill.
- Precision check: disposition names, the `handoff_id` format, and the hash rules
  were moved verbatim, not paraphrased.
- Gate: no-regression A/B; DERIVED blocks only, no gap-fill content
- Caveat: baselines in this campaign are contaminated — the measuring subagent
  carries prior knowledge of this repository, so a pre-migration baseline is
  not a clean no-skill control. Contamination is symmetric across the A/B, so
  regression detection remains valid; necessity claims for new content do not.
