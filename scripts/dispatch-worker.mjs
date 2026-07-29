#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
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
    if (typeof value.job?.status === "string") return value.job;
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
    const taskDir = dirname(resolve(values.request));
    const turnName = basename(taskDir).match(/^(\d{3})-[a-z0-9]+(?:-[a-z0-9]+)*$/);
    if (basename(values.request) !== "request.json" || !turnName)
      throw new Error("--request must be request.json inside NNN-purpose");
    const displayDir = dirname(values.request);
    const jobPath = join(taskDir, "job.txt");
    const responsePath = join(taskDir, "response.json");
    const rawPath = join(taskDir, "result-raw.txt");
    const displayResponse = join(displayDir, "response.json");
    const displayRaw = join(displayDir, "result-raw.txt");

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

    const state = statusFrom(runCompanion(companion, ["status", jobId, "--wait", "--timeout-ms", WAIT_TIMEOUT_MS, "--json"]));
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
    if (envelope) writeFileSync(responsePath, `${JSON.stringify(envelope, null, 2)}\n`);
    else if (!existsSync(responsePath)) {
      writeFileSync(rawPath, `${result}\n`);
      console.log(`TERMINAL malformed ${displayRaw}`);
      return;
    }
    console.log(`TERMINAL completed ${displayResponse}`);
  } catch (error) {
    console.log(`TERMINAL failed wrapper ${String(error.message ?? error).replace(/\s+/g, "-")}`);
  }
}

const invoked = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) main(process.argv.slice(2));
