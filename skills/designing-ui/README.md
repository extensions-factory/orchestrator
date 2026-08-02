# Designing UI

## Description

Turns approved feature requirements into a human-approved UI decision record and a written UI design for planning. It does not implement the UI.

## Inputs

- The selected current-workspace session in the single `main:docs/superpower/manifest.json`.
- Approved feature requirements and any caller-provided UI spec path.
- Installed project files, the project scaffold fallback, and an optional human, existing-code, or Figma layout source.
- Exact per-invocation or comparable cumulative token metadata exposed by the harness/provider.

## Durable Output

Designing UI adds decisions only to the selected workspace session:

```json
{
  "sessions": [
    {
      "workspace": {
        "type": "branch",
        "target": "feature/example-feature"
      },
      "designing_ui": {
        "workflow_id": "20260802T120000Z-example-feature",
        "platform": "React",
        "layout": "Header, sidebar, content grid, and detail panel",
        "source": "docs/mockups/example.png",
        "component_approach": "native React and browser primitives",
        "constraints": ["Keyboard accessible", "Responsive at 768px"]
      }
    }
  ]
}
```

The written UI design is saved to `docs/superpowers/features/<feature-slug>/design.md` or a caller-provided UI spec path.

## Token-cost Monitoring

`.superpowers/runs/<workflow-id>/designing-ui-token-cost.jsonl` stores every harness-reported main-orchestrator model invocation. Missing counts remain `null` with reasons; Figma and ReUI tool calls are included in orchestrator usage rather than recorded as workers. The return or handoff reports measured totals and coverage without presenting partial values as complete.

## Human Decisions

The human approves platform, layout, source, component approach, and constraints as one bundle before they become planning inputs. Later decision changes return to the same gate, update the selected manifest entry, and regenerate affected UI design content.

## Handoff

Before returning or invoking `writing-plans`, designing-ui rereads the selected main-manifest session and verifies that its complete approved bundle matches the written UI design. Direct invocation owns the one `writing-plans` call; sub-flow invocation returns the design path and token report to its caller.

## Legend

- `○` — orchestrator action performed inline
- `◇` — human approval or decision gate
- `⊘` — hard stop, no UI implementation
- `↻` — return to an earlier step

## Lifecycle Tree

```text
DESIGNING UI
│
├── ○ Start token-cost boundary and select current manifest session
│   └── initialize/reuse designing_ui.workflow_id
│
├── ○ Detect platform
│   ├── 1. installed project files (package.json, electron config,
│   │      tsconfig.json, Xcode project)
│   ├── 2. docs/superpowers/project/scaffold-design.md [no project files]
│   └── 3. ask the human [neither resolves]
│       installed project files win over a conflicting scaffold doc
│
├── ◇ Framework has a branch-table row?
│   ├── no  → ⊘ say unsupported, hand off to
│   │         superpowers-orchestrator:brainstorming, write no UI code
│   └── yes → continue [React → references/react-reui.md]
│
├── ○ Resolve layout and source
│   ├── supplied → continue
│   └── missing → ask the human ↻
│
├── ○ Read the Figma reference [only when the source is a Figma file/node]
│   ├── get_metadata  → hierarchy
│   └── get_screenshot → visual reference
│
├── ○ Follow the framework reference
│   └── references/react-reui.md
│       ├── confirm the framework from installed project files
│       └── ◇ registry toolchain present? (Tailwind / shadcn / configured registry)
│           ├── no  → ask the human whether to adopt it
│           │   ├── declines → native platform primitives
│           │   └── approves → REQUIRED SUB-SKILL reui
│           └── yes → REQUIRED SUB-SKILL reui
│
├── ◇ Human approves UI decisions and constraints?
│   ├── no/unavailable → ⊘ report what awaits approval and stop
│   └── yes → ○ record platform + layout + source + component approach
│             + constraints in the selected main-manifest session
│
├── ○ Write and approve the UI design planning input
│   └── later decision change → return to the UI decision gate ↻
│
├── ○ Report main-orchestrator token totals and coverage
│
├── use-tool
│   ├── Figma MCP: get_metadata, get_screenshot
│   └── reui MCP: search [React branch, registry present or approved only]
│
├── use-file
│   ├── read: docs/superpowers/project/scaffold-design.md [fallback detection]
│   ├── read: references/react-reui.md [React branch]
│   └── write: docs/superpowers/features/<feature-slug>/design.md
│
└── ◇ Invocation mode?
    ├── direct invoke   → ○ invoke superpowers-orchestrator:writing-plans
    └── sub-flow invoke → ○ return control to the calling skill
        caller invokes writing-plans exactly once when its own flow finishes

Hard gates:
no UI planning input without an approved and recorded UI decision bundle — an
unavailable human is not approval. No UI implementation for a framework absent
from the branch table — hand off to brainstorming instead of self-authorizing
support by adding a reference file for an unapproved framework.
```

## File Lifecycle Tree

```text
DESIGNING UI FILES
│
├── Skill package [tracked]
│   └── skills/designing-ui/
│       ├── SKILL.md
│       ├── README.md
│       └── references/
│           └── react-reui.md
│
├── Peer skills [tracked, read]
│   ├── skills/reui/ [React branch, REQUIRED SUB-SKILL]
│   └── skills/brainstorming/ [unsupported-framework hand-off]
│
├── Project context [read-only]
│   ├── package.json / tsconfig.json / electron config / Xcode project
│   └── docs/superpowers/project/scaffold-design.md [project-kickoff output]
│
├── Design source [read-only, optional]
│   └── Figma file/node reference [get_metadata, get_screenshot]
│
├── Decision record [tracked on main, read and updated]
│   └── docs/superpower/manifest.json
│       └── sessions[current workspace].designing_ui
│           ├── workflow_id
│           └── platform + layout + source + component_approach + constraints
│
├── Durable feature documents [tracked, created or updated]
│   └── docs/superpowers/features/<feature-slug>/
│       └── design.md [approved UI decisions recorded here]
│
└── Runtime evidence [ignored]
    └── .superpowers/runs/<workflow-id>/designing-ui-token-cost.jsonl
```
