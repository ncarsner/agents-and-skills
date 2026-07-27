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
| Language profile + domain-specific profiles | [profiles/](profiles/) |
| Session shutdown protocol | `/epilogue` ([.claude/commands/epilogue.md](.claude/commands/epilogue.md)) |
| 12-factor agents analysis + Karpathy wiki lens | [.12-FACTOR-AGENTS.md](.12-FACTOR-AGENTS.md) |

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

## Changelog

| Date | Change |
|------|--------|
| 2026-07-12 | `templates/epilogue.md` converted to `.claude/commands/epilogue.md` (invoked as `/epilogue`), since it's a frequently-invoked end-of-session action rather than a copy-once template. Original archived at `archive/epilogue-template-2026-07-12.md`. |
| 2026-07-12 | Root-doc consolidation completed. `AGENTS.md` and `GEMINI.md` deleted — `CLAUDE.md` is now the sole root context file, in this repo and in downstream copies (`RULES.md` §12 stub pattern). Unique content merged in first: the git-config authorship detail and headless-delegation integration note (from `GEMINI.md`), and the onboarding/containerization resource-table rows (from `AGENTS.md`). |
| 2026-06-10 | Added Pipeline Discipline section to all three root context files. Added PIPELINE GATE blocks to `/ideate`, `/grill-me`, and `/prd` skills. Fixed `epilogue.md` §3 to discover context files from inside `AGENTS/` subdirectory. |
| 2026-06-01 | Added `RULES-BRIEF.md` reference; changed session-start compliance directive to load brief file, full RULES.md on demand only. |
| 2026-05-17 | Added `profiles/` resource reference. RULES.md refactored with scope markers; Python rules extracted to `profiles/python.md`; `epilogue.md` step numbering fixed. |
| 2026-05-14 | Added onboarding checklist reference to resource table. |
| 2026-05-14 | Initial version. |
