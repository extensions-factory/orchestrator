import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repo = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const cli = spawnSync(process.execPath, [join(repo, "scripts/validate-skills.mjs"), join(repo, "skills")], { encoding: "utf8" });
assert.equal(cli.status, 0, cli.stderr);

console.log("PASS test-validate-skills-repository");
