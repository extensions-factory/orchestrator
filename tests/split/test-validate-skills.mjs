import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const module = await import("../../scripts/validate-skills.mjs").catch(() => null);
assert.ok(module, "validator module must exist");

const root = mkdtempSync(join(tmpdir(), "validate-skills-"));
const skill = (name, content) => {
  const dir = join(root, name);
  mkdirSync(dir, { recursive: true });
  const file = join(dir, "SKILL.md");
  writeFileSync(file, content);
  return file;
};
const valid = (name, body = `# ${name}\n`) =>
  `---\nname: ${name}\ndescription: Use when testing the validator\n---\n\n${body}`;

try {
  const linked = skill("linked", valid("linked", "# Linked\n\n[Reference](reference.md)\n"));
  writeFileSync(join(root, "linked", "reference.md"), "reference");
  assert.deepEqual(module.validateSkill(linked), { errors: [], warnings: [] });

  const cases = [
    ["missing frontmatter", "# Missing\n", "frontmatter"],
    ["bad name", valid("Bad_Name"), "lowercase hyphenated"],
    ["bad description", valid("bad-description").replace("Use when", "Use for"), "Use when"],
    ["bad description boundary", valid("bad-description-boundary").replace("Use when", "Use whenever"), "Use when"],
    ...["I", "my", "you", "your"].map(pronoun => [
      `${pronoun}-person description`,
      valid(`${pronoun.toLowerCase()}-person`).replace("Use when testing the validator", `Use when ${pronoun} review a plan`),
      "third-person",
    ]),
    ["sentence workflow summary", valid("sentence-summary").replace("Use when testing the validator", "Use when a project starts. Validates the idea"), "workflow summary"],
    ["hyphen workflow summary", valid("hyphen-summary").replace("Use when testing the validator", "Use when implementation is complete - guides integration"), "workflow summary"],
    ["em-dash workflow summary", valid("em-dash-summary").replace("Use when testing the validator", "Use when feature work starts — ensures isolation"), "workflow summary"],
    ["canonical workflow summary", valid("canonical-summary").replace("Use when testing the validator", "Use when executing plans - dispatches subagent per task with code review between tasks"), "workflow summary"],
    ["missing H1", valid("missing-h1", "## Not an H1\n"), "H1"],
    ["fenced fake H1", valid("fenced-fake-h1", "```markdown\n# Not a document heading\n```\n"), "H1"],
    ["missing link", valid("missing-link", "# Missing link\n\n[Nope](missing.md)\n"), "does not resolve"],
    ["Windows path", valid("windows-path", "# Windows path\n\n[Nope](references\\guide.md)\n"), "Windows-style"],
    ["legacy invocation", valid("legacy-invocation", "# Legacy\n\nUse `superpowers:brainstorming` now.\n"), "legacy skill reference"],
  ];

  for (const [name, content, message] of cases) {
    const result = module.validateSkill(skill(name.replaceAll(" ", "-"), content));
    assert.ok(result.errors.some(error => error.includes(message)), `${name}: ${result.errors.join("; ")}`);
  }

  const oversized = module.validateSkill(skill(
    "oversized",
    valid("oversized", `# Oversized\n${Array(501).fill("word").join("\n")}\n`),
  ));
  assert.deepEqual(oversized.errors, []);
  assert.ok(oversized.warnings.some(warning => warning.includes("500 words")));
  assert.ok(oversized.warnings.some(warning => warning.includes("500 lines")));

  const longDescription = module.validateSkill(skill(
    "long-description",
    valid("long-description").replace(
      "Use when testing the validator",
      `Use when ${"a".repeat(501)}`,
    ),
  ));
  assert.ok(longDescription.warnings.some(warning => warning.includes("500 characters")));

  const longFrontmatter = module.validateSkill(skill(
    "long-frontmatter",
    valid("long-frontmatter").replace(
      "Use when testing the validator",
      `Use when ${"a".repeat(1024)}`,
    ),
  ));
  assert.ok(longFrontmatter.errors.some(error => error.includes("1024 characters")));

  const triggerList = valid("trigger-list").replace(
    "Use when testing the validator",
    "Use when features, components, guides, validators, or established behavior need review",
  );
  assert.deepEqual(module.validateSkill(skill("trigger-list", triggerList)), { errors: [], warnings: [] });
} finally {
  rmSync(root, { recursive: true, force: true });
}

console.log("PASS test-validate-skills");
