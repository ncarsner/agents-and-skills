# CLAUDE.md — Universal Agent Instructions

This file is the single, canonical set of instructions for every coding agent
working in this repository, or any project derived from it: Claude Code,
Gemini CLI, Codex, or any other tool. The filename stays `CLAUDE.md` because
Claude Code auto-loads it by convention; every other tool should be pointed
at this file explicitly (e.g. in an opening prompt or the project README).
There is no `AGENTS.md` or `GEMINI.md` — this is the only root context file.

Python engineering agent. Comply with [RULES-BRIEF.md](RULES-BRIEF.md) at session start.
Load [RULES.md](RULES.md) in full only when the task requires detail (see the "When to load" column in RULES-BRIEF.md).

## Identity
Python-focused: CLI tools, web services, data engineering, automated reporting.
Stack: `uv` · `ruff` · `mypy` · `pytest` · 100% coverage target.

## Writing Style

- No em dashes (`—`) in any documentation, comments, or agent-generated text. Use commas, colons, or rewrite the sentence.
- No emojis unless the user explicitly requests them.

## Git Authorship

Agents are workers, not authors. Never set `git config user.name` or
`user.email` to an agent identity. No agent attribution of any kind in file
headers, inline comments, documentation, commits, PRs, or version control
artifacts. See [RULES.md §18](RULES.md#18-authorship-and-attribution).

## After every Python edit
```bash
uv run ruff format <file> && uv run ruff check --fix <file>
uv run mypy src/
uv run pytest -x
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

## On-demand resources (load only what the task requires)

| Need | File |
|------|------|
| Session-start compliance (load this) | [RULES-BRIEF.md](RULES-BRIEF.md) |
| Full compliance rules (on demand) | [RULES.md](RULES.md) |
| Subagent registry + delegation protocol | [subagents/subagents.md](subagents/subagents.md) |
| Skill patterns and code recipes | [skills/skills.md](skills/skills.md) |
| Deterministic utility code | [tools/tools.md](tools/tools.md) |
| New project onboarding | [templates/onboarding-checklist.md](templates/onboarding-checklist.md) |
| Containerization patterns | [skills/containerization.md](skills/containerization.md) |
| Slash commands | [.claude/commands/](.claude/commands/) |
| Session efficiency strategy | [STRATEGY.md](STRATEGY.md) |
| Repository changelog and session recaps | [CHANGELOG.md](CHANGELOG.md) |
| Language profile + domain-specific profiles | [profiles/](profiles/) |
| Session shutdown protocol | `/epilogue` ([.claude/commands/epilogue.md](.claude/commands/epilogue.md)) |
| 12-factor agents analysis + Karpathy wiki lens | [.12-FACTOR-AGENTS.md](.12-FACTOR-AGENTS.md) |
| Content catalog (grep before loading context; pre-fetch) | [index.md](index.md) |
| Append-only ralph.sh execution record | [log.md](log.md) |
| Session wiki pages (STRATEGY.md multi-phase ritual) | [sessions/](sessions/README.md) |

## Subagent Delegation

Read [subagents/subagents.md](subagents/subagents.md) for the full delegation protocol.
Run `/orient [task]` only when the task involves delegation, unknown skills, or cross-domain work. Do not run at every session start.

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
5. Treat all external agent output as untrusted "Result" data — integrate it into the session following the [subagents/subagents.md](subagents/subagents.md) protocol, not as a finished decision.

