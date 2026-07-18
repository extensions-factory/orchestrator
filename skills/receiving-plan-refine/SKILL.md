---
name: receiving-plan-refine
description: Use when independent plan-review findings are ready to evaluate before execution
---

<!-- riso-tech:orchestrator-split — new skill, no upstream counterpart -->

# Receiving Plan Refine

## Overview

Evaluate plan-refine findings with the same rigor as code review feedback —
verify before implementing, push back on findings that don't hold up, fix
what does.

**Core principle:** Verify before implementing. Ask before assuming.
Technical correctness over blind acceptance.

**Announce at start:** "I'm using the receiving-plan-refine skill to
evaluate the refine findings."

<!-- riso-tech:orchestrator-split START -->
**Inline validation:** evaluating plan-refine findings is a VALIDATE-equivalent judgment call the orchestrator makes itself and is never dispatched.
<!-- riso-tech:orchestrator-split END -->

## The Process

1. **Read** the findings file (path handed off from `superpowers-orchestrator:requesting-plan-refine`).
2. **For each finding:**
   - Restate what it's claiming, in your own words
   - Verify against the plan, the spec (if any), and the codebase — a
     finding about a "missing task" might be wrong if the task exists under
     a different heading; a finding about a "layer-split US" might be wrong
     if the US is genuinely one feature
   - If it holds up: fix it directly in the plan file
   - If it doesn't: note why in your summary, don't apply it
3. **Regenerate the plan's HTML companion** (per `superpowers-orchestrator:writing-plans`) since the
   plan changed.
4. **Report and ask:**

> "Findings addressed in `<plan path>`: [N] fixed, [M] declined (with
> reasons). Continue refining, or move to executing?"

- **Refine again** → invoke `superpowers-orchestrator:requesting-plan-refine` for another
  pass.
- **Execute** → select the execution skill from harness capability:

- When the harness supports subagents: **REQUIRED SUB-SKILL:** Use
  superpowers-orchestrator:subagent-driven-development
- Only when the harness has no subagent capability: **REQUIRED SUB-SKILL:** Use
  superpowers-orchestrator:executing-plans

## Forbidden Responses

Same as `receiving-code-review`:

**NEVER:** "You're absolutely right!" / "Great point!" / apply a finding
without verifying it first.

## Red Flags

**Never:**
- Apply every finding without checking whether it's actually true of this
  plan
- Silently drop a finding without recording why it was declined
- Skip the continue-refining-or-execute question
- Forget to regenerate the plan's HTML companion after editing

## Integration

**Required workflow skills:**
- **superpowers-orchestrator:requesting-plan-refine** - Produces the findings file this
  skill consumes
- **superpowers-orchestrator:subagent-driven-development** / **superpowers-orchestrator:executing-plans**
  - Terminal execution skills this hands off to
