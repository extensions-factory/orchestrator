# Requesting Code Review

## Description

Reviews task or whole-branch changes against the approved decisions and plan, with optional security review for sensitive diffs.

## Inputs

- The current workspace and exactly matching session in the single `main:docs/superpower/manifest.json`.
- Approved Brainstorming and Writing Plans decisions, exact plan/design paths and hashes, and the caller's decision snapshot.
- Exact base/head range, review package, task brief/report or whole-branch requirements, and author-provider metadata.

## Durable Output

Each review retains its request, `review.md`, response, exact Git range, approved hashes, finding classifications/routes, and dispatch-ledger evidence. D14/D15/D17 worker and main-orchestrator usage is stored in `requesting-code-review-token-cost.jsonl`.

## Human Decisions

Reviewers identify but never apply decision changes. Product scope, exclusions, or acceptance-criteria proposals return to Brainstorming; build-order, file, interface, test, or verification proposals return to Writing Plans. Implementation defects and deviations alone enter fix waves.

## Handoff

Return implementation and decision verdicts, review evidence, unchanged approved context, and token-cost coverage to the caller. A clean implementation verdict cannot bypass a pending human decision.

## Legend

- `◆ Dn` — reviewer or fixer dispatch
- `○` — orchestrator preparation and adjudication
- `◇` — review verdict gate
- `↻` — fix and re-review loop

## Lifecycle Tree

```text
CODE REVIEW
│
├── ○ Select current main-manifest session and approved plan
│   └── bind decision snapshot + plan/design hashes
│
├── Per-task review
│   ├── ○ Preserve the exact pre-D13 BASE_SHA
│   ├── ○ Commit validated worker changes
│   ├── ○ Generate BASE_SHA..HEAD_SHA review package
│   ├── ◆ D14 task review
│   │   ├── role: tech_lead
│   │   ├── task_type: code_review_quality
│   │   ├── carry approved decision/plan boundary
│   │   ├── enforce reviewer provider diversity
│   │   └── require spec-compliance + code-quality verdicts
│   ├── ◇ Security-sensitive diff?
│   │   ├── no  → continue
│   │   └── yes → ◆ D15 security review
│   │       ├── role: security_engineer
│   │       ├── task_type: security_review
│   │       └── require base_sha + complete security_focus
│   └── ◇ Classified findings?
│       ├── decision proposal → owning human gate
│       ├── implementation Critical/Important → ◆ D16 fix wave
│       │   ├── commit validated fix
│       │   ├── regenerate review package
│       │   └── re-dispatch D14/D15 ↻
│       └── no  → task gate is clean
│
└── Whole-branch review
    ├── ○ Derive MERGE_BASE
    ├── ○ Generate MERGE_BASE..HEAD review package
    ├── ◆ D17 final review
    │   ├── role: tech_lead
    │   ├── task_type: code_review_quality
    │   ├── carry approved decision/plan boundary
    │   └── include plan/spec and accumulated Minor findings
    └── ◇ Findings?
├── decision proposal → owning human gate
├── implementation issue → ◆ D18 one complete fix wave
│   ├── commit validated fixes
│   ├── regenerate whole-branch package
│   └── re-dispatch D17 ↻
└── no  → hand off to finishing-a-development-branch
│
├── use-tool
│   ├── Git rev-parse, merge-base, and commit
│   ├── subagent-driven-development/scripts/review-package
│   ├── superpowers-orchestrator:dispatch-agent [D14–D18]
│   └── project-specific covering/full test commands [fix evidence]
│
└── use-file
    ├── read: prompts/code-reviewer.md
    ├── read: main manifest, task brief, implementer report, design, and plan
    ├── create: review-<base7>..<head7>.diff
    └── create/update: review.md, response.json, report.md, ledger.jsonl,
        and token-cost JSONL
```

## File Lifecycle Tree

```text
CODE REVIEW FILES
│
├── Skill package [tracked]
│   └── skills/requesting-code-review/
│       ├── SKILL.md
│       ├── README.md
│       └── prompts/
│           └── code-reviewer.md
│
├── Review inputs [tracked or run-scoped, read]
│   ├── main:docs/superpower/manifest.json [single decision record]
│   ├── docs/superpowers/features/<feature-slug>/
│   │   ├── design.md
│   │   └── plan.md
│   └── .superpowers/runs/<workflow-id>/40-execution/tasks/<task>/
│       ├── brief.md
│       ├── report.md
│       └── reviews/review-<base7>..<head7>.diff
│
└── Review evidence [ignored, created]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        ├── requesting-code-review-token-cost.jsonl
        └── 40-execution/tasks/<task>/turns/
            ├── <NNN>-review/
            │   ├── request.json
            │   ├── review.md
            │   └── response.json
            └── <NNN>-fix/
                ├── request.json
                └── response.json
```
