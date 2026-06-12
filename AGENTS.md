# AGENTS.md — Root Agent Instructions

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
| Language profile + domain-specific profiles | [profiles/](profiles/) |
| Session shutdown protocol | [templates/epilogue.md](templates/epilogue.md) |
| 12-factor agents analysis + Karpathy wiki lens | [.12-FACTOR-AGENTS.md](.12-FACTOR-AGENTS.md) |

## Changelog

| Date | Change |
|------|--------|
| 2026-06-10 | Added Pipeline Discipline section to all three root context files. Added PIPELINE GATE blocks to `/ideate`, `/grill-me`, and `/prd` skills. Fixed `epilogue.md` §3 to discover context files from inside `AGENTS/` subdirectory. |
| 2026-06-01 | Added `RULES-BRIEF.md` reference; changed session-start compliance directive to load brief file, full RULES.md on demand only. |
| 2026-05-17 | Added `profiles/` resource reference. RULES.md refactored with scope markers; Python rules extracted to `profiles/python.md`; `epilogue.md` step numbering fixed. |
| 2026-05-14 | Added onboarding checklist reference to resource table. |
| 2026-05-14 | Initial version. |
