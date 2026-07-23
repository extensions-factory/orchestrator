---
name: project-kickoff
description: Use when starting a greenfield project without an existing repository or meaningful code
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

# Project Kickoff

**Announce at start:** "I'm using the project-kickoff skill to turn this idea into a validated, scaffolded starting point."

## Trigger

Use this skill when **either** holds:

1. **No repo/meaningful code exists** — the directory is empty, `git rev-parse --git-dir` fails, or only stray non-code files exist (a lone `.gitignore`, `LICENSE`); **or**
2. **Explicit greenfield language** — "new project", "from scratch", "start a new app/tool/service".

**Redirect guard:** If the directory holds a real existing project, STOP and use `superpowers-orchestrator:brainstorming` instead. Never scaffold a new repo on top of one that already exists.

## Flow

Discovery (+ backlog) → Setup → Scaffold spec → Handoff. Each phase is defined below. **Do not skip or reorder phases.** Discovery gates everything after it.

## Phase 1 — Discovery (gates everything)

1. **Idea capture** — ask exactly one question: "What are you building, in a sentence?" Use the answer to seed research and later stack questions. Do not persist it as a vision doc.

2. **Pick the research track** from the idea-capture answer — the *track* adapts to the project, the fan-out itself never gets skipped:
   - **Market-facing product** — the answer names end users or customers to win (app, SaaS, service, game).
   - **Technical build** — the answer names infrastructure, IaC, internal tooling, a library, or a devtool: there is no market to win; the "competition" is prior art to adopt.

   If the answer doesn't clearly place it, ask one multiple-choice question: "Is this a product for users/customers, or a technical/internal build?"

3. **Research fan-out** — dispatch parallel research subagents with `superpowers-orchestrator:dispatching-parallel-agents` (use the `deep-research` skill where a deep multi-source pass fits). Four independent investigations for the chosen track, no shared state:

   *Market-facing product:*
   - Similar/competing products
   - Market size & potential
   - Risks (technical, legal, adoption)
   - Differentiation opportunities

   *Technical build:*
   - Best practices & standards for the domain (e.g. module layout, state management, naming conventions)
   - Existing reference designs/architectures to adopt or fork
   - Risks (technical, operational, security)
   - Tooling/ecosystem landscape (mature tools vs build-your-own)

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D1`, `D2`, `D3`, and `D4` are four distinct dispatches: use `superpowers-orchestrator:dispatching-parallel-agents` to send one independent worker for each of the chosen track's four research domains in the order listed above (D1 first domain, D2 second, D3 third, D4 fourth), each through `superpowers-orchestrator:dispatch-agent` with `role: business_analyst`, `task_type: discovery_research`, and only that domain's context; issue all four in one fan-out, then wait for all four results before `D5`.
<!-- riso-tech:orchestrator-split END -->

4. **Synthesize, validate, present.**

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D5` runs only after `D1`–`D4` return: dispatch `role: business_analyst`, `task_type: discovery_research` through `superpowers-orchestrator:dispatch-agent` to synthesize their results into the discovery document `docs/superpowers/specs/YYYY-MM-DD-<topic>-discovery.md`, covering the selected track's four acceptance areas, and to close the doc with a **Proposed backlog** section decomposing the findings into an Epic → Feature → User Story hierarchy (candidates only, no specs); validate the returned file and present it to the human before Setup.
<!-- riso-tech:orchestrator-split END -->

5. **Confirm the backlog (inline, never dispatched).** Present the discovery doc's Proposed backlog to the human and refine it together — the discovery findings seed the candidates; the human edits, adds, drops, and approves before anything is written to the roadmap. This is a live conversation like `superpowers-orchestrator:brainstorming`; a dispatched worker never talks to the human. The confirmed Epic → Feature → US list is the input Phase 3 writes to `roadmap.json`. Do not seed the roadmap from unconfirmed candidates.

**This phase gates the rest.** Do not start Setup until the discovery doc is written, validated, and presented — even if the human "already knows the space." Once Setup begins, do not proceed beyond repository initialization until `D7` commits the generated `.gitignore` and then the discovery document. The research grounds the stack decision and the later `superpowers-orchestrator:brainstorming` session.

## Phase 2 — Setup

Ask questions **one at a time**, multiple-choice where possible (same discipline as `superpowers-orchestrator:brainstorming`), informed by the discovery doc.

1. **Stack** — language, framework/library, package manager, test runner.
2. **Standards** — formatter/linter, naming conventions, commit convention, test-file convention.
3. **AI tools** — multi-select: "Which AI coding tools do you use?" (Claude Code, Codex, Gemini CLI, Copilot, other/none). This drives which per-tool instruction files the scaffold spec will create.

### Step 4 — Bootstrap the repo

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D6` initializes the Git repository: if `git rev-parse --git-dir` fails, dispatch `git init` alone through `superpowers-orchestrator:dispatch-agent` with `role: devops_engineer` and `task_type: workspace_setup`; if a repository already exists, skip D6, and do not continue to `D7` until repository initialization is confirmed; run it inline only if the harness has no subagent capability at all.
<!-- riso-tech:orchestrator-split END -->

### Step 5 — Create the bootstrap commits

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D7` creates two isolated commits after `D6` succeeds or an existing repository is confirmed: dispatch `role: devops_engineer` and `task_type: workspace_setup` through `superpowers-orchestrator:dispatch-agent`, making `.gitignore` the initial commit when `HEAD` is absent and committing discovery second, following the steps below; run it inline only if the harness has no subagent capability at all.
<!-- riso-tech:orchestrator-split END -->

1. **Generate `.gitignore`.** If `.gitignore` already exists, stop and ask the human whether to preserve or replace it. Otherwise map every approved language, framework/library, package manager, and test runner to the smallest covering set of valid gitignore.io templates; count a broader template as coverage only when its generated patterns cover that stack choice's outputs. Follow `https://docs.gitignore.io/install/command-line`, using `curl --fail --silent --show-error --location` for both the template-list and generation requests. Validate names against `https://www.toptal.com/developers/gitignore/api/list`, fetch the templates in one comma-separated request into a repository-root temporary file, and require non-empty output whose `Created by` and `End of` markers contain the exact request URL before moving it to `.gitignore`. Do not modify a shell profile or global Git configuration. On any request, response-validation, or coverage failure, remove the temporary file and stop without creating or truncating `.gitignore`.
2. **Commit `.gitignore`.** Run `git rev-parse --verify HEAD` before committing: absent `HEAD` makes this the initial commit; otherwise it is normal. For this commit, stage only `.gitignore`, run `git diff --cached --name-only`, and require exactly `.gitignore` with no `.superpowers/` entry or other file before committing with the approved convention.
3. **Commit discovery.** For the second commit, stage only the discovery document `docs/superpowers/specs/YYYY-MM-DD-<topic>-discovery.md`, repeat the exact staged-path check for that file, and commit it separately. On any mismatch, stop without committing.
4. **Return evidence.** The worker must return both commit SHAs as a labelled commit SHA for each file, the template-to-stack coverage mapping, both staged-path outputs, and `git show --name-only --format= <sha>` output proving each SHA contains only its intended file. Do not continue to the scaffold spec until both commits are verified.

These bootstrap commits are the one piece of setup nothing downstream can do for itself.

## Phase 3 — Scaffold spec

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D8` dispatches the scaffold spec through `superpowers-orchestrator:dispatch-agent` with `role: tech_lead` and `task_type: architecture_design`; the worker writes `docs/superpowers/specs/YYYY-MM-DD-<topic>-scaffold-design.md` from the discovery and approved stack/tooling choices, initializes the product roadmap as described below, and the orchestrator validates and presents the returned artifacts for user approval before handing the scaffold spec to `superpowers-orchestrator:writing-plans`; write them inline only if the harness has no subagent capability at all.
<!-- riso-tech:orchestrator-split END -->

Write `docs/superpowers/specs/YYYY-MM-DD-<topic>-scaffold-design.md` using the standard `superpowers-orchestrator:brainstorming` spec format and self-review, scoped to tooling not features. Express all concrete scaffolding as **tasks for the plan** (do NOT run them here):

- Run the stack's **official init command** (ecosystem-native: `npm create …`, `cargo new`, `uv init`, `go mod init`, …) and install the chosen lint/format/test tooling. See `references/stack-init-commands.md`.
- Write `CONSTITUTION.md` — the single canonical source of truth for the Phase 2 standards answers.
- Write **thin per-tool instruction files** for each selected AI tool (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, …), each a pointer ("See `CONSTITUTION.md` for this project's coding standards") plus any genuinely tool-specific config. Follows `docs/superpowers/specs/2026-05-05-platform-neutral-config-refs-design.md`.
- Write enforceable config (`.eslintrc`/`.prettierrc`/`pyproject.toml`/…) matching the constitution.
- Write a minimal CI stub (lint + test) for the developer's git host. See `references/ci-stub-templates.md`.
- Walking-skeleton verification: run build/dev/test and the linter once; confirm a green baseline before the branch is finished.

Seed the product roadmap during `D8` from the **confirmed backlog** (Phase 1 step 5): write `docs/superpowers/roadmap.json` with one entry per confirmed User Story and generate `docs/superpowers/ROADMAP.html`, following `${CLAUDE_PLUGIN_ROOT}/skills/brainstorming/roadmap.md` and starting from `${CLAUDE_PLUGIN_ROOT}/assets/roadmap.html` verbatim. Follow that file's level mapping exactly: **Epic → summary card**, **Feature → exactly one detail section** (dedup by feature — never emit two sections for the same feature), **User Story → one `.item`**. Every seeded US is `status: open` with `spec` and `plan` set to `null`; kickoff creates no spec but Scaffold, so no roadmap entry points at a spec yet. `superpowers-orchestrator:brainstorming` attaches specs and adds later User Stories per feature as it designs them. Write nothing that wasn't in the human-confirmed backlog; if the backlog is empty, write `[]`.

## Phase 4 — Handoff

Invoke `superpowers-orchestrator:writing-plans` on the scaffold spec. From there the existing pipeline runs unmodified. After the scaffold branch is finished, `superpowers-orchestrator:brainstorming` designs the first real feature — now against a tested repo with market context in hand.

**This is the terminal state.** Do NOT invoke any other implementation skill; `superpowers-orchestrator:writing-plans` is the next step.

## Red Flags

| Situation | Rule |
|---|---|
| Directory isn't actually empty (unrelated files present) | Stop and ask before `git init` / init commands — don't silently treat a non-empty dir as greenfield. |
| Idea-capture answer describes a feature for an *existing* project | Stop — not greenfield. Redirect to `superpowers-orchestrator:brainstorming`. |
| "I already know the space, skip the research" | Discovery gates everything. Run the research fan-out anyway — it grounds the stack decision and later brainstorming. |
| "Market research is irrelevant for this IaC/internal tool" | Wrong track, not wrong gate — switch to the technical-build track (best practices, reference designs), still run the fan-out. |
| Stack init command fails (registry error, tool not installed) | Surface the failure; don't hand-write files faking what the tool would have produced. |
| Unknown stack/tool combo with no known init command | Ask the user for the exact command rather than guessing. |
| "It's a toy project, skip the CI stub / verification" | The scaffold spec still lists the CI stub and walking-skeleton verification. A green baseline is the point of kickoff. |
| Walking-skeleton verification fails | Do not finish the branch or hand off to `superpowers-orchestrator:brainstorming` with a broken baseline. |
| Tempted to run init/lint/CI commands here | Don't. Concrete scaffolding is plan tasks (Phase 3), executed by the pipeline — not by this skill. |
| Seeding the roadmap from discovery candidates the human never confirmed | Stop. Phase 1 step 5 confirmation gates the seed. Present the Proposed backlog, refine it with the human, then write only what they approved. |
| Two detail sections rendered for the same Feature | Wrong. One detail section per distinct Feature (dedup, first-appearance order); its User Stories are `.item`s inside it. See `roadmap.md`. |
| Attaching a spec path to a seeded US, or inventing a Scaffold roadmap entry | Seeded US are `status: open`, `spec`/`plan` = `null`. Scaffold is tooling, not a product US — it stays its own spec, off the roadmap. |
