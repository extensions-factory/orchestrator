---
name: designing-ui
description: Use when designing a new or changed user-facing screen, component, or visual layout in a project
---

# Designing UI

Capture an approved layout source before implementation so the UI has a stated structure to follow.

## Platform

Detect the platform in this order; the first result wins:

1. Inspect installed project files: `package.json` dependencies, Electron configuration, `tsconfig.json`, Xcode projects, and framework files.
2. If no project files identify it, read `docs/superpowers/project/scaffold-design.md`.
3. If still unknown, ask the human: “What stack/platform is this project?”

Installed project files override a conflicting scaffold document.

| Framework | Reference |
| --- | --- |
| React | [references/react-reui.md](references/react-reui.md) |

For a framework without a row, say it is not supported yet, hand off to `superpowers-orchestrator:brainstorming`, and write no UI code. Extend this map with one row and one reference file per supported framework.

## Required layout-source slot

Before any implementation, fill and present this slot for human approval:

```text
Layout: <sections, hierarchy, and arrangement>
Source: <human description | existing page/component path | Figma file/node reference>
```

If it is not supplied, ask the human for the layout. If the human is unavailable or does not reply, write the proposed slot, report what awaits approval, and stop before any UI implementation: an unavailable human is not approval. For a Figma reference, use `get_metadata` for hierarchy and `get_screenshot` for visual reference.

After approval, follow the selected framework reference and record the approved layout in the feature design spec.

## Completion

Direct invocation: after the written design is approved, invoke only `superpowers-orchestrator:writing-plans`.

Sub-flow invocation: after the written design is approved, return control to the calling skill; it invokes `superpowers-orchestrator:writing-plans` exactly once when its flow finishes.
