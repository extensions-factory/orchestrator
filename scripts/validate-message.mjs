// ponytail: validates the schema subset this protocol uses; add a dependency
// only if the contract grows beyond required keys, enums, and patterns.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const schema = JSON.parse(readFileSync(join(here, "../assets/message-envelope.schema.json"), "utf8"));

export function validateMessage(msg) {
  const errors = [];
  for (const k of schema.required) if (!(k in msg)) errors.push(`missing top-level key: ${k}`);
  if (msg.message_type && !schema.properties.message_type.enum.includes(msg.message_type))
    errors.push(`invalid message_type: ${msg.message_type}`);
  for (const obj of ["context", "dispatch", "output"]) {
    const def = schema.properties[obj];
    if (msg[obj] == null) { errors.push(`missing object: ${obj}`); continue; }
    for (const k of def.required) if (!(k in msg[obj])) errors.push(`missing ${obj}.${k}`);
  }
  const status = msg.output?.status;
  if (status !== undefined && !schema.properties.output.properties.status.enum.includes(status)) errors.push(`invalid output.status: ${status}`);
  const agent = msg.dispatch?.agent;
  if (agent !== undefined && !schema.properties.dispatch.properties.agent.enum.includes(agent)) errors.push(`invalid dispatch.agent: ${agent}`);
  const effort = msg.dispatch?.effort;
  if (effort !== undefined && !schema.properties.dispatch.properties.effort.enum.includes(effort)) errors.push(`invalid dispatch.effort: ${effort}`);
  if (msg.run_id !== undefined && !new RegExp(schema.properties.run_id.pattern).test(msg.run_id))
    errors.push(`invalid run_id: ${msg.run_id}`);
  if (msg.phase !== undefined && !schema.properties.phase.enum.includes(msg.phase))
    errors.push(`invalid phase: ${msg.phase}`);
  if (msg.purpose !== undefined && !new RegExp(schema.properties.purpose.pattern).test(msg.purpose))
    errors.push(`invalid purpose slug: ${msg.purpose}`);
  if (msg.task !== undefined && !/^[a-z0-9][a-z0-9-]*$/.test(msg.task))
    errors.push(`invalid task slug: ${msg.task}`);
  if (msg.turn !== undefined && (!Number.isInteger(msg.turn) || msg.turn < 1))
    errors.push(`invalid turn (positive integer required): ${msg.turn}`);
  const blockedOps = msg.output?.blocked_ops;
  if (blockedOps !== undefined) {
    if (!Array.isArray(blockedOps)) errors.push("output.blocked_ops must be an array");
    else for (const [i, b] of blockedOps.entries())
      if (typeof b?.op !== "string" || typeof b?.reason !== "string")
        errors.push(`output.blocked_ops[${i}] must be {op, reason} strings`);
  }
  return { ok: errors.length === 0, errors };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const msg = JSON.parse(readFileSync(process.argv[2], "utf8"));
  const { ok, errors } = validateMessage(msg);
  if (!ok) { console.error(errors.join("\n")); process.exit(1); }
  console.log("valid");
}
