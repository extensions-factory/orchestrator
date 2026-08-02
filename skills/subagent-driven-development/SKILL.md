---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration

**Git ownership:** Implementation workers never commit or push; they edit files, run tests, and report. The orchestrator owns Git bookkeeping after every successful implementation or fix response.

**Narration:** between tool calls, narrate at most one short line — the
ledger and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, a decision-change proposal awaiting its owning human gate, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

## Approved Execution Boundary

The token-cost boundary starts when this skill is announced. Capture the exact cumulative orchestrator counter scope and baseline when the harness exposes them.

**Read `main:docs/superpower/manifest.json` and select the session entry matching the current workspace** by `workspace.type` and `workspace.target`; require exactly one session entry and preserve every other session entry. Require `writing_plans.workflow_id` plus approved `scope`, `exclusions`, `ordering`, `files`, `interfaces`, `tests`, and `verification`. For feature work also require `brainstorming.scope`, `brainstorming.exclusions`, and `brainstorming.acceptance_criteria`.

Use `writing_plans.workflow_id` as the active run. Accept only the exact plan path and content hash handed off by Writing Plans or Receiving Plan Refine, resolve it inside the current worktree, and verify the plan matches the approved records. Capture the exact approved decision snapshot, workspace key, plan path/hash, and optional design path/hash. Ambient run IDs and another session's artifacts never override them.

Every D13–D18 request includes `DECISION_RECORD=main:docs/superpower/manifest.json`, the workspace key, workflow ID, exact approved decision snapshot, exact plan path and content hash, task brief/report/review paths, and this instruction: “Read main:docs/superpower/manifest.json before acting and select the entry matching the current workspace.” Before editing or reviewing, the worker compares the selected record and plan hash with the request; a mismatch returns a blocked response with reason `stale_input` without acting.

Before every dispatch and after every worker response, reread the selected main-manifest entry and rehash the plan. Stale input blocks Git bookkeeping, review, and the next task.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Harness has subagent capability?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Harness has subagent capability?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Harness has subagent capability?" -> "subagent-driven-development" [label="yes"];
    "Harness has subagent capability?" -> "executing-plans" [label="no"];
}
```

**vs. Executing Plans (no-subagent harness):**
- When subagents are available, use this skill in whichever session executes the plan
- Fresh subagent per task (no context pollution)
- Review after each task (spec compliance + code quality), broad review at the end
- Faster iteration (no human-in-loop between tasks)

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "Dispatch implementer subagent (prompts/implementer-prompt.md)" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer subagent implements, tests, self-reviews, reports" [shape=box];
        "Orchestrator commits successful worker changes" [shape=box];
        "Generate review package, dispatch task reviewer subagent (prompts/task-reviewer-prompt.md)" [shape=box];
        "Task reviewer reports spec ✅ and quality approved?" [shape=diamond];
        "Dispatch fix subagent for Critical/Important findings" [shape=box];
        "Mark task complete in todo list and progress ledger" [shape=box];
    }

    "Read plan, note context and global constraints, create todos" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Dispatch final code reviewer subagent (../requesting-code-review/prompts/code-reviewer.md)" [shape=box];
    "Final reviewer reports clean?" [shape=diamond];
    "Dispatch one final fix subagent" [shape=box];
    "Orchestrator commits successful final-fix changes" [shape=box];
    "Use superpowers-orchestrator:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

    "Read plan, note context and global constraints, create todos" -> "Dispatch implementer subagent (prompts/implementer-prompt.md)";
    "Dispatch implementer subagent (prompts/implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent (prompts/implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, self-reviews, reports" [label="no"];
    "Implementer subagent implements, tests, self-reviews, reports" -> "Orchestrator commits successful worker changes";
    "Orchestrator commits successful worker changes" -> "Generate review package, dispatch task reviewer subagent (prompts/task-reviewer-prompt.md)";
    "Generate review package, dispatch task reviewer subagent (prompts/task-reviewer-prompt.md)" -> "Task reviewer reports spec ✅ and quality approved?";
    "Task reviewer reports spec ✅ and quality approved?" -> "Dispatch fix subagent for Critical/Important findings" [label="no"];
    "Dispatch fix subagent for Critical/Important findings" -> "Orchestrator commits successful worker changes" [label="successful fix"];
    "Task reviewer reports spec ✅ and quality approved?" -> "Mark task complete in todo list and progress ledger" [label="yes"];
    "Mark task complete in todo list and progress ledger" -> "More tasks remain?";
    "More tasks remain?" -> "Dispatch implementer subagent (prompts/implementer-prompt.md)" [label="yes"];
    "More tasks remain?" -> "Dispatch final code reviewer subagent (../requesting-code-review/prompts/code-reviewer.md)" [label="no"];
    "Dispatch final code reviewer subagent (../requesting-code-review/prompts/code-reviewer.md)" -> "Final reviewer reports clean?";
    "Final reviewer reports clean?" -> "Use superpowers-orchestrator:finishing-a-development-branch" [label="yes"];
    "Final reviewer reports clean?" -> "Dispatch one final fix subagent" [label="no"];
    "Dispatch one final fix subagent" -> "Orchestrator commits successful final-fix changes";
    "Orchestrator commits successful final-fix changes" -> "Dispatch final code reviewer subagent (../requesting-code-review/prompts/code-reviewer.md)" [label="regenerate package"];
}
```

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D13` runs for every plan task in sequence: call `superpowers-orchestrator:dispatch-agent` with `role: software_engineer` and the plan task's task_type, paste `prompts/implementer-prompt.md` into the prompt body, and provide the approved execution boundary, task brief, global constraints, required prior-task interfaces, and report path so the worker can implement and test that task; after a successful current-snapshot response, the orchestrator performs Git bookkeeping inline, generates the task review package from the recorded pre-task SHA through the new commit, and sends the same boundary and task artifacts to `D14`, repeating D13–D16 for every plan task before `D17`.
<!-- riso-tech:orchestrator-split END -->

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D16` runs when `D14` or conditional `D15` reports Critical/Important findings that are implementation defects: call `superpowers-orchestrator:dispatch-agent` once with `role: software_engineer`, the plan task's task_type, `skill: superpowers-worker:receiving-code-review`, the approved execution boundary, original task brief/report, complete actionable findings, and covering test commands; never send a decision-change proposal to D16. The worker fixes the task and reruns and records those tests, then after a successful current-snapshot response the orchestrator performs Git bookkeeping inline, regenerates the task review package, and re-dispatches `D14` with the same boundary for re-review, repeating D16→D14 until clean.
<!-- riso-tech:orchestrator-split END -->

<!-- riso-tech:orchestrator-split START -->
**Dispatch:** `D18` runs only when final review `D17` returns implementation findings: send the complete findings list in one fix wave through `superpowers-orchestrator:dispatch-agent` with `role: software_engineer`, `task_type: implementation_coding`, `skill: superpowers-worker:receiving-code-review`, and the approved execution boundary; never include a decision-change proposal. Require the worker to fix the whole-branch issues and report covering/full test results, then after a successful current-snapshot response the orchestrator performs Git bookkeeping inline, regenerates the whole-branch review package, and re-dispatches `D17` with the same boundary; repeat one wave at a time until the final whole-branch review is clean.
<!-- riso-tech:orchestrator-split END -->

## Pre-Flight Plan Review

Before dispatching Task 1, scan the plan once for conflicts:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that the review rubric treats as a
  defect (a test that asserts nothing, verbatim duplication of a logic block)

Present everything you find to your human partner as one batched question —
each finding beside the plan text that mandates it, asking which governs —
before execution begins, not one interrupt per discovery mid-plan. If the
scan is clean, proceed without comment. The review loop remains the net for
conflicts that only emerge from implementation.

## Decision Changes Stop Execution

Judge a proposed edit by its actual effect, not the worker/reviewer label. If it would change `brainstorming.scope`, `brainstorming.exclusions`, `brainstorming.acceptance_criteria`, or any approved Writing Plans field, record a `decision_change_proposal` with affected fields, exact current values, proposed values, evidence, and originating task/finding.

For a decision proposal, D13/D16/D18 do not edit code, the plan, or the manifest; D14/D15/D17 remain read-only. Stop the task and route product scope, exclusions, or acceptance changes to the Brainstorming Human Gate. Route ordering, files, interfaces, tests, verification, or other build-only changes to Writing Plans' Final build decision gate. When both are affected, Brainstorming resolves first and Writing Plans regenerates afterward.

Human rejection resumes against the unchanged snapshot. Human approval is not permission to patch inline: the owning gate updates the selected main-manifest entry and regenerates/reapproves every affected design and plan artifact. Then capture new hashes and revalidate every completed task against the new decisions and plan, starting again at the earliest affected task. Refine/execute continuity never makes a changed decision retroactive.

## Model Selection

<!-- riso-tech:orchestrator-split START -->
**Under the orchestrator split, this section is rationale, not procedure.** Model choice is made by `superpowers-orchestrator:dispatch-agent` Steps 1–2 (`task_type` → `sdlc-model-routing.json` lookup → readiness preflight). Never hand-pick a model or call the Agent tool directly at any dispatch node — including Task 1 and workspace setup. A dispatch that skips the lookup is a protocol violation even when the worker would be a claude subagent. If the table's pick conflicts with this section's principles, the table wins.
<!-- riso-tech:orchestrator-split END -->

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture and design tasks**: use the most capable available model.
The final whole-branch review is one of these — dispatch it on the most
capable available model, not the session default.

**Review tasks**: choose the model with the same judgment, scaled to the
diff's size, complexity, and risk. A small mechanical diff does not need the
most capable model; a subtle concurrency change does.

**Always specify the model explicitly when dispatching a subagent.** An
omitted model inherits your session's model — often the most capable and
most expensive — which silently defeats this section.

**Turn count beats token price.** Wall-clock and context cost scale with how
many turns a subagent takes, and the cheapest models routinely take 2-3× the
turns on multi-step work — costing more overall. Use a mid-tier model as the
floor for reviewers and for implementers working from prose descriptions.
When the task's plan text contains the complete code to write, the
implementation is transcription plus testing: use the cheapest tier for
that implementer. Single-file mechanical fixes also take the cheapest tier.

**Task complexity signals (implementation tasks):**
- Touches 1-2 files with a complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Validate the report and diff, perform the task's orchestrator-only Git bookkeeping, then generate the review package (`scripts/review-package BASE HEAD`, from this skill's directory — it prints the unique file path it wrote; BASE is the commit recorded before dispatching the implementer — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task) and dispatch the task reviewer with the printed path.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them, then follow the DONE bookkeeping-and-review sequence.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Handling Reviewer ⚠️ Items

The task reviewer may report "⚠️ Cannot verify from diff" items — requirements
that live in unchanged code or span tasks. These do not block the rest of the
review, but you must resolve each one yourself before marking the task
complete: you hold the plan and cross-task context the reviewer
lacks. If you confirm an item is a real gap, treat it as a failed spec
review — send it back to the implementer and re-review.

## Constructing Reviewer Prompts

Per-task reviews are task-scoped gates. The broad review happens once, at the
final whole-branch review. When you fill a reviewer template:

- Do not add open-ended directives like "check all uses" or "run race tests
  if useful" without a concrete, task-specific reason
- Do not ask a reviewer to re-run tests the implementer already ran on the
  same code — the implementer's report carries the test evidence
- Do not pre-judge findings for the reviewer — never instruct a reviewer to
  ignore or not flag a specific issue. If you believe a finding would be a
  false positive, let the reviewer raise it and adjudicate it in the review
  loop. If the prompt you are writing contains "do not flag," "don't treat X
  as a defect," "at most Minor," or "the plan chose" — stop: you are
  pre-judging, usually to spare yourself a review loop.
- The global-constraints block you hand the reviewer is its attention
  lens. Copy the binding requirements verbatim from the plan's Global
  Constraints section or the spec: exact values, exact formats, and the
  stated relationships between components ("same layout as X", "matches
  Y"). The reviewer's template already carries the process rules (YAGNI,
  test hygiene, review method) — the constraints block is for what THIS
  project's spec demands.
- Hand the reviewer its diff as a file: run this skill's
  `scripts/review-package BASE HEAD` and pass the reviewer the file path
  it prints (or, without bash: `git log --oneline`, `git diff --stat`,
  and `git diff -U10` for the range, redirected to one uniquely named
  file). The output never enters your own context, and the reviewer sees
  the commit list, stat summary, and full diff with context in one Read
  call. Use the BASE you recorded before dispatching the implementer —
  never `HEAD~1`, which silently truncates multi-commit tasks.
- A dispatch prompt describes one task, not the session's history. Do not
  paste accumulated prior-task summaries ("state after Tasks 1-3") into
  later dispatches — a real session's dispatch hit 42k chars of which 99%
  was pasted history. A fresh subagent needs its task, the interfaces it
  touches, and the global constraints. Nothing else.
- Dispatch fix subagents for Critical and Important findings. Record Minor
  findings in the progress ledger as you go, and point the final
  whole-branch review at that list so it can triage which must be fixed
  before merge. A roll-up nobody reads is a silent discard.
- A finding labeled plan-mandated — or any finding that conflicts with
  what the plan's text requires — is the human's decision, like any plan
  contradiction: present the finding and the plan text, ask which governs.
  Do not dismiss the finding because the plan mandates it, and do not
  dispatch a fix that contradicts the plan without asking.
- The final whole-branch review gets a package too: run
  `scripts/review-package MERGE_BASE HEAD` (MERGE_BASE = the commit the
  branch started from, e.g. `git merge-base main HEAD`) and include the
  printed path in the final review dispatch, so the final reviewer reads
  one file instead of re-deriving the branch diff with git commands.
- Every fix dispatch carries the implementer contract: the fix subagent
  re-runs the tests covering its change and reports the results. Name the
  covering test files in the dispatch — a one-line fix does not need the
  whole suite. Before re-dispatching the reviewer, confirm the fix report
  contains the covering tests, the command run, and the output; dispatch
  the re-review once all three are present.
- If the final whole-branch review returns findings, dispatch ONE fix
  subagent with the complete findings list — not one fixer per finding.
  Per-finding fixers each rebuild context and re-run suites; a real
  session's final-review fix wave cost more than all its tasks combined.

## File Handoffs

Everything you paste into a dispatch prompt — and everything a subagent
prints back — stays resident in your context for the rest of the session
and is re-read on every later turn. Hand artifacts over as files:

Set `SUPERPOWERS_RUN_ID=<workflow-id>` and `SUPERPOWERS_TASK_ID=<task>` on
every `task-brief` and `review-package` call so both helpers write into the
same run-scoped task directory.

- **Task brief:** before dispatching an implementer, run this skill's
  `scripts/task-brief PLAN_FILE N` — it extracts the task's full text to a
  uniquely named file and prints the path. Compose the dispatch so the
  brief stays the single source of requirements. Your dispatch should
  contain: (1) one line on where this task fits in the project; (2) the
  brief path, introduced as "read this first — it is your requirements,
  with the exact values to use verbatim"; (3) interfaces and decisions
  from earlier tasks that the brief cannot know; (4) your resolution of
  any ambiguity you noticed in the brief; (5) the report-file path and
  report contract. Exact values (numbers, magic strings, signatures, test
  cases) appear only in the brief.
- **Report file:** use `<run>/40-execution/tasks/<task>/report.md` from
  [task-report-template.md](templates/task-report-template.md) and put it in the
  dispatch prompt. The implementer writes the full report there and
  returns only status, files changed, a one-line test summary, and concerns.
- **Reviewer inputs:** the task reviewer gets three paths — the same brief
  file, the report file, and the review package — plus the global
  constraints that bind the task.
- Fix dispatches append their fix report (with test results) to the same
  report file and return a short summary; re-reviews read the updated file.

## Durable Progress

Conversation memory does not survive compaction. Append task checkpoints to `.superpowers/runs/<workflow-id>/subagent-driven-development-progress.jsonl` with task ID, status, decision/plan hashes, pre/post commit SHAs, report/review paths, verdicts, and detail.

Git history and the current worktree are authoritative. On start/resume, derive tasks from the current approved plan and accept a `done` checkpoint only when its workflow/hashes match, its commit is reachable from `HEAD`, its report/review evidence belongs to the same run, and D14 plus any D15 verdicts are clean. On disagreement, resume at the earliest unverified task; never trust or create another `manifest.json`. If approved decisions or plan hashes changed, revalidate every completed task before dispatching new work. `git clean -fdx` may remove ignored evidence, so reconstruct checkpoints from Git and rerun missing reviews.

## Token-cost Monitoring

Use `.superpowers/runs/<workflow-id>/subagent-driven-development-token-cost.jsonl` for SDD-owned work. After every provider call for D13, D16, and D18, append and validate one worker record, retaining retries, revisions, fallbacks, blocked results, and resumed calls:

```json
{"source":"worker","task":"D13","plan_task":"task-1","turn":1,"attempt":1,"agent":"codex","model":"<exact-model>","input_tokens":123,"output_tokens":45,"unavailable_reason":null}
```

Within each dispatch number and plan task, `turn` identifies one request envelope/decision-plan snapshot; revisions use the next turn. `attempt` increments for every provider retry or fallback on that envelope and continues after resume.

After each harness-reported SDD main-orchestrator invocation becomes observable, append and validate one orchestrator record before the next SDD action:

```json
{"source":"orchestrator","task":"orchestrator","turn":1,"attempt":1,"agent":"claude","model":"<exact-model>","input_tokens":456,"output_tokens":78,"unavailable_reason":null}
```

Copy exact per-invocation metadata. Use monotonic cumulative-counter deltas only; after a reset, record affected counts as `null` with the reason and retain the new baseline. Otherwise keep unavailable fields `null` with a reason. **Do not estimate missing token counts** or treat them as zero. Ordinary tools get no separate record.

Do not copy nested Requesting Code Review usage for D14, D15, or D17 into this file; that skill owns those worker and orchestrator invocations. Resume SDD metering when control returns. Before the finishing handoff, append its orchestrator record with both counts `null` and reason `usage becomes visible only after this turn completes`. Report worker, orchestrator, and combined measured totals, unavailable reasons, full-record coverage as measured records / total records, and independent input/output field coverage. Never call a partial subtotal complete.

## Final Handoff

Before finishing, reread the selected main-manifest entry, rehash the plan/design, and require every task checkpoint and the clean D17 result to match the current approved snapshot. Invoke `superpowers-orchestrator:finishing-a-development-branch` exactly once with the workspace key, workflow ID, decision-record path and snapshot, plan/design paths and hashes, progress file, final review evidence, and token-cost report. Any mismatch returns to the owning gate instead of finishing.

## Prompt Templates

- [implementer-prompt.md](prompts/implementer-prompt.md) - Dispatch implementer subagent
- [task-reviewer-prompt.md](prompts/task-reviewer-prompt.md) - Dispatch task reviewer subagent (spec compliance + code quality)
- Final whole-branch review: use superpowers-orchestrator:requesting-code-review's [code-reviewer.md](../requesting-code-review/prompts/code-reviewer.md)

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file once: docs/superpowers/plans/feature-plan.md]
[Create todos for all tasks]

Task 1: Hook installation script

[Run task-brief for Task 1; dispatch implementer with brief + report paths + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/superpowers/hooks/)"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it

[Orchestrator stages the validated Task 1 files and commits them]
[Run review-package, dispatch task reviewer with the printed path]
Task reviewer: Spec ✅ - all requirements met, nothing extra.
  Strengths: Good test coverage, clean. Issues: None. Task quality: Approved.

[Mark Task 1 complete]

Task 2: Recovery modes

[Run task-brief for Task 2; dispatch implementer with brief + report paths + context]

Implementer: [No questions, proceeds]
Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good

[Orchestrator stages the validated Task 2 files and commits them]
[Run review-package, dispatch task reviewer with the printed path]
Task reviewer: Spec ❌:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)
  Issues (Important): Magic number (100)

[Dispatch fix subagent with all findings]
Fixer: Removed --json flag, added progress reporting, extracted PROGRESS_INTERVAL constant

[Orchestrator stages and commits the validated fix]
[Regenerate review-package]
[Task reviewer reviews again]
Task reviewer: Spec ✅. Task quality: Approved.

[Mark Task 2 complete]

...

[After all tasks]
[Dispatch final code-reviewer]
Final reviewer: All requirements met, ready to merge

Done!
```

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**vs. Executing Plans:**
- Same session (no handoff)
- Continuous progress (no waiting)
- Review checkpoints automatic

**Efficiency gains:**
- Controller curates exactly what context is needed; bulk artifacts move
  as files, not pasted text
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)

**Quality gates:**
- Self-review catches issues before handoff
- Task review carries two verdicts: spec compliance and code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures implementation is well-built

**Cost:**
- More subagent invocations (implementer + reviewer per task)
- Controller does more prep work (extracting all tasks upfront)
- Review loops add iterations
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Start implementation on main/master branch without explicit user consent
- Let an implementation or fix worker commit or push; the orchestrator performs their Git bookkeeping
- Generate or regenerate a review package before committing successful D13/D16/D18 changes
- Skip task review, or accept a report missing either verdict (spec compliance AND task quality are both required)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make a subagent read the whole plan file (hand it its task brief —
  `scripts/task-brief` — instead)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (reviewer found spec issues = not done)
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace actual review (both are needed)
- Tell a reviewer what not to flag, or pre-rate a finding's severity in the
  dispatch prompt ("treat it as Minor at most") — the plan's example code is
  a starting point, not evidence that its weaknesses were chosen
- Dispatch a task reviewer without a diff file — generate it first
  (`scripts/review-package BASE HEAD`) and name the printed path in the
  prompt
- Move to next task while the review has open Critical/Important issues
- Re-dispatch a task the progress ledger already marks complete — check
  the ledger (and `git log`) after any compaction or resume

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If reviewer finds issues:**
- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Integration

**Required workflow skills:**
- **superpowers-orchestrator:using-git-worktrees** - Ensures the isolated workspace: verifies the current one, resumes the brainstorming-created one, or creates it when none exists; Step 0/0.5 prevent duplicate creation.
- **superpowers-orchestrator:writing-plans** - Creates the plan this skill executes
- **superpowers-orchestrator:requesting-code-review** - Code review template for the final whole-branch review
- **superpowers-orchestrator:finishing-a-development-branch** - Complete development after all tasks

**Subagents should use:**
- **superpowers-worker:test-driven-development** - Subagents follow TDD for each task

**Alternative workflow:**
- **superpowers-orchestrator:executing-plans** - Use only when the executing harness has no subagent capability
