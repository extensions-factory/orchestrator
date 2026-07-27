import { validateMessage } from "../../scripts/validate-message.mjs";
import assert from "node:assert/strict";

const good = {
  message_type: "request", from: "scrum_master", to: "software_engineer",
  run_id: "20260727T141500Z-test-workflow",
  phase: "execution", purpose: "implement",
  task: "test-task", turn: 1,
  task_type: "implementation_coding", skill: "test-driven-development",
  context: { input_artifacts: [], acceptance_criteria: [], constraints: [] },
  dispatch: { agent: "claude", model: "sonnet", effort: "medium", persona: "software_engineer", provider_diversity: null },
  output: { artifacts: [], status: "done", notes: "" }
};
assert.equal(validateMessage(good).ok, true, "well-formed message must validate");

const badStatus = structuredClone(good);
badStatus.output.status = "finished"; // not in enum
assert.equal(validateMessage(badStatus).ok, false, "bad status must fail");

const missingTop = structuredClone(good);
delete missingTop.task_type;
const r = validateMessage(missingTop);
assert.equal(r.ok, false, "missing top-level key must fail");
assert.ok(r.errors.some(e => e.includes("task_type")), "error names the missing key");

const badTask = structuredClone(good);
badTask.task = "Bad Task";
const badTaskResult = validateMessage(badTask);
assert.equal(badTaskResult.ok, false, "bad task slug must fail");
assert.ok(badTaskResult.errors.some(e => e.includes("task slug")), "error names the bad task slug");

const badTurn = structuredClone(good);
badTurn.turn = 0;
const badTurnResult = validateMessage(badTurn);
assert.equal(badTurnResult.ok, false, "bad turn must fail");
assert.ok(badTurnResult.errors.some(e => e.includes("turn")), "error names the bad turn");

const missingRun = structuredClone(good);
delete missingRun.run_id;
const missingRunResult = validateMessage(missingRun);
assert.equal(missingRunResult.ok, false, "missing run_id must fail");
assert.ok(missingRunResult.errors.some(e => e.includes("run_id")), "error names missing run_id");

const badPhase = structuredClone(good);
badPhase.phase = "coding";
assert.equal(validateMessage(badPhase).ok, false, "unknown lifecycle phase must fail");

const badPurpose = structuredClone(good);
badPurpose.purpose = "../review";
assert.equal(validateMessage(badPurpose).ok, false, "unsafe purpose slug must fail");

console.log("PASS test-validate-message");
