# Orchestrator Workflow

## Legend

- `◆ Dn` — dispatch point; always routes through `superpowers-orchestrator:dispatch-agent`
- `○` — orchestrator action performed inline
- `◇` — human approval gate
- `↻` — loop back to an earlier step

## Lifecycle Tree

```text
SUPERPOWERS ORCHESTRATOR
│
├── Session bootstrap
│   ├── ○ session-start injects using-superpowers
│   ├── ○ user-prompt-submit restores the Scrum Master reminder
│   └── ○ classify request
│
├── A. Greenfield project
│   └── project-kickoff
│       ├── ◇ capture idea
│       ├── ○ select market-facing or technical research track
│       ├── ◆ D1 research domain 1 ┐
│       ├── ◆ D2 research domain 2 │ parallel
│       ├── ◆ D3 research domain 3 │
│       ├── ◆ D4 research domain 4 ┘
│       │      role: business_analyst
│       │      task_type: discovery_research
│       ├── ◆ D5 synthesize discovery document
│       │      role: business_analyst
│       │      task_type: discovery_research
│       ├── ◇ select stack, standards, and AI tools
│       ├── ◆ D6 initialize Git repository
│       ├── ◆ D7 create initial commit
│       │      role: devops_engineer
│       │      task_type: workspace_setup
│       ├── ◆ D8 write scaffold spec
│       │      role: tech_lead
│       │      task_type: architecture_design
│       └── continue to Writing Plan
│
├── B. Feature/change in an existing project
│   └── brainstorming
│       ├── ○ inspect project context
│       ├── ○ ask one question at a time
│       ├── ○ present two or three approaches
│       ├── ◇ approve design
│       ├── ◆ D9 write documentation artifacts
│       │      ├── discovery
│       │      │   role: business_analyst
│       │      │   task_type: discovery_research
│       │      ├── requirements
│       │      │   role: product_owner
│       │      │   task_type: requirements_user_stories
│       │      ├── architecture
│       │      │   role: tech_lead
│       │      │   task_type: architecture_design
│       │      └── documentation
│       │          role: technical_writer
│       │          task_type: documentation_knowledge_transfer
│       ├── ○ validate spec, HTML companion, and roadmap
│       ├── ◇ review written spec
│       └── continue to Writing Plan
│
├── C. Writing Plan
│   ├── ◆ D10 write plan and HTML companion
│   │      role: tech_lead
│   │      task_type: sprint_planning
│   ├── ○ self-review returned artifacts
│   └── ◇ choose next action
│       ├── Execute
│       └── Refine
│           ├── ◆ D11 independent plan review
│           │      role: tech_lead
│           │      task_type: code_review_quality
│           ├── ○ evaluate findings with receiving-plan-refine
│           └── ↻ refine again or execute
│
├── D. Execute Plan
│   ├── ◆ D12 create isolated worktree
│   │      role: devops_engineer
│   │      task_type: workspace_setup
│   └── subagent-driven-development
│       ├── Task 1
│       │   ├── ◆ D13 implement and test
│       │   │      role: software_engineer
│       │   │      task_type: value declared by the plan task
│       │   ├── ○ perform Git bookkeeping
│       │   ├── ◆ D14 task review
│       │   │      role: tech_lead
│       │   │      task_type: code_review_quality
│       │   ├── ◆ D15 security review [conditional]
│       │   │      role: security_engineer
│       │   │      task_type: security_review
│       │   └── findings?
│       │       ├── yes → ◆ D16 fix → ◆ D14 re-review ↻
│       │       └── no  → mark task complete
│       ├── Task 2..N
│       │   └── repeat D13–D16
│       ├── ◆ D17 final whole-branch review
│       │      role: tech_lead
│       │      task_type: code_review_quality
│       └── findings?
│           ├── yes → ◆ D18 one fix wave → ◆ D17 re-review ↻
│           └── no  → Finish Branch
│
├── E. Finish Branch
│   ├── ○ verify test results
│   ├── ◇ choose merge, PR, keep, or discard
│   └── ◆ D19 execute the selected finish path
│          role: devops_engineer
│          task_type: release_deployment
│          ├── Git mechanics
│          ├── PR body and gh pr create
│          ├── roadmap release update
│          └── worktree cleanup
│
├── F. Sprint Retrospective
│   ├── ○ calculate metrics from ledger.jsonl
│   ├── ◆ D20 process review
│   │      role: agile_coach
│   │      task_type: retrospective_process_improvement
│   ├── ◇ approve process improvements
│   └── approved skill improvement?
│       └── ◆ D21 edit skill
│              role: software_engineer
│              task_type: implementation_coding
│
└── G. Backlog Refinement
    ├── ○ read roadmap
    ├── ◆ D22 propose ordering and grooming
    │      role: product_owner
    │      task_type: backlog_refinement_prioritization
    ├── ◇ approve proposal
    └── ○ apply approved roadmap changes
```

## Dispatch-Agent Subtree

Every `◆ Dn` above enters this subtree.

```text
◆ DISPATCH-AGENT(role, task_type, artifacts)
│
├── 1. ○ Resolve task_type
│
├── 2. ○ Resolve ranked candidates
│   └── scripts/model-lookup.sh <task_type>
│       └── output: rank, provider, model, reason
│
├── 3. ○ Select rank
│   ├── normal task → rank 1
│   ├── review task → provider-diversity rule
│   └── provider unavailable → next ready rank
│
├── 4. ○ Resolve exact invocation
│   └── scripts/model-lookup.sh --command <task_type> <rank>
│       ├── agent
│       ├── model
│       ├── effort
│       ├── write
│       └── exact invocation
│
├── 5. ○ Build request envelope
│   ├── assign stable task slug
│   ├── assign next turn number
│   ├── set dispatch persona
│   ├── attach artifacts, acceptance criteria, and constraints
│   └── write .superpowers/<task>/turn-<turn>-request.json
│
├── 6. ○ Provider readiness preflight
│   ├── agent=claude      → Agent tool is ready
│   ├── agent=codex       → run /codex:setup
│   └── agent=antigravity → human relay is ready
│
├── 7. Actual worker dispatch
│   │
│   ├── agent=claude
│   │   └── ◆ Agent tool
│   │       model=<output.model>
│   │       prompt="ROLE: subagent\n" + <request JSON>
│   │
│   ├── agent=codex
│   │   ├── task_type=code_review_quality
│   │   │   └── ◆ /codex:review --wait --model <output.model>
│   │   │         --base <context.base_sha>
│   │   ├── task_type=security_review
│   │   │   └── ◆ /codex:adversarial-review --wait --model <output.model>
│   │   │         --base <context.base_sha> "<context.security_focus>"
│   │   └── rescue task_type set
│   │       ├── discovery_research, requirements_user_stories
│   │       ├── backlog_refinement_prioritization, sprint_planning
│   │       ├── architecture_design, ui_ux_prototyping
│   │       ├── implementation_coding, debugging_root_cause, testing_qa
│   │       ├── release_deployment, workspace_setup, monitoring_incident_ops
│   │       ├── documentation_knowledge_transfer
│   │       ├── retrospective_process_improvement
│   │       └── ◆ /codex:rescue --wait --fresh --write
│   │             --model <output.model>
│   │             --effort <output.effort>
│   │             "<prompt>"
│   │
│   └── agent=antigravity
│       └── ◆ Human relay
│           select <output.model>
│           send request JSON
│           return response JSON
│
├── 8. ○ Receive and validate
│   ├── rescue/other provider → write turn-<turn>-response.json
│   ├── Codex review → persist stdout as turn-<turn>-review.md
│   │                  and construct turn-<turn>-response.json
│   ├── run scripts/validate-message.mjs
│   └── append request/response pair to .superpowers/ledger.jsonl
│
└── 9. ○ Route response
    ├── status=done
    │   └── continue parent workflow
    ├── status=needs_revision
    │   └── next turn → ◆ DISPATCH-AGENT ↻
    └── status=blocked
        ├── missing external context → ask human
        ├── Git bookkeeping → orchestrator inline
        └── other denied operation → ◆ DISPATCH-AGENT ↻
```

## Dispatch Invariant

```text
task_type
   ↓
scripts/model-lookup.sh <task_type>
   ↓
select rank/provider
   ↓
scripts/model-lookup.sh --command <task_type> <rank>
   ↓
use the exact invocation from output
   ↓
dispatch worker
```

When the resolved agent is Codex, task type selects one invocation:

```text
code_review_quality
└── /codex:review --wait --model <model> --base <base_sha>

security_review
└── /codex:adversarial-review --wait --model <model> --base <base_sha> "<security focus>"

rescue task types
├── discovery_research
├── requirements_user_stories
├── backlog_refinement_prioritization
├── sprint_planning
├── architecture_design
├── ui_ux_prototyping
├── implementation_coding
├── debugging_root_cause
├── testing_qa
├── release_deployment
├── workspace_setup
├── monitoring_incident_ops
├── documentation_knowledge_transfer
├── retrospective_process_improvement
└── /codex:rescue --wait --fresh --write --model <model> --effort <effort> "<prompt>"
```
