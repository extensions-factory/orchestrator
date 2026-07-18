import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export function validateSkill(file) {
  const source = readFileSync(file, "utf8");
  const errors = [];
  const warnings = [];
  const frontmatter = source.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);

  if (!frontmatter) {
    errors.push("missing YAML frontmatter");
  } else {
    if (frontmatter[0].length > 1024) errors.push("frontmatter exceeds 1024 characters");
    const field = key => frontmatter[1].match(new RegExp(`^${key}:\\s*(.+)$`, "m"))?.[1].trim().replace(/^(['"])(.*)\1$/, "$2");
    const name = field("name");
    const description = field("description");
    if (!name || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(name))
      errors.push("name must be lowercase hyphenated text");
    if (!/^Use when(?:\s|$)/.test(description ?? ""))
      errors.push('description must start exactly "Use when"');
    if (/\b(?:I|my|you|your)\b/i.test(description ?? ""))
      errors.push("description must be third-person");
    if (/(?:\.\s+|\s(?:-|—)\s+)(?:creates|dispatches|establishes|executes|guides|performs|routes|runs|validates|writes|ensures)\b/i.test(description ?? ""))
      errors.push("description contains a workflow summary");
    if ((description?.length ?? 0) > 500) warnings.push("description exceeds 500 characters");
  }

  const body = source.slice(frontmatter?.[0].length ?? 0);
  let fence = null;
  let hasH1 = false;
  for (const line of body.split(/\r?\n/)) {
    const marker = line.match(/^\s*(`{3,}|~{3,})/i)?.[1];
    if (marker) {
      if (!fence) fence = marker;
      else if (marker[0] === fence[0] && marker.length >= fence.length) fence = null;
      continue;
    }
    if (!fence && /^#\s+\S/.test(line)) { hasH1 = true; break; }
  }
  if (!hasH1) errors.push("missing H1 heading");

  for (const match of source.matchAll(/!?\[[^\]]*\]\(([^)]+)\)/g)) {
    let target = match[1].trim();
    target = target.startsWith("<") ? target.slice(1, target.indexOf(">")) : target.split(/\s+/)[0];
    if (target.includes("\\")) {
      errors.push(`Windows-style relative path: ${target}`);
      continue;
    }
    if (!target || target.startsWith("#") || isAbsolute(target) || /^[a-z][a-z\d+.-]*:/i.test(target)) continue;
    target = target.split(/[?#]/, 1)[0];
    if (target && !existsSync(resolve(dirname(file), decodeURIComponent(target))))
      errors.push(`relative link does not resolve: ${target}`);
  }

  for (const match of source.matchAll(/\bsuperpowers:[a-z][a-z0-9-]*\b/g))
    errors.push(`legacy skill reference: ${match[0]}`);

  if ((source.match(/\S+/g)?.length ?? 0) > 500) warnings.push("skill exceeds 500 words");
  if (source.split(/\r?\n/).length > 500) warnings.push("skill exceeds 500 lines");
  return { errors, warnings };
}

function skillFiles(target) {
  if (statSync(target).isFile()) return [target];
  return readdirSync(target, { withFileTypes: true })
    .filter(entry => entry.isDirectory() && existsSync(join(target, entry.name, "SKILL.md")))
    .map(entry => join(target, entry.name, "SKILL.md"));
}

if (fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  let failed = false;
  for (const file of skillFiles(resolve(process.argv[2] ?? "skills"))) {
    const { errors, warnings } = validateSkill(file);
    for (const warning of warnings) console.warn(`${file}: warning: ${warning}`);
    for (const error of errors) { console.error(`${file}: ${error}`); failed = true; }
  }
  process.exitCode = failed ? 1 : 0;
}
