---
title: superpowers-orchestrator:designing-ui
date: 2026-07-31
status: draft
---

# superpowers-orchestrator:designing-ui — Design Spec

## 1. Overview

Agents working on UI currently fall back to the general `superpowers-orchestrator:brainstorming` skill for every design task, which lacks platform detection, visual layout capture, and component-library mapping steps. This skill — `superpowers-orchestrator:designing-ui` — is a dedicated UI/visual-design sibling of `brainstorming` that an agent invokes directly when starting any UI work (new screen, component, or redesign) on a web/Electron/TypeScript project. It detects the target platform, captures the layout via Figma or a text description, maps each layout section to free-tier ReUI components, flags gaps, and produces a component-mapped design doc that feeds `superpowers-orchestrator:writing-plans` exactly as `brainstorming` does.

## 2. Context & Assumptions

- The orchestrator plugin already has `superpowers-orchestrator:brainstorming` and `superpowers-orchestrator:writing-plans`. This skill is a peer of `brainstorming`, not a replacement.
- The superseded `docs/UI-desgin.md` proposed a narrower `metronic-free-build` skill (Metronic Figma + ReUI free tier, with licensing/asset-extraction guard rules). That proposal is replaced by this skill. The licensing/tier guard logic is dropped; the new skill only verifies that a Figma reference resolves, nothing about licensing tiers.
- Assumption: the Figma MCP server exposes `get_metadata` and `get_screenshot` tools. If the MCP server is unavailable the skill degrades gracefully to a text-description path.
- Assumption: the ReUI MCP server exposes a `search` tool. If unavailable the agent notes the gap and asks the user to describe components manually.
- Assumption: platform detection is limited to `web-electron-ts` vs `other`. Native mobile and non-TS stacks are explicitly out of scope at this time.
- No open questions remain; the scope and workflow were approved section by section in the brainstorming session.

## 3. Scope

### Goals

- Provide a dedicated skill trigger for UI design work, separate from `brainstorming`.
- Auto-detect the target platform from project files, scaffold-design doc, or human input.
- Accept a Figma file/node link or text description as the layout source.
- Map each layout section to free-tier ReUI components; flag sections with no match.
- Produce a `design.md` spec, `design.html` companion, and roadmap entries, then hand off to `writing-plans`.
- Maintain the same terminal-state contract as `brainstorming` so downstream tooling is identical.

### Non-Goals

- Does not generate code from Figma directly (no `figma-design-to-code` skill, no `get_design_context` call).
- Does not handle native mobile or non-web-Electron-TS platforms — that branch redirects to `brainstorming`.
- Does not carry forward any licensing/asset-extraction guard logic from the superseded `docs/UI-desgin.md` proposal.
- Does not replace or modify the existing `reui` or `figma-design-to-code` skills.
- Does not auto-chain from `brainstorming`; the user or orchestrator invokes it directly (direct-invoke mode). In sub-flow mode it is called BY `brainstorming` or `project-kickoff` — see section 5a.

## 4. User Stories

### US-1: Platform detection (Priority: P1)

As an agent running the `designing-ui` skill, I want to detect the project's target platform automatically, so that I can apply the correct design workflow without asking the user for information already in the project files.

**Acceptance criteria:**

- GIVEN a project with `package.json`, `tsconfig.json`, or electron config files WHEN the skill starts THEN the platform is classified as `web-electron-ts` without prompting the user.
- GIVEN a project with `docs/superpowers/project/scaffold-design.md` (but no installed project files yet) WHEN the skill starts THEN the platform is read from that doc without prompting the user.
- GIVEN neither project files nor scaffold-design.md exist WHEN the skill starts THEN the agent asks the user one question: "What stack/platform is this project?"
- GIVEN the detected or declared platform is not `web-electron-ts` WHEN the skill processes the detection result THEN the skill stops, tells the user this branch is not yet designed, and suggests `superpowers-orchestrator:brainstorming` instead.

### US-2: Layout capture via Figma reference (Priority: P1)

As an agent running the `designing-ui` skill, I want to read a Figma file or node when the user provides a link, so that I can capture the structural layout and visual reference for mapping to components.

**Acceptance criteria:**

- GIVEN the user provides a Figma file/node URL WHEN the skill processes the layout step THEN the agent calls `get_metadata` and `get_screenshot` via the Figma MCP directly (not via `figma-design-to-code`) to retrieve the hierarchy and a visual screenshot.
- GIVEN the Figma reference resolves successfully WHEN the metadata is returned THEN the agent extracts section names, layout hierarchy, spacing, and component slots for use in the mapping step.
- GIVEN the Figma reference is inaccessible or returns an error WHEN `get_metadata` is called THEN the agent tells the user the reference could not be resolved and asks for another reference or a text description instead.
- GIVEN no Figma link is provided WHEN the agent asks for the layout THEN the agent accepts a plain text description of the desired layout as a valid alternative input.

### US-3: ReUI component mapping (Priority: P1)

As an agent running the `designing-ui` skill, I want to map each layout section to a free-tier ReUI component, so that the design doc records concrete component choices before implementation begins.

**Acceptance criteria:**

- GIVEN layout sections have been identified (from Figma or text description) WHEN the mapping step runs THEN the agent calls the ReUI MCP `search` tool once per section with a description of that section's purpose.
- GIVEN a ReUI search returns one or more free-tier matches WHEN results are evaluated THEN the agent records the best-matching component for that section in the mapping table.
- GIVEN a ReUI search returns no free-tier match for a section WHEN results are evaluated THEN the agent flags the section as a gap and tells the user explicitly rather than substituting a premium component.
- GIVEN all sections have been evaluated WHEN the mapping step is complete THEN the agent presents a summary table (section → component or gap) and seeks approval per section before writing the spec.

### US-4: Design doc and roadmap output (Priority: P1)

As an agent running the `designing-ui` skill, I want to write the approved design to a `design.md` spec, a `design.html` companion, and roadmap entries, so that the output is a durable, human-readable record that feeds the standard `writing-plans` workflow.

**Acceptance criteria:**

- GIVEN the user has approved the design WHEN the write step runs THEN `docs/superpowers/features/<slug>/design.md` is created from `skills/brainstorming/templates/spec-template.md` with an additional "Platform & Layout Source" block (detected platform, detection method, layout source, Figma reference if any).
- GIVEN `design.md` has been written WHEN the HTML companion step runs THEN `docs/superpowers/features/<slug>/design.html` is generated by filling `{{TITLE}}` and `{{CONTENT}}` in `skills/brainstorming/templates/document-companion-template.html`.
- GIVEN `design.md` has been written WHEN the roadmap step runs THEN one entry per User Story is appended to (or updated in) `docs/superpowers/roadmap.json` conforming to `assets/roadmap.schema.json`, and `docs/superpowers/ROADMAP.html` is regenerated from `assets/roadmap.html`.
- GIVEN all output files have been written WHEN the spec self-review step runs THEN the agent scans for TBD/placeholder text, checks internal consistency, scope, ambiguity, and template conformance before presenting the spec to the user.
- GIVEN the user has reviewed and accepted the spec AND the skill was invoked in direct mode WHEN the skill ends THEN the agent invokes `superpowers-orchestrator:writing-plans` and does not invoke any other skill.
- GIVEN the user has reviewed and accepted the spec AND the skill was invoked in sub-flow mode (by `brainstorming` or `project-kickoff`) WHEN the skill ends THEN control returns to the calling skill; the calling skill is responsible for invoking `writing-plans` exactly once after its own flow completes.

### US-5: Brainstorming injection point (Priority: P2)

As an agent running `superpowers-orchestrator:brainstorming`, I want to detect when a feature has a user-facing surface right after the Architecture sub-section of "Present design" is approved, so that UI design work happens through `designing-ui` instead of being improvised inline.

**Acceptance criteria:**

- GIVEN the Architecture sub-section of Present design has just been approved by the human WHEN the agent evaluates that approved content THEN it judges, from the Architecture content alone (no separate question), whether the feature has a user-facing surface (FrontEnd).
- GIVEN the agent judges the feature has a FrontEnd WHEN the judgment is made THEN the agent invokes `designing-ui` as a sub-flow with the human now, before continuing to the remaining Present-design sections (data flow, error handling, testing).
- GIVEN `designing-ui` sub-flow completes and produces its own `design.md` under the same feature slug WHEN brainstorming resumes THEN brainstorming continues its own remaining sections and later writes its own `design.md` as normal (two separate spec files: brainstorming's business/architecture spec, designing-ui's UI spec, same feature slug directory).
- GIVEN brainstorming reaches its terminal step WHEN `designing-ui` ran during this session THEN brainstorming invokes `superpowers-orchestrator:writing-plans` exactly ONCE, referencing BOTH spec paths.
- GIVEN brainstorming reaches its terminal step WHEN `designing-ui` did NOT run during this session (no FrontEnd judged) THEN brainstorming invokes `writing-plans` on its own spec alone (unchanged behavior).

> **Eval-evidence requirement (implementation gate):** Editing `skills/brainstorming/SKILL.md` to implement this injection point requires adversarial pressure testing and before/after eval evidence via `superpowers-orchestrator:writing-skills` before merge — as mandated by this repo's CLAUDE.md ("Skill Changes Require Evaluation"). This is a requirement for the IMPLEMENTATION PLAN to satisfy, not something resolved by this design document.

### US-6: Project-kickoff injection point (Priority: P2)

As an agent running `superpowers-orchestrator:project-kickoff`, I want to detect a FrontEnd stack from the Phase 2 "Stack" answer and route the initial UI shell through `designing-ui`, so that greenfield frontend projects get the same UI-design discipline as existing-project features.

**Acceptance criteria:**

- GIVEN the human has answered the Phase 2 "Stack" question (language, framework/library, package manager, test runner) WHEN Phase 3 (Scaffold spec) begins THEN the agent classifies the chosen framework/library using the same `web-electron-ts` vs `other` classification `designing-ui` Step 2 uses — no new question is asked, this reuses the existing Stack answer.
- GIVEN the classification is `web-electron-ts` (FrontEnd) WHEN the scaffold spec is being written THEN the scaffold spec ALSO includes an initial UI-shell/skeleton-page task, and `designing-ui` runs as a sub-flow on that shell (same dual-mode contract as the brainstorming injection: sub-flow mode, does not call `writing-plans` itself), producing its own spec file.
- GIVEN the classification is `other` (no FrontEnd, e.g. CLI/library/IaC) WHEN Phase 3 runs THEN the scaffold spec is written as today — tooling only, no UI-shell task, no `designing-ui` invocation.
- GIVEN Phase 4 (Handoff) runs and the FrontEnd path was taken WHEN the agent hands off THEN it invokes `writing-plans` exactly ONCE, referencing BOTH `docs/superpowers/project/scaffold-design.md` and the designing-ui shell spec.
- GIVEN Phase 4 runs and no FrontEnd was detected WHEN the agent hands off THEN behavior is unchanged — `writing-plans` on `scaffold-design.md` alone.

> **Eval-evidence requirement (implementation gate):** Editing `skills/project-kickoff/SKILL.md` to implement this injection point requires adversarial pressure testing and before/after eval evidence via `superpowers-orchestrator:writing-skills` before merge — same gate as US-5. This is a requirement for the IMPLEMENTATION PLAN to satisfy, not something resolved by this design document.

## 5. Approach

The skill is implemented as a **full sibling skill** — a standalone `SKILL.md` file under `skills/designing-ui/` that loads `reui` as a peer and calls Figma MCP tools directly. It does not wrap or extend `brainstorming`, and it does not modify any existing skill file.

This approach was chosen because it:
- Keeps the new skill's checklist self-contained and independently evolvable.
- Follows the existing layering pattern (peer loading) without creating fragile edits to auto-regenerated skill files.
- Gives it the same terminal-state contract as `brainstorming` (`writing-plans`) with no change to downstream tooling.
- Avoids the brittleness of delegating to `brainstorming` and intercepting its output mid-flow.

## 5a. Invocation Modes

The skill operates in two distinct invocation modes that share Steps 1–9 identically; only the terminal action (Step 10) differs:

### Direct invoke (human calls `designing-ui` explicitly)

The full 10-step checklist runs as specified. Step 10 is terminal: the agent invokes `superpowers-orchestrator:writing-plans` directly, referencing the `design.md` it produced, and does not invoke any other skill.

### Sub-flow invoke (called BY `brainstorming` or `project-kickoff`)

Steps 1–9 are identical — human-in-the-loop approval of the layout mapping (Step 6) and the written spec (Step 9) remain required in both modes. Step 10 changes: the agent does **NOT** invoke `writing-plans` itself. Instead it returns control to the calling skill. The calling skill is then responsible for invoking `writing-plans` exactly once after its own flow completes, passing both its own spec path and the `designing-ui` spec path. This prevents a double `writing-plans` invocation when the UI spec is just one part of a larger design session.

| Step | Direct invoke | Sub-flow invoke |
|------|---------------|-----------------|
| 1–9  | Identical | Identical |
| 10   | Agent calls `writing-plans` on own spec | Returns control to caller; caller calls `writing-plans` once on both specs |

### Alternatives considered

| Option | Why rejected |
|--------|-------------|
| B: Thin wrapper around `brainstorming` — invoke `brainstorming` and intercept or post-process its output to add platform detection and component mapping | `brainstorming` has no hook/extension points; the wrapper would need to duplicate or shadow large parts of its checklist, creating a maintenance coupling risk every time `brainstorming` evolves. |
| C: Extend the shared `spec-template.md` — add a conditional "UI variant" section to the existing template that any skill can optionally activate | The template is a document structure specification, not a skill workflow; adding control-flow conditions there would blur the template's purpose and make it harder to maintain. The platform-detection and component-mapping steps belong in a skill, not in a document template. |

## 6. Design

### Architecture

```
superpowers-orchestrator:designing-ui  (new SKILL.md — future work)
  │
  ├── reads  .ua/knowledge-graph.json or .understand-anything/knowledge-graph.json
  ├── reads  docs/superpowers/project/scaffold-design.md
  ├── calls  Figma MCP: get_metadata, get_screenshot
  ├── loads  skill: reui  →  calls ReUI MCP: search
  │
  ├── writes docs/superpowers/features/<slug>/design.md
  ├── writes docs/superpowers/features/<slug>/design.html
  ├── writes docs/superpowers/roadmap.json
  ├── writes docs/superpowers/ROADMAP.html
  │
  └── invokes superpowers-orchestrator:writing-plans
```

The skill is a sequential checklist (Steps 1–10). Steps 1–2 are read-only discovery; steps 3–6 are interactive (human-in-the-loop); steps 7–10 are write and hand-off.

### Platform & Layout Source

- **Detected platform:** `web-electron-ts` (the in-scope branch for this skill).
- **Detection method:** project file inspection → scaffold-design.md → direct human question (first source that resolves wins).
- **Layout source:** Figma file/node URL or human text description (first provided wins; Figma is preferred).
- **Figma MCP tools used:** `get_metadata` (hierarchy + spacing), `get_screenshot` (visual reference). No code-generation tools are called.

### Components & Interfaces

| Component | Role | Depends on |
|-----------|------|------------|
| `designing-ui` SKILL.md | Orchestrates the 10-step checklist | Figma MCP, ReUI MCP, `reui` skill |
| Figma MCP | Provides `get_metadata` and `get_screenshot` | External Figma API |
| ReUI MCP | Provides `search` for free-tier component lookup | External ReUI registry |
| `reui` skill | Peer-loaded for `adapting.md` reuse-first rules | ReUI MCP |
| `spec-template.md` | Document structure for `design.md` output | — |
| `document-companion-template.html` | HTML wrapper for `design.html` output | — |
| `roadmap.json` / `ROADMAP.html` | Persistent roadmap updated per feature spec | `roadmap.schema.json`, `assets/roadmap.html` |

### Data Model & Flow

```
Human input (Figma URL or text description)
  ↓
[Step 1] knowledge-graph read  →  project context (best-effort)
[Step 2] platform detection    →  "web-electron-ts" | STOP (other)
[Step 3] layout question       →  Figma URL | text description
[Step 4] Figma MCP calls       →  section list + screenshot (if Figma)
[Step 5] ReUI search (per §)   →  component mapping table + gap list
[Step 6] approval loop         →  human-approved mapping
[Step 7] write design.md       →  spec file on disk
         write design.html     →  HTML companion on disk
         write roadmap.json    →  one entry per US
         write ROADMAP.html    →  regenerated HTML roadmap
[Step 8] spec self-review      →  agent-verified: no TBD, consistent, in-template
[Step 9] user review           →  human approval of written spec
[Step 10] invoke writing-plans →  terminal state
```

### Error Handling

| Failure | Behaviour |
|---------|-----------|
| Figma MCP unavailable | Degrade to text-description path; tell the user |
| Figma reference not accessible | Tell user; ask for another reference or text description |
| ReUI MCP unavailable | Tell user; ask them to describe components manually; record gaps |
| Platform not detectable | Ask user one question before continuing |
| Platform is `other` | Stop; redirect to `brainstorming` |

### Edge Cases

- User provides a Figma link that is accessible but the node ID resolves to an empty frame: treat as not accessible; ask for a more specific node or text description.
- User has both project files and a scaffold-design.md with conflicting stack declarations: prefer installed project files (ground truth over pre-init plans).
- ReUI search returns only premium-tier results for a section: treat as a gap (no free match); flag to user; do not record a premium result.

## 7. Testing Strategy

Each user story's acceptance criteria are verified manually by running the skill in a controlled environment and observing its behaviour at each step:

- **US-1 (Platform detection):** Execute the skill against (a) a repo with `package.json` + `tsconfig.json`, (b) a bare repo with only `scaffold-design.md`, (c) an empty repo, (d) a native-mobile repo. Confirm the correct branch is taken in each case.
- **US-2 (Figma capture):** Provide (a) a valid Figma URL, (b) an invalid/private URL, (c) no URL. Confirm `get_metadata` + `get_screenshot` are called only in case (a), and fallback behaviour fires for (b) and (c).
- **US-3 (ReUI mapping):** Supply a layout with three sections — one with a clear free-tier match, one with no match, one ambiguous. Confirm the mapping table records the match, flags the gap, and prompts approval.
- **US-4 (Output files):** After a complete skill run, verify `design.md` conforms to `spec-template.md`, `design.html` is valid HTML derived from the companion template, `roadmap.json` validates against `assets/roadmap.schema.json` with one entry per US, and `ROADMAP.html` is generated from `assets/roadmap.html`.
- **Spec self-review (Step 8):** Search the written `design.md` for the strings "TBD", "TODO", and "placeholder"; confirm zero matches.

## 8. Success Criteria

- SC-1: An agent invoking `superpowers-orchestrator:designing-ui` on a `web-electron-ts` project completes the full 10-step workflow and produces all four output files (`design.md`, `design.html`, `roadmap.json`, `ROADMAP.html`) without manual intervention beyond the two required approval steps (section mapping and spec review).
- SC-2: The written `design.md` passes the spec self-review scan (zero TBD/TODO/placeholder occurrences) and conforms to `spec-template.md` structure.
- SC-3: `roadmap.json` validates against `assets/roadmap.schema.json` with one entry per User Story, status `open`, `completed: null`.
- SC-4: Invoking the skill on a non-`web-electron-ts` project terminates cleanly with a redirect message to `brainstorming` and produces no output files.
- SC-5 (direct mode): The skill's terminal state in direct-invoke mode is always `superpowers-orchestrator:writing-plans` — no other skill is invoked on successful completion.
- SC-6 (sub-flow mode): In sub-flow mode the skill does NOT invoke `writing-plans`; it returns control to the calling skill, which invokes `writing-plans` exactly once referencing both specs.
