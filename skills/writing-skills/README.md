# Writing Skills

## Legend

- `◆ D22` — approved skill-improvement dispatch
- `○` — authoring or validation action
- `◇` — evidence, quality, or deployment gate
- `↻` — repeat RED/GREEN/REFACTOR testing

## Lifecycle Tree

```text
WRITING SKILLS
│
├── ◇ Is this a reusable skill-worthy problem?
│   ├── one-off/project-specific/standard practice → do not create a skill
│   └── reusable technique, pattern, or reference → continue
│
├── ○ Classify skill type
│   ├── technique
│   ├── pattern
│   └── reference
│
├── RED — prove the documentation gap
│   ├── ○ create realistic pressure or retrieval scenarios
│   ├── ○ run scenarios without the new guidance
│   ├── ◇ Does control exhibit the target failure?
│   │   ├── no  → stop; there is nothing to teach
│   │   └── yes → continue
│   └── ○ record exact failures and rationalizations
│
├── GREEN — write the minimum effective skill
│   ├── ◆ D22 [human-approved retrospective improvement]
│   │   ├── role: software_engineer
│   │   ├── task_type: implementation_coding
│   │   └── input: approval, acceptance criteria, failing scenario, paths
│   ├── ○ write valid frontmatter
│   ├── ○ optimize trigger-only description for discovery
│   ├── ○ choose guidance form matching the observed failure
│   ├── ○ keep core concepts concise
│   ├── ○ move heavy reference/tools to supporting files
│   └── ○ run the same scenarios with the skill
│
├── ◇ Scenarios now pass?
│   ├── no  → tighten guidance ↻
│   └── yes → continue
│
├── REFACTOR — close observed loopholes
│   ├── ○ identify new rationalizations
│   ├── ○ add only evidence-backed counters
│   ├── ○ micro-test wording with 5+ fresh-context reps per variant
│   ├── ○ keep a no-guidance control
│   └── ○ rerun pressure/application scenarios ↻
│
├── ◇ Quality checks
│   ├── correct name and frontmatter
│   ├── searchable trigger language
│   ├── token-efficient content
│   ├── qualified cross-skill references
│   ├── flowchart only for non-obvious decisions
│   ├── no narrative or speculative guidance
│   └── all validation evidence recorded
│
├── use-tool
│   ├── fresh-context subagents or API calls for baseline/guided scenarios
│   ├── superpowers-orchestrator:dispatch-agent [approved D22]
│   ├── render-graphs.js [Graphviz validation/rendering]
│   ├── word-count/search/format validation
│   └── Git commit/push after verification
│
├── use-file
│   ├── read: anthropic-best-practices.md
│   ├── read: testing-skills-with-subagents.md
│   ├── read: persuasion-principles.md + graphviz-conventions.dot
│   ├── create/update: target skills/<skill-name>/SKILL.md and support files
│   └── create: baseline, guided, scoring, and before/after evaluation evidence
│
└── ○ Deploy one verified skill before starting another
    ├── commit
    ├── push to fork when configured
    └── consider upstream contribution

Iron law:
no new or edited skill guidance without first observing the relevant failure.
```

## File Lifecycle Tree

```text
SKILL-AUTHORING FILES
│
├── Authoring skill package [tracked, read]
│   └── skills/writing-skills/
│       ├── SKILL.md
│       ├── README.md
│       ├── anthropic-best-practices.md
│       ├── testing-skills-with-subagents.md
│       ├── persuasion-principles.md
│       ├── graphviz-conventions.dot
│       ├── render-graphs.js
│       └── examples/
│           └── CLAUDE_MD_TESTING.md
│
├── Target skill [tracked, created or updated]
│   └── skills/<skill-name>/
│       ├── SKILL.md
│       ├── README.md [when maintained]
│       ├── scripts/ [reusable tools only]
│       ├── templates/ [reusable output shapes only]
│       ├── prompts/ [worker/reviewer prompts only]
│       └── references/ [heavy reference only]
│
├── Evaluation evidence [project-specific location]
│   ├── baseline/control outputs
│   ├── guided outputs
│   ├── scoring notes
│   └── before/after results
│
└── Retrospective dispatch evidence [ignored, D22 path]
    └── .superpowers/runs/<workflow-id>/
        ├── ledger.jsonl
        └── 60-retrospective/
            ├── retrospective.md
            └── <skill-task>/turns/<NNN>-implement/
                ├── request.json
                └── response.json
```

See [F. Sprint Retrospective](../../docs/orchestrator-workflow.md#lifecycle-tree).
