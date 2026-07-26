#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ACTIVE = new Set(["queued", "running"]);
const WAIT_TIMEOUT_MS = "570000";
const DEFAULT_MAX_WALL_MS = 60 * 60 * 1000;

function maxWallMs(values) {
  if (values["max-wall-ms"] === undefined) return DEFAULT_MAX_WALL_MS;
  const parsed = Number(values["max-wall-ms"]);
  if (!Number.isInteger(parsed) || parsed <= 0) throw new Error("--max-wall-ms must be a positive integer");
  return parsed;
}

function parseArgs(argv) {
  const values = {};
  for (let i = 0; i < argv.length; i += 2) {
    const flag = argv[i];
    if (!flag?.startsWith("--") || argv[i + 1] === undefined) throw new Error(`invalid argument: ${flag ?? ""}`);
    values[flag.slice(2)] = argv[i + 1];
  }
  for (const key of ["provider", "plugin-root", "request", "prompt", "model", "effort"])
    if (!values[key]) throw new Error(`missing --${key}`);
  if (!["codex", "antigravity"].includes(values.provider)) throw new Error(`unsupported provider ${values.provider}`);
  return values;
}

function runCompanion(companion, args) {
  const result = spawnSync(process.execPath, [companion, ...args], {encoding: "utf8"});
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error((result.stderr || result.stdout || `companion exit ${result.status}`).trim());
  return result.stdout.trim();
}

function jobIdFrom(stdout) {
  const match = stdout.match(/\btask-[A-Za-z0-9-]+\b/);
  if (!match) throw new Error("companion returned no job id");
  return match[0];
}

function statusFrom(stdout) {
  const start = stdout.indexOf("{");
  const end = stdout.lastIndexOf("}");
  if (start >= 0 && end > start) {
    const value = JSON.parse(stdout.slice(start, end + 1));
    if (typeof value.status === "string") return value;
  }
  const match = stdout.match(/\bstatus\s*[:=]\s*([A-Za-z0-9_-]+)/i);
  if (!match) throw new Error("companion returned no status");
  return {status: match[1]};
}

function responseEnvelope(stdout) {
  for (const match of stdout.matchAll(/```(?:json)?\s*([\s\S]*?)```/gi)) {
    try {
      const value = JSON.parse(match[1]);
      if (value && typeof value === "object" && !Array.isArray(value)) return value;
    } catch {}
  }
  try {
    const value = JSON.parse(stdout);
    if (value && typeof value === "object" && !Array.isArray(value)) return value;
  } catch {}
  return null;
}

function shellQuote(value) {
  return `'${String(value).replaceAll("'", `'\\''`)}'`;
}

function resumeLine(values, jobId) {
  const flags = [
    "--provider", values.provider,
    "--plugin-root", values["plugin-root"],
    "--request", values.request,
    "--prompt", values.prompt,
    "--model", values.model,
    "--effort", values.effort,
  ];
  if (values.profile) flags.push("--profile", values.profile);
  if (values["max-wall-ms"] !== undefined) flags.push("--max-wall-ms", values["max-wall-ms"]);
  return `RESUME node scripts/dispatch-worker.mjs --job ${shellQuote(jobId)} ${flags.map(shellQuote).join(" ")}`;
}

export function main(argv) {
  try {
    const values = parseArgs(argv);
    const companion = join(resolve(values["plugin-root"]), "scripts", `${values.provider}-companion.mjs`);
    const requestName = values.request.match(/turn-(\d+)-request\.json$/);
    if (!requestName) throw new Error("--request must end in turn-N-request.json");
    const turn = requestName[1];
    const taskDir = dirname(resolve(values.request));
    const displayDir = dirname(values.request);
    const jobPath = join(taskDir, `turn-${turn}-job.txt`);
    const responsePath = join(taskDir, `turn-${turn}-response.json`);
    const rawPath = join(taskDir, `turn-${turn}-result-raw.txt`);
    const displayResponse = join(displayDir, `turn-${turn}-response.json`);
    const displayRaw = join(displayDir, `turn-${turn}-result-raw.txt`);

    let jobId = values.job;
    if (jobId && !/^task-[A-Za-z0-9-]+$/.test(jobId)) throw new Error(`invalid --job ${jobId}`);
    if (!jobId) {
      const prompt = readFileSync(values.prompt, "utf8");
      const taskArgs = ["task", "--background", "--fresh", "--write", "--model", values.model, "--effort", values.effort];
      if (values.profile) taskArgs.push("--profile", values.profile);
      taskArgs.push(prompt);
      jobId = jobIdFrom(runCompanion(companion, taskArgs));
      writeFileSync(jobPath, `${jobId}\n`);
    }

    const state = statusFrom(runCompanion(companion, ["status", jobId, "--wait", "--timeout-ms", WAIT_TIMEOUT_MS]));
    if (ACTIVE.has(state.status)) {
      const createdAt = Date.parse(state.createdAt);
      if (!Number.isFinite(createdAt)) {
        console.log(`TERMINAL failed no-createdAt ${jobId}`);
        return;
      }
      if (Date.now() - createdAt >= maxWallMs(values)) {
        console.log(`TERMINAL failed timeout ${jobId}`);
        return;
      }
      console.log(`PENDING ${jobId}\n${resumeLine(values, jobId)}`);
      return;
    }
    if (state.status !== "completed") {
      console.log(`TERMINAL failed ${state.status} ${String(state.phase ?? "companion-status").replace(/\s+/g, "-")}`);
      return;
    }

    const result = runCompanion(companion, ["result", jobId]);
    const envelope = responseEnvelope(result);
    if (!envelope) {
      writeFileSync(rawPath, `${result}\n`);
      console.log(`TERMINAL malformed ${displayRaw}`);
      return;
    }
    writeFileSync(responsePath, `${JSON.stringify(envelope, null, 2)}\n`);
    console.log(`TERMINAL completed ${displayResponse}`);
  } catch (error) {
    console.log(`TERMINAL failed wrapper ${String(error.message ?? error).replace(/\s+/g, "-")}`);
  }
}

const invoked = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) main(process.argv.slice(2));
