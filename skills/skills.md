# Skills Reference Index

This directory contains **agent reference documents**: pattern libraries, configuration
recipes, and code cookbooks. They are read on demand when an agent needs to know
*how* to implement something. They are not invokable commands.

> **Distinction from Claude Code skills:**
> Invokable slash commands live in `.claude/skills/<name>/SKILL.md`.
> Files in this directory are reference material, loaded by agents, not invoked by users.

---

## Reference Files

| File | Domain | When to load |
|------|--------|--------------|
| [`python-formatting.md`](python-formatting.md) | All | ruff format configuration and usage |
| [`pre-commit-hooks.md`](pre-commit-hooks.md) | All | pre-commit and commit-msg hook authoring, pygrep traps, install pitfalls |
| [`python-linting.md`](python-linting.md) | All | ruff lint rules and mypy configuration |
| [`python-testing.md`](python-testing.md) | All | pytest, coverage, fixtures, mocking cookbook |
| [`python-uv-workflow.md`](python-uv-workflow.md) | All | uv package manager complete reference |
| [`approved-packages.md`](approved-packages.md) | All | Authorized third-party library list |
| [`error-handling.md`](error-handling.md) | All | Exception handling patterns |
| [`logging-observability.md`](logging-observability.md) | All | structlog, logging levels, audit trails |
| [`configuration-management.md`](configuration-management.md) | All | Config file handling patterns |
| [`bundle-distribution.md`](bundle-distribution.md) | All | rsync include-lists, clean-slate pruning, openrsync delete-flag pitfalls, alias-shadows-function |
| [`github-issue-creation.md`](github-issue-creation.md) | All | GitHub issue authorization rules, `gh` commands, and stale-premise triage/closure pattern |
| [`secret-scanning.md`](secret-scanning.md) | All | Pre-commit hook setup, baseline management, credential rotation, incident remediation |
| [`multi-agent.md`](multi-agent.md) | All | Handoff payload schema, context passing, loop detection, logging |
| [`prompt-engineering.md`](prompt-engineering.md) | All | Prompt structure standards, injection defense, token efficiency |
| [`cost-management.md`](cost-management.md) | All | LLM token logging, session budget guards, pre-flight cost estimation |
| [`containerization.md`](containerization.md) | DevOps | Docker multi-stage builds, non-root user, .dockerignore, trivy scanning |
| [`infrastructure-operations.md`](infrastructure-operations.md) | DevOps | Feature flags, canary/blue-green validation, rollback procedure |
| [`cloud-cost-management.md`](cloud-cost-management.md) | DevOps | Resource tagging, budget alerts, right-sizing, cost-review checklist |
| [`cli-development.md`](cli-development.md) | CLI | argparse patterns, boundary validation, exit codes, NO_COLOR testing, terminal UI |
| [`web-development.md`](web-development.md) | Web | FastAPI, Flask, Django patterns |
| [`api-integration.md`](api-integration.md) | Data/Web | HTTP clients, retry, pagination |
| [`wikimedia-svg-sourcing.md`](wikimedia-svg-sourcing.md) | Data/Web | Downloading public-domain SVGs from Wikimedia Commons; MD5 URL computation; rate-limit handling |
| [`database-access.md`](database-access.md) | Data/Web | Query patterns, parameterized SQL |
| [`nlp-processing.md`](nlp-processing.md) | NLP | spaCy, Transformers, sklearn patterns |
| [`legal-fiscal-analysis.md`](legal-fiscal-analysis.md) | Legal/Fiscal | Decimal arithmetic, tax rules, audit trails |
| [`dashboarding-reporting.md`](dashboarding-reporting.md) | Dashboards | Matplotlib, Plotly, Dash, Excel patterns |
| [`process-modernization.md`](process-modernization.md) | Automation | ETL, data quality, change detection |
| [`STRATEGY.md`](../STRATEGY.md) | All | Multi-session phasing, skills caching, subagent decomposition |

---

## Invokable Claude Code Skills

These live in `.claude/skills/` and are called via `/skill-name`:

### Idea-to-implementation pipeline

Run these in order to take a raw idea through to automated implementation:

```
/ideate → /grill-me → /prd → /prd-to-issues → /ralph
```

| Step | Skill | Invocation | What it does |
|------|-------|-----------|--------------|
| 1 | ideate | `/ideate [idea]` | Surface risks, edge cases, and gaps before investing further |
| 2 | grill-me | `/grill-me [topic]` | Interview relentlessly until reaching shared design understanding |
| 3 | prd | `/prd [project-name]` | Synthesize conversation into a PRD + task JSON in `plans/` |
| 4 | prd-to-issues | `/prd-to-issues [prd-path]` | Convert PRD to GitHub issues (preview before create) |
| 5 | ralph | `/ralph --prd plans/<project>-prd.json` | Invoke ralph.sh PRD loop to work through tasks; also accepts issue numbers or `--all` |

### Utility skills

| Skill | Invocation | What it does |
|-------|-----------|--------------|
| orient | `/orient [task]` | Bootstrap context: reads AGENTS.md, RULES.md, subagent registry, skills index, and surveys repo structure |
| format | `/format [path]` | `ruff format` + `ruff check --fix` |
| test | `/test [flags]` | `pytest --cov=src --cov-fail-under=100` |
| project-review | `/project-review [perspective]` | Structured multi-lens project audit |
| stress-test | `/stress-test [topic]` | Stress-test a design, code, or proposal with hard questions |
| write-a-skill | `/write-a-skill [name]` | Scaffold a new slash command skill with correct frontmatter and repo conventions |
| caveman | `/caveman` | Ultra-compressed responses (~75% fewer tokens) |
| pr | `/pr` | Commit, push, and open a PR; enforces RULES.md §6 and §18 |

Command-file invocables (`.claude/commands/`, not `.claude/skills/`):

| Command | Invocation | What it does |
|---------|-----------|--------------|
| epilogue | `/epilogue` | Session shutdown protocol, capture session, refresh AGENTS.md, update CHANGELOG, commit, push, closure report |
| skills-sync | `/skills-sync` | Scan sibling projects' AGENTS/skills/ dirs and merge new files/sections into this repo |
| debt-scan | `/debt-scan` | Scan for technical debt patterns and prioritize remediation |
| dissect | `/dissect [path]` | Deep structural review of a file or module |
| migrate-draft | `/migrate-draft` | Draft a database migration with rollback plan |
| preflight | `/preflight` | Pre-commit scan for debug artifacts and code smells |
| rebuild | `/rebuild` | Rebuild working context after `/clear` |
| refactor-safe | `/refactor-safe` | Refactor internals without changing public API |
| ship | `/ship` | Validate and generate PR description from current branch |
