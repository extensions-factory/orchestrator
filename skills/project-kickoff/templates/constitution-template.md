# Project Constitution

> The canonical source for project-wide commands, standards, and quality gates.
> Tool-specific instruction files point here instead of repeating these rules.

## Project at a glance

- **Language/runtime:** <name and version>
- **Framework:** <name and version, or none>
- **Package manager:** <name and version>
- **Test runner:** <name>

## Required commands

| Task | Command | When to run |
|------|---------|-------------|
| Install | `<exact command>` | After checkout or dependency changes |
| Format | `<exact command>` | Before committing |
| Lint | `<exact command>` | Before committing |
| Test | `<exact command>` | Before committing and integration |
| Build | `<exact command>` | Before integration |

## Standards

- **Naming:** <project convention>
- **Formatting:** <project convention>
- **Test files:** <location and naming convention>
- **Commit convention:** <project convention>

## Quality gates

- <Observable condition required before integration, with its command or evidence.>

## Decision authority

| Decision | Owner | Escalate when |
|----------|-------|---------------|
| Product scope | <role or person> | <condition> |
| Architecture | <role or person> | <condition> |
| Release | <role or person> | <condition> |
