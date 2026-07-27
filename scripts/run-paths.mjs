import {mkdirSync, readFileSync, renameSync, writeFileSync} from "node:fs";
import {dirname, join, resolve} from "node:path";
import {fileURLToPath} from "node:url";

export const PHASES = Object.freeze({
  discovery: "10-discovery",
  design: "20-design",
  plan: "30-plan",
  execution: "40-execution",
  finish: "50-finish",
  retrospective: "60-retrospective",
});

const RUN_ID = /^\d{8}T\d{6}Z-[a-z0-9]+(?:-[a-z0-9]+)*$/;
const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const here = dirname(fileURLToPath(import.meta.url));

function slugTopic(topic) {
  if (typeof topic !== "string" || !/^[A-Za-z0-9 _-]+$/.test(topic.trim()))
    throw new Error("topic must contain only letters, numbers, spaces, underscores, and hyphens");
  const slug = topic.trim().toLowerCase().replace(/[ _]+/g, "-").replace(/-+/g, "-");
  if (!SLUG.test(slug)) throw new Error("topic does not produce a valid slug");
  return slug;
}

function valid(value, pattern, label) {
  if (typeof value !== "string" || !pattern.test(value)) throw new Error(`invalid ${label}: ${value}`);
  return value;
}

function rootPath(root) {
  if (typeof root !== "string" || root.trim() === "") throw new Error("root is required");
  return resolve(root);
}

function timestamp(date) {
  if (!(date instanceof Date) || Number.isNaN(date.valueOf())) throw new Error("now must be a valid Date");
  return date.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
}

export function runPath({root, runId}) {
  valid(runId, RUN_ID, "run ID");
  return join(rootPath(root), ".superpowers", "runs", runId);
}

export function phasePath({root, runId, phase}) {
  const directory = PHASES[phase];
  if (!directory) throw new Error(`invalid phase: ${phase}`);
  return join(runPath({root, runId}), directory);
}

export function taskPath({root, runId, phase, task}) {
  valid(task, SLUG, "task slug");
  const base = phasePath({root, runId, phase});
  return phase === "execution" ? join(base, "tasks", task) : join(base, task);
}

export function turnPath({root, runId, phase, task, turn, purpose}) {
  if (!Number.isInteger(turn) || turn < 1) throw new Error(`invalid turn: ${turn}`);
  valid(purpose, SLUG, "purpose slug");
  return join(taskPath({root, runId, phase, task}), "turns", `${String(turn).padStart(3, "0")}-${purpose}`);
}

export function setTaskStatus({root, runId, task, status, detail}) {
  valid(task, SLUG, "task slug");
  if (!["pending", "active", "done", "blocked"].includes(status))
    throw new Error(`invalid task status: ${status}`);
  if (typeof detail !== "string" || detail.trim() === "") throw new Error("task detail is required");

  const manifestPath = join(runPath({root, runId}), "manifest.json");
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  manifest.tasks ??= [];
  const next = {task, status, detail};
  const index = manifest.tasks.findIndex(item => item.task === task);
  if (index === -1) manifest.tasks.push(next);
  else manifest.tasks[index] = next;

  // ponytail: one orchestrator owns manifest writes; add a cross-process lock
  // only if parallel task-status updates become a supported workflow.
  const temporary = `${manifestPath}.${process.pid}.tmp`;
  writeFileSync(temporary, `${JSON.stringify(manifest, null, 2)}\n`);
  renameSync(temporary, manifestPath);
}

export function createRun({root, topic, now = new Date()}) {
  const topicSlug = slugTopic(topic);
  const id = `${timestamp(now)}-${topicSlug}`;
  const path = runPath({root, runId: id});
  const scratchRoot = join(rootPath(root), ".superpowers");
  const phases = Object.entries(PHASES).map(([name, directory]) => ({name, directory, status: "pending"}));

  mkdirSync(path, {recursive: true});
  try {
    readFileSync(join(scratchRoot, ".gitignore"));
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
    writeFileSync(join(scratchRoot, ".gitignore"), "*\n");
  }
  for (const {directory} of phases) mkdirSync(join(path, directory), {recursive: true});
  mkdirSync(join(path, PHASES.execution, "tasks"), {recursive: true});

  const manifestPath = join(path, "manifest.json");
  try {
    const existing = JSON.parse(readFileSync(manifestPath, "utf8"));
    if (existing.run_id !== id || existing.topic !== topicSlug)
      throw new Error(`existing manifest does not match run ${id}`);
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
    writeFileSync(manifestPath, `${JSON.stringify({
      schema: "assets/run-manifest.schema.json",
      run_id: id,
      topic: topicSlug,
      status: "active",
      created_at: now.toISOString(),
      phases,
      artifacts: [],
      tasks: [],
    }, null, 2)}\n`);
  }

  const indexTemplate = readFileSync(join(here, "../assets/run-index-template.md"), "utf8");
  const indexPath = join(path, "README.md");
  try {
    readFileSync(indexPath);
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
    writeFileSync(indexPath, indexTemplate
      .replaceAll("{{RUN_ID}}", id)
      .replaceAll("{{TOPIC}}", topicSlug)
      .replaceAll("{{CREATED_AT}}", now.toISOString()));
  }

  const ledgerPath = join(path, "ledger.jsonl");
  try {
    readFileSync(ledgerPath);
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
    writeFileSync(ledgerPath, "");
  }

  return {id, path};
}

function args(argv) {
  const [command, ...rest] = argv;
  const values = {};
  for (let i = 0; i < rest.length; i += 2) {
    if (!rest[i]?.startsWith("--") || rest[i + 1] === undefined) throw new Error(`invalid argument: ${rest[i] ?? ""}`);
    values[rest[i].slice(2)] = rest[i + 1];
  }
  return {command, values};
}

function cli(argv) {
  const {command, values} = args(argv);
  const common = {root: values.root, runId: values.run};
  if (command === "init") {
    const result = createRun({
      root: values.root,
      topic: values.topic,
      now: values.now ? new Date(values.now) : new Date(),
    });
    console.log(JSON.stringify(result));
    return;
  }
  if (command === "phase") console.log(phasePath({...common, phase: values.phase}));
  else if (command === "task") console.log(taskPath({...common, phase: values.phase, task: values.task}));
  else if (command === "turn") console.log(turnPath({
    ...common,
    phase: values.phase,
    task: values.task,
    turn: Number(values.turn),
    purpose: values.purpose,
  }));
  else if (command === "task-status") setTaskStatus({
    ...common,
    task: values.task,
    status: values.status,
    detail: values.detail,
  });
  else throw new Error("usage: run-paths.mjs <init|phase|task|turn|task-status> --root ...");
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    cli(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exit(2);
  }
}
