---
name: write-a-skill
description: Scaffold a new Claude Code skill with proper frontmatter, progressive disclosure, and repo conventions. Use when the user wants to create, write, or add a new slash command skill to this repo.
disable-model-invocation: true
argument-hint: [skill-name or description]
allowed-tools: Read Write Bash
---

Scaffold a new skill for this repo. Skills live in `.claude/skills/<name>/SKILL.md`.

## Step 1: Gather requirements

Ask the user (one question at a time if unclear):
- What does the skill do, and what is the exact `/command` name?
- What triggers it? (keywords, file types, workflow stage)
- Which tools does it need? (`Read`, `Write`, `Bash`, `Grep`, or `Bash(<cmd> *)` for scoped commands)
- Does it need reference files or utility scripts, or is SKILL.md sufficient?

## Step 2: Draft SKILL.md

Use this frontmatter template:

```md
---
name: <skill-name>
description: <what it does>. Use when <specific triggers>.
disable-model-invocation: true
argument-hint: [<arg description>]
allowed-tools: <space-separated tool list>
---
```

Frontmatter rules:
- `description` ≤ 1024 chars; first sentence = capability, second = "Use when [triggers]"
- `disable-model-invocation: true` on all skills unless the skill explicitly needs a sub-model call
- `allowed-tools`: use `Bash(<pattern> *)` to scope shell access (e.g. `Bash(ruff *)`, `Bash(gh issue *)`)
- `argument-hint`: brief placeholder shown in autocomplete; omit if skill takes no arguments

Body rules:
- Keep SKILL.md under 100 lines
- Split into `REFERENCE.md` or `scripts/` if content exceeds that limit
- No time-sensitive information (dates, version numbers that will rot)
- Concrete steps > vague instructions
- Reference repo skills docs with relative paths (e.g. `[skills/python-testing.md](../../../../skills/python-testing.md)`)

## Step 3: Create the files

1. Write `.claude/skills/<name>/SKILL.md`
2. If reference material needed: write `.claude/skills/<name>/REFERENCE.md`
3. If deterministic scripts needed: write `.claude/skills/<name>/scripts/<helper>`

## Step 4: Register the skill

Add a row to the appropriate table in `skills/skills.md`:
- Pipeline skill → add to the pipeline table under the correct step
- Utility skill → add to the utility skills table

## Step 5: Review checklist

Verify before presenting to user:

- [ ] `name` matches the directory name exactly
- [ ] `description` includes "Use when [specific triggers]"
- [ ] SKILL.md is under 100 lines
- [ ] `allowed-tools` is scoped to what the skill actually needs
- [ ] `skills/skills.md` updated
- [ ] No hardcoded secrets, tokens, or absolute paths
