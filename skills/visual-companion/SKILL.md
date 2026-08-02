---
name: visual-companion
description: Use when the human explicitly requests the draft Visual Companion by name for browser-based mockups, diagrams, or visual comparisons
---

# Visual Companion (Draft)

This skill is retained for later discussion. **Do not invoke it automatically** from brainstorming, designing-ui, or a generic request for visual work. Use it only when the human explicitly requests Visual Companion by name.

## Overview

Visual Companion runs a local browser surface for interactive mockups, diagrams, and visual comparisons. The terminal conversation remains the primary feedback channel.

## Trigger boundary

| Request | Action |
| --- | --- |
| Explicitly names Visual Companion | Read the guide and follow it |
| Asks for a mockup, UI, diagram, or layout without naming it | Do not load this draft |
| Another skill reaches a visual question | Continue that skill without offering this draft |

The trigger boundary here overrides the broader use cases described in the guide.

## Use

After an explicit request, read [guide.md](guide.md) completely before starting the server. The guide owns platform launch details, authenticated URLs, screen authoring, feedback collection, and cleanup.

## Resources

- `scripts/start-server.sh` and `scripts/stop-server.sh`
- `scripts/server.cjs` and `scripts/helper.js`
- `templates/frame-template.html`

## Common mistakes

- Treating a visual question as permission to offer or load the draft.
- Adding Visual Companion back into another skill's automatic flow.
- Starting the server before reading the guide or receiving an explicit request.
