# Writing Plans

## Description

Turns approved project or feature decisions into a human-approved, source-free implementation plan and synchronized HTML companion for refinement or execution.

## Inputs

- The current workspace and its selected entry in the single `main:docs/superpower/manifest.json`.
- Complete applicable approvals from `project_kickoff`, `brainstorming`, and `designing_ui`.
- Matching approved design artifacts and current repository structure.
- Exact per-invocation or comparable cumulative token metadata exposed by the harness/provider.

## Durable Output

Writing Plans adds the final build decision only to the selected workspace session:

```json
{
  "sessions": [
    {
      "workspace": {
        "type": "branch",
        "target": "feature/example-feature"
      },
      "writing_plans": {
        "workflow_id": "20260802T120000Z-example-feature",
        "scope": ["US-1 delivers the approved behavior"],
        "exclusions": ["Deferred behavior remains out of scope"],
        "ordering": ["US-1/Task 1", "US-1/Task 2"],
        "files": ["src/example.ts: implement the approved behavior"],
        "interfaces": ["runExample(input: ExampleInput) -> ExampleResult"],
        "tests": ["tests/example.test.ts::returns approved result"],
        "verification": ["npm test -- example.test.ts => PASS"]
      }
    }
  ]
}
```

It also creates or updates `docs/superpowers/features/<feature-slug>/plan.md` and `plan.html`. Both artifacts contain implementation instructions but no implementation or test source code.

## Token-cost Monitoring

`.superpowers/runs/<workflow-id>/writing-plans-token-cost.jsonl` stores source-tagged records for every D10 worker attempt and every harness-reported main-orchestrator invocation. Missing counts remain `null` with reasons. Handoffs report worker, orchestrator, and combined measured totals and coverage without treating partial values as complete.

## Human Decisions

After self-review, the human explicitly approves scope, exclusions, ordering, files, interfaces, tests, and verification together. Planning cannot offer Refine or Execute before that bundle is written to the selected main-manifest session. Later decision changes return to the gate and regenerate and reapprove both plan artifacts.

## Handoff

Before Refine or Execute, Writing Plans rereads the selected main-manifest session and verifies the approved seven-field bundle against the plan, HTML companion, and upstream records. It sends exactly one selected route with the workspace-aware manifest instruction and token-cost report.

## Legend

- `◆ Dn` — dispatch through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator validation or routing
- `◇` — human choice or scope gate
- `↻` — revise and validate again

## Lifecycle Tree

```text
WRITING PLANS
│
├── ○ Start token-cost boundary and select current manifest session
│   └── initialize/reuse writing_plans.workflow_id
│
├── ○ Read approved decision records, specification, and project context
│   └── require matching project_kickoff / brainstorming / designing_ui inputs
│
├── ◇ Spec contains multiple independent subsystems?
│   ├── yes → recommend separate plans/specs
│   └── no  → continue
│
├── ◆ D10 author implementation plan
│   ├── role: tech_lead
│   ├── task_type: sprint_planning
│   ├── use templates/plan-template.md
│   ├── generate plan.md + plan.html without implementation source code
│   └── return proposed final build decision
│
├── Plan structure
│   ├── header with spec, goal, architecture, stack
│   ├── Expected Outcome
│   ├── Global Constraints copied exactly from spec
│   ├── optional Foundation for work shared by multiple stories
│   ├── one vertical-slice section per spec User Story
│   │   ├── preserve US IDs
│   │   ├── one or more independently reviewable tasks
│   │   └── end-to-end US checkpoint
│   └── every task contains
│       ├── dependencies
│       ├── exact files
│       ├── consumed and produced interfaces
│       ├── valid task_type
│       ├── failing test step
│       ├── observed failure
│       ├── minimal implementation
│       ├── passing verification
│       └── orchestrator-only Git bookkeeping block
│
├── ○ Self-review returned artifacts
│   ├── complete spec coverage
│   ├── no placeholders or vague steps
│   ├── type/interface consistency
│   ├── template conformance
│   ├── valid task_type on every task
│   └── spec US ↔ plan US ↔ checkpoint traceability
│
├── ◇ Self-review finds gaps?
│   ├── yes → fix plan + regenerate plan.html ↻
│   └── no  → continue
│
├── ◇ Human approves scope + exclusions + ordering + files
│      + interfaces + tests + verification?
│   ├── no  → revise, regenerate both artifacts, self-review ↻
│   └── yes → record under writing_plans in selected manifest session
│
├── ○ Report worker + orchestrator token usage and combined coverage
│
├── use-tool
│   ├── superpowers-orchestrator:dispatch-agent [D10]
│   ├── plan self-review and traceability checks
│   ├── superpowers-orchestrator:requesting-plan-refine [optional]
│   └── selected execution skill [terminal handoff]
│
├── use-file
│   ├── read: approved design.md
│   ├── read: templates/plan-template.md
│   ├── read: templates/plan-companion-template.html
│   └── create/update: plan.md + plan.html
│
└── ◇ Human chooses next action
    ├── Refine
    │   └── requesting-plan-refine
    └── Execute
        ├── subagent-capable harness → subagent-driven-development
        └── no subagent capability  → executing-plans
```

## File Lifecycle Tree

```text
PLAN FILES
│
├── Skill package [tracked, read]
│   └── skills/writing-plans/
│       ├── SKILL.md
│       ├── README.md
│       ├── prompts/
│       │   └── plan-document-reviewer-prompt.md
│       └── templates/
│           ├── plan-template.md
│           └── plan-companion-template.html
│
├── Specification [tracked, read]
│   └── docs/superpowers/features/<feature-slug>/
│       └── design.md
│
├── Decision record [tracked on main, read and updated]
│   └── docs/superpower/manifest.json
│       └── sessions[current workspace].writing_plans
│           ├── workflow_id
│           └── scope + exclusions + ordering + files + interfaces
│               + tests + verification
│
├── Plan artifacts [tracked, created and kept synchronized]
│   └── docs/superpowers/features/<feature-slug>/
│       ├── plan.md
│       └── plan.html
│
└── Runtime planning evidence [ignored]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        ├── writing-plans-token-cost.jsonl
        └── 30-plan/<task>/turns/<NNN>-planning/
            ├── request.json
            └── response.json
```

## Pattern Omissions

No conditional blocks are omitted; each has existing source material in the skill.

## Pattern Migration Notes

- `purpose` — DERIVED from the existing `## Overview` prose, moved to sit directly under the title.
- `hard-gate` — DERIVED from `## Human Gate — Final build decision`, including "Do not offer Refine or Execute until this approval is recorded", no new requirements.
- `anti-pattern` — DERIVED from `## No Placeholders`: "TBD", "TODO", "implement later", and "fill in details" are existing banned forms, no new requirements.
- `checklist` — DERIVED from `## Overview`, `## Scope Check`, `## Final Build Decision`, `## Organize Tasks Under User Stories`, `## File Structure`, `## Self-Review`, `## Human Gate — Final build decision`, and `## Execution Handoff`, no new requirements.
- `process-flow` — DERIVED from `## Scope Check`, `## Self-Review`, and `## Human Gate — Final build decision`, no new requirements.
- `the-process` — DERIVED from `## Overview` through `## Execution Handoff`, no new requirements.
- `after-artifact` — DERIVED from `## Final Build Decision`, `## Human Gate — Final build decision`, and `## Execution Handoff`, no new requirements.
- `token-cost-monitoring` — RETAINED, heading normalized to Title Case; body unchanged.
- `red-flags` — DERIVED from `## No Placeholders` and `## Human Gate — Final build decision`, no new requirements.
- `key-principles` — DERIVED from `## Organize Tasks Under User Stories`, `## Task Right-Sizing`, `## No Placeholders`, and `## Human Gate — Final build decision`, no new requirements.

### Migration evidence

- Scenario: `plan-gate-and-placeholder-under-lunch-pressure` (adapted from `evals/scenarios/triggering-writing-plans/story.md`)
- Baseline (pre-migration): 4/4 PASS
- After (post-migration): 4/4 PASS — no regression (gate: after >= baseline)
- Note: the first after-run was discarded as stale. The migration had absorbed a
  phrase from the pressure scenario into an Anti-Pattern block, which the run then
  cited as decisive — teaching to the test. The block was rebased onto the source's
  own `"TBD"` example and the run repeated against the corrected file.
- Gate: no-regression A/B; DERIVED blocks only, no gap-fill content
- Caveat: baselines in this campaign are contaminated — the measuring subagent
  carries prior knowledge of this repository, so a pre-migration baseline is
  not a clean no-skill control. Contamination is symmetric across the A/B, so
  regression detection remains valid; necessity claims for new content do not.
