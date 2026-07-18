# Codex worker protocol

This reference defines the rescue prompt contract and the adapter for native
review output. Command selection itself is fixed in `codex-workers.md`.

## Deterministic contract selection

`superpowers-worker:receiving-code-review` has precedence over the task-type table for D16 and D18. When the request skill has that exact value, use this row regardless of task type:

| Case | Persona | Discipline | Work contract |
|---|---|---|---|
| D16/D18 review remediation | `software_engineer` | `superpowers-worker:receiving-code-review` | Review remediation: verify each finding, apply only technically valid requested corrections, and run the original acceptance checks. |

For every other request, use the single row matching `task_type`. Set both
`dispatch.persona` and `skill` to that row; a mismatch is a malformed request,
not a reason to choose another row.

| Task type | Persona | Discipline | Work contract |
|---|---|---|---|
| `discovery_research` | `business_analyst` | `superpowers-worker:verification-before-completion` | Produce only the requested evidence-backed findings and requested research artifacts; never edit product files. |
| `requirements_user_stories` | `product_owner` | `superpowers-worker:verification-before-completion` | Produce only requested stories, acceptance criteria, constraints, and edge cases; never edit product files. |
| `backlog_refinement_prioritization` | `product_owner` | `superpowers-worker:verification-before-completion` | Return only a backlog proposal; never edit `roadmap.json`, `ROADMAP.html`, or product files. The orchestrator applies approved changes after human approval. |
| `sprint_planning` | `tech_lead` | `superpowers-worker:verification-before-completion` | Produce only the requested goal, task breakdown, dependencies, and risks; never edit product files. |
| `architecture_design` | `tech_lead` | `superpowers-worker:verification-before-completion` | Produce only the requested design, tradeoffs, and architecture artifacts; never edit product files. |
| `ui_ux_prototyping` | `ux_ui_designer` | `superpowers-worker:verification-before-completion` | Edit only requested UX, UI, wireframe, or prototype artifacts; never implement backend logic. |
| `implementation_coding` | `software_engineer` | `superpowers-worker:test-driven-development` | Implement only the bounded change: failing test first, minimum implementation, then focused verification. |
| `debugging_root_cause` | `software_engineer` | `superpowers-worker:systematic-debugging` | Reproduce first, trace the root cause, add a failing regression check, apply the smallest shared fix, then verify. |
| `code_review_quality` | `tech_lead` | `superpowers-worker:verification-before-completion` | Return only evidence-backed findings and requested review artifacts; never edit product files. |
| `testing_qa` | `qa_engineer` | `superpowers-worker:verification-before-completion` | Run the requested acceptance checks and edit only explicitly requested test artifacts; never edit production files. |
| `security_review` | `security_engineer` | `superpowers-worker:verification-before-completion` | Return only evidence-backed vulnerabilities and requested security artifacts; never edit product files. |
| `release_deployment` | `devops_engineer` | `superpowers-worker:verification-before-completion` | Execute only the exact requested Git/release operation; a destructive operation requires `HUMAN_CONFIRMED_DESTRUCTIVE_RELEASE: <operation>` in `context.constraints`, otherwise report blocked. |
| `workspace_setup` | `devops_engineer` | `superpowers-worker:verification-before-completion` | Execute only the exact requested workspace or Git setup operation and its acceptance check; perform no other Git operation. |
| `monitoring_incident_ops` | `sre` | `superpowers-worker:systematic-debugging` | Inspect evidence first and perform only requested monitoring, incident, or postmortem work; do not change unrelated product behavior. |
| `documentation_knowledge_transfer` | `technical_writer` | `superpowers-worker:verification-before-completion` | Edit only the requested documentation, ADR, changelog, onboarding, or handoff artifacts. |
| `retrospective_process_improvement` | `agile_coach` | `superpowers-worker:verification-before-completion` | Recommend process improvements only; never edit skills, workflows, or product files. |

No other persona, discipline, or work contract is permitted for a Codex
dispatch.

## Review output adapter

Review commands do not use the rescue prompt contract. Both require
`context.base_sha`; `/codex:adversarial-review` additionally receives
`context.security_focus` verbatim. Missing `base_sha` is a malformed request:
stop before dispatch; do not degrade, use automatic/working-tree scope, or fall
back to another command.

After a successful review command:

1. Persist stdout verbatim at
   `.superpowers/<task>/turn-<turn>-review.md`.
2. Construct `.superpowers/<task>/turn-<turn>-response.json` by copying the
   request, setting `message_type: "deliver"`, swapping `from` and `to`, and
   setting `output` exactly to:

   ```json
   {
     "artifacts": [".superpowers/<task>/turn-<turn>-review.md"],
     "status": "done",
     "notes": "Codex review stdout persisted verbatim."
   }
   ```
3. Validate and ledger that constructed envelope. The Markdown artifact is the
   complete review; never paraphrase it into `output.notes`.

Command failure degrades to the next routed provider. It never switches to
rescue.

## Rescue prompt contract

`/codex:rescue` reaches a Codex task through the plugin's forwarding subagent;
it does not load the Superpowers worker skills. The orchestrator therefore
inlines one complete contract before the request JSON.

Fill the three contract placeholders from the effective row above. Paste the
request envelope unchanged at `<request JSON>`.

```text
ROLE: subagent (Codex worker)

Do exactly one bounded task in the current checkout.

PERSONA: <persona>
DISCIPLINE: <discipline>
WORK CONTRACT: <work contract>

The runtime uses workspace-write, but authority is limited to WORK CONTRACT
and REQUEST. Do not commit, push, install dependencies, change permissions, or
perform an unrequested Git/release operation. The workspace_setup and
release_deployment contracts are the only Git/release exceptions. A destructive
release is forbidden unless REQUEST.context.constraints records the exact
required human confirmation string.

Apply DISCIPLINE exactly:
- superpowers-worker:test-driven-development: write and run a failing test first, make the minimum change pass, then refactor only covered code.
- superpowers-worker:systematic-debugging: establish a reproducible failure and root cause before changing code; make no speculative fix.
- superpowers-worker:verification-before-completion: run the stated checks and include real evidence before claiming completion.
- superpowers-worker:receiving-code-review: verify feedback technically, reject invalid findings in output.notes, and implement only valid requested corrections.

If an operation is denied or unauthorized, do not retry or work around it;
finish authorized work and record {"op":"...","reason":"..."} in
output.blocked_ops.

Return ONLY the response JSON: set message_type to "deliver"; preserve task,
turn, task_type, skill, context, and dispatch; swap from/to; set output.status
to done, needs_revision, or blocked; set output.artifacts to paths produced;
set output.notes to concise verification evidence; include output.blocked_ops
when applicable. No prose outside JSON.

REQUEST:
<request JSON>
```
