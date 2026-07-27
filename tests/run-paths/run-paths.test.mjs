import assert from "node:assert/strict";
import {mkdtempSync, readFileSync, writeFileSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test from "node:test";

import {
  createRun,
  phasePath,
  setTaskStatus,
  taskPath,
  turnPath,
} from "../../scripts/run-paths.mjs";

const now = new Date("2026-07-27T14:15:00.000Z");

function root() {
  return mkdtempSync(join(tmpdir(), "superpowers-run-paths-"));
}

test("creates a traceable lifecycle skeleton", () => {
  const project = root();
  const run = createRun({root: project, topic: "Auth refresh", now});

  assert.equal(run.id, "20260727T141500Z-auth-refresh");
  assert.equal(run.path, join(project, ".superpowers/runs", run.id));
  assert.equal(readFileSync(join(project, ".superpowers/.gitignore"), "utf8"), "*\n");

  const manifest = JSON.parse(readFileSync(join(run.path, "manifest.json"), "utf8"));
  assert.equal(manifest.run_id, run.id);
  assert.equal(manifest.topic, "auth-refresh");
  assert.equal(manifest.status, "active");
  assert.deepEqual(
    manifest.phases.map(({name, directory}) => [name, directory]),
    [
      ["discovery", "10-discovery"],
      ["design", "20-design"],
      ["plan", "30-plan"],
      ["execution", "40-execution"],
      ["finish", "50-finish"],
      ["retrospective", "60-retrospective"],
    ],
  );
  assert.match(readFileSync(join(run.path, "README.md"), "utf8"), /# Workflow run: auth-refresh/);
  assert.equal(readFileSync(join(run.path, "ledger.jsonl"), "utf8"), "");
});

test("resolves phase, task, and semantic turn paths", () => {
  const project = root();
  const {id} = createRun({root: project, topic: "Auth refresh", now});

  assert.equal(
    phasePath({root: project, runId: id, phase: "execution"}),
    join(project, ".superpowers/runs", id, "40-execution"),
  );
  assert.equal(
    taskPath({root: project, runId: id, phase: "execution", task: "task-3-add-auth"}),
    join(project, ".superpowers/runs", id, "40-execution/tasks/task-3-add-auth"),
  );
  assert.equal(
    turnPath({
      root: project,
      runId: id,
      phase: "execution",
      task: "task-3-add-auth",
      turn: 2,
      purpose: "review",
    }),
    join(project, ".superpowers/runs", id, "40-execution/tasks/task-3-add-auth/turns/002-review"),
  );
});

test("isolates identical task slugs between runs", () => {
  const project = root();
  const first = createRun({root: project, topic: "First", now});
  const second = createRun({
    root: project,
    topic: "Second",
    now: new Date("2026-07-27T14:15:01.000Z"),
  });

  const args = {root: project, phase: "execution", task: "task-1-build", turn: 1, purpose: "implement"};
  assert.notEqual(turnPath({...args, runId: first.id}), turnPath({...args, runId: second.id}));
});

test("reinitialization preserves existing run artifacts", () => {
  const project = root();
  const first = createRun({root: project, topic: "Auth refresh", now});
  const marker = join(first.path, "40-execution", "marker.txt");
  writeFileSync(marker, "keep\n");

  const second = createRun({root: project, topic: "Auth refresh", now});
  assert.equal(second.id, first.id);
  assert.equal(readFileSync(marker, "utf8"), "keep\n");
});

test("records task progress idempotently in the manifest", () => {
  const project = root();
  const {id, path} = createRun({root: project, topic: "Auth refresh", now});

  setTaskStatus({
    root: project,
    runId: id,
    task: "task-1-build",
    status: "active",
    detail: "implementation dispatched",
  });
  setTaskStatus({
    root: project,
    runId: id,
    task: "task-1-build",
    status: "done",
    detail: "commits abc1234..def5678, review clean",
  });

  const {tasks} = JSON.parse(readFileSync(join(path, "manifest.json"), "utf8"));
  assert.deepEqual(tasks, [{
    task: "task-1-build",
    status: "done",
    detail: "commits abc1234..def5678, review clean",
  }]);
});

test("rejects malformed run and artifact identifiers", () => {
  const project = root();
  assert.throws(() => createRun({root: project, topic: "../escape", now}), /topic/);
  assert.throws(
    () => phasePath({root: project, runId: "../../escape", phase: "execution"}),
    /run ID/,
  );
  assert.throws(
    () => taskPath({root: project, runId: "20260727T141500Z-safe", phase: "unknown", task: "task-1"}),
    /phase/,
  );
  assert.throws(
    () => turnPath({
      root: project,
      runId: "20260727T141500Z-safe",
      phase: "execution",
      task: "../escape",
      turn: 0,
      purpose: "review",
    }),
    /task|turn/,
  );
});
