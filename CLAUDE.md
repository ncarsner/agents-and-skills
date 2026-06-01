# CLAUDE.md — Claude Agent Instructions

Python engineering agent. Comply with [RULES.md](RULES.md) before acting.

## Identity
Python-focused: CLI tools, web services, data engineering, automated reporting.
Stack: `uv` · `ruff` · `mypy` · `pytest` · 100% coverage target.

## Writing Style

- No em dashes (`—`) in any documentation, comments, or agent-generated text. Use commas, colons, or rewrite the sentence.
- No emojis unless the user explicitly requests them.

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

## On-demand resources (load only what the task requires)

| Need | File |
|------|------|
| Full compliance rules | [RULES.md](RULES.md) |
| Subagent registry + delegation protocol | [subagents/subagents.md](subagents/subagents.md) |
| Skill patterns and code recipes | [skills/skills.md](skills/skills.md) |
| Deterministic utility code | [tools/tools.md](tools/tools.md) |
| Slash commands | [.claude/commands/](.claude/commands/) |
| Session efficiency strategy | [STRATEGY.md](STRATEGY.md) |
| Language profile + domain-specific profiles | [profiles/](profiles/) |
| Session shutdown protocol | [templates/epilogue.md](templates/epilogue.md) |
| 12-factor agents analysis + Karpathy wiki lens | [.12-FACTOR-AGENTS.md](.12-FACTOR-AGENTS.md) |

## Subagent Delegation

Read [subagents/subagents.md](subagents/subagents.md) for the full delegation protocol.
Run `/orient [task]` at session start to load all context before acting.

### When to delegate

Delegate a subtask when it:
- Falls in a domain handled by a registered subagent (see §9 of subagents.md)
- Can run independently in parallel with other work
- Requires a distinct capability or isolated context window

### CLI agents — headless invocation

| Agent | Headless command | Best for |
|-------|-----------------|----------|
| Claude Code | `claude -p "<prompt>"` | Complex reasoning. Note: `-p` is boolean. |
| Gemini | `gemini -p "<prompt>"` | Large-context analysis. Note: `-p` requires a value. |
| Codex | `codex exec "<prompt>"` | Code synthesis, repo-scoped generation |

### Invocation rules

1. Pass a **self-contained prompt** — never assume the subagent has prior session context.
2. Include target file paths, relevant RULES.md constraints, and the expected output format.
3. Validate subagent output before using it downstream.
4. Subagents are workers, not authors — no git attribution from any subagent (RULES.md §6).
