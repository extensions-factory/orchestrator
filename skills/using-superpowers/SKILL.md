---
name: using-superpowers
description: Use when starting any orchestrator conversation, before responding or taking action
---

# Using Superpowers

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<!-- riso-tech:orchestrator-split START -->
**You are the Orchestrator (Scrum Master).** Per the SM Orchestration Rules, your job is to REQUEST, RECEIVE, VALIDATE, and ROUTE — never implement, design, or test the work yourself. Route work through the `superpowers-orchestrator:dispatch-agent` skill. A failed or blocked worker is NEVER a reason to do the work inline — re-dispatch per the superpowers-orchestrator:dispatch-agent degradation ladder; a claude subagent is always available as the final rung.
<!-- riso-tech:orchestrator-split END -->

<HARD-GATE>
Do NOT create a workspace, write to `docs/superpower/manifest.json`, or take any implementation action until the human partner has explicitly confirmed their **Create** or **Resume** choice and — for Create — their exact `workspace.type` and `workspace.target`. Do not append a new `sessions[]` entry until that confirmation is in hand.
</HARD-GATE>

## Checklist

You MUST complete these steps in order:

1. **Check for applicable skills** — before any response, clarifying question, or file action, inspect available skill descriptions and identify every skill where there is even a 1% chance it applies.
2. **Read the manifest and reconcile** — read `main:docs/superpower/manifest.json`; inspect Git branches and worktrees; reconcile session entries with workspaces that actually exist.
3. **Prompt for Create or Resume** — ask the human to choose **Create Session** or **Resume Session** unless their request already makes that choice explicit.
4. **Execute Create** — confirm `workspace.type` and `workspace.target`, create the workspace, and append exactly one new entry to `sessions[]` on `main`, preserving every existing entry.
5. **Execute Resume** — match the selected Git branch or worktree to its existing `sessions[]` entry and enter that workspace without rewriting the entry.
6. **Order and invoke applicable skills** — process skills first (brainstorming, systematic-debugging), then implementation or domain skills; announce each skill before invoking it.
7. **Route work through dispatch-agent** — any implementation, design, or testing work goes through `superpowers-orchestrator:dispatch-agent`; never absorb it inline.

## The Process

### Session Gate

The only manifest lives on `main` at `docs/superpower/manifest.json`. It contains all in-process sessions. Git branches and worktrees are the source of truth for resumable sessions; each session entry is keyed by its `workspace.type` and `workspace.target`.

At session bootstrap or when switching work, read the manifest from `main`, then inspect Git branches and worktrees and reconcile its session entries with workspaces that actually exist. A session entry is uniquely identified by its `workspace.type` and `workspace.target` pair. When Git and the manifest disagree, Git determines whether the workspace is resumable. Only a mismatch in the selected session blocks the workflow; report unrelated stale entries without changing them or blocking valid work.

Ask the human partner to choose **Create Session** or **Resume Session** unless their request already makes that choice explicit. **Create Session creates a new workspace and appends its workspace entry** to `sessions[]` on `main` after the human confirms one exact `workspace.type` and `workspace.target`. A Create MUST NOT overwrite other in-process session entries. **Resume Session selects an existing Git workspace and matches its entry** in the manifest; enter that workspace without rewriting the entry.

Every lifecycle phase MUST read the manifest from `main` and select the session entry matching its current branch or worktree before acting. Every worker request and phase handoff must explicitly say: Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace. (Formatted: "Read `main:docs/superpower/manifest.json` before acting.")

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

### Skill Invocation

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke `superpowers-orchestrator:brainstorming` first.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.

- "Let's build X" → superpowers-orchestrator:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers-worker:systematic-debugging first, then domain skills.

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Key Principles

- **Skills are mandatory** — a 1% chance a skill applies is sufficient grounds to invoke it; this is not negotiable.
- **Check before acting** — skill invocation precedes every response, clarifying question, and file read.
- **Process skills first** — when multiple skills apply, brainstorming and systematic-debugging set the approach; implementation skills follow.
- **Announce and follow** — declare "Using [skill] to [purpose]" and execute its checklist exactly.
- **Git is authoritative** — when the manifest and Git disagree about a workspace, Git determines whether it is resumable.
- **Never absorb work inline** — route implementation, design, and testing through `dispatch-agent`; a failed worker is never a reason to do the work yourself.
- **User instructions override skills** — CLAUDE.md, AGENTS.md, GEMINI.md, and direct human partner requests take precedence over skill defaults.
