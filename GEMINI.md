# GEMINI.md — Gemini Agent Instructions

Python engineering agent. Comply with [RULES-BRIEF.md](RULES-BRIEF.md) at session start.
Load [RULES.md](RULES.md) in full only when the task requires detail (see the "When to load" column in RULES-BRIEF.md).

## Identity
Python-focused: CLI tools, web services, data engineering, automated reporting.
Stack: `uv` · `ruff` · `mypy` · `pytest` · 100% coverage target.

## Git Authorship

Agents are workers, not authors. Never set `git config user.name` or
`user.email` to an agent identity. No agent attribution of any kind in commits,
PRs, or version control artifacts. See [RULES.md §6](RULES.md#6-version-control-and-commits).

## After every Python edit
```bash
ruff format <file> && ruff check --fix <file>
mypy src/
python3 -m pytest -x
```

## Pipeline Discipline

New work follows the pipeline in order:

```
/ideate → /grill-me → /prd → /prd-to-issues → /ralph
```

No file creation or code changes may occur before `/prd-to-issues` has run and
GitHub issues exist. `/ideate` output is analysis, not a task list. Each stage
boundary is a STOP requiring human invocation of the next command.

Scope check at session start: if `plans/*.json` exists with `done:false` tasks,
route to `/ralph`, not `/ideate`. If no `plans/*.json` exists and the task is a
new feature, begin at `/ideate`.

## Headless Agent Delegation

When a task is highly complex, requires specialized reasoning, or benefits from parallel execution, you may deploy external subagents in headless mode via CLI:

- **Claude (Headless):** Invoke as `claude -p "<prompt>" --allowedTools "Read,Edit,Bash"`. Note: `-p` is a boolean flag for "print and exit"; the prompt is a positional argument.
- **Gemini (Headless):** Invoke as `gemini -p "<prompt>"`. Note: `-p` requires the prompt as an immediate argument.
- **Codex (Headless):** Invoke as `codex exec "<prompt>"`. Use for surgical code generation, unit test creation, or deterministic translations.

All external agent output must be treated as "Result" data and integrated into the session following the [subagents/subagents.md](subagents/subagents.md) protocol.

## On-demand resources (load only what the task requires)

| Need | File |
|------|------|
| Session-start compliance (load this) | [RULES-BRIEF.md](RULES-BRIEF.md) |
| Full compliance rules (on demand) | [RULES.md](RULES.md) |
| Subagent registry + delegation protocol | [subagents/subagents.md](subagents/subagents.md) |
| Skill patterns and code recipes | [skills/skills.md](skills/skills.md) |
| Deterministic utility code | [tools/tools.md](tools/tools.md) |
| Language profile + domain-specific profiles | [profiles/](profiles/) |
| Session shutdown protocol | [templates/epilogue.md](templates/epilogue.md) |
