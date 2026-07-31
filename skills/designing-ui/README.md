# Designing UI

## Legend

- `○` — orchestrator action performed inline
- `◇` — human approval or decision gate
- `⊘` — hard stop, no UI implementation
- `↻` — return to an earlier step

## Lifecycle Tree

```text
DESIGNING UI
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
├── ○ Fill the layout-source slot
│   ├── layout + source supplied → continue
│   └── not supplied → ask the human ↻
│
├── ◇ Layout approved by a human?
│   ├── human unavailable or no reply → ⊘ write the proposed slot,
│   │   report what awaits approval, stop
│   │   (an unavailable human is not approval)
│   └── approved → continue
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
├── ○ Record the approved layout in the feature design spec
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
no UI implementation without an approved layout-source slot — an unavailable
human is not approval. No UI implementation for a framework absent from the
branch table — hand off to brainstorming instead of self-authorizing support
by adding a reference file for an unapproved framework.
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
└── Durable feature documents [tracked, created or updated]
    └── docs/superpowers/features/<feature-slug>/
        └── design.md [approved layout recorded here]
```

Standalone, direct-invoke skill — not wired into `brainstorming` or
`project-kickoff`. The auto-injection hand-off described in
`docs/superpowers/features/designing-ui-skill/design.md` (US-5, US-6) is
deferred; a baseline probe showed `brainstorming` does not reliably fire for
UI build requests, so that hand-off point needs resolving before it is built.
