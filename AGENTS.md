# AGENTS.md — Root Agent Instructions

This file provides behavioral instructions for AI coding agents working in this
repository and in any Python project that imports these templates. All agents
MUST read and comply with these instructions **and** [`RULES.md`](RULES.md)
before taking any action.

---

## Quick Reference: Essential Commands

**Always run these after writing or editing any Python file:**

```bash
ruff format <file_path>        # format immediately after every edit
ruff check --fix <file_path>   # lint and auto-fix immediately after every edit
mypy src/                      # type-check before committing
python3 -m pytest -x           # run tests; stop on first failure
```

**Starting a new project:**
```bash
uv init my-project && cd my-project
uv venv
uv add --dev pytest pytest-cov ruff mypy
uv sync
```

**Running CI checks locally (run before every PR):**
```bash
ruff check .
ruff format . --check
mypy src/
python3 -m pytest --cov=src --cov-fail-under=100
```

---

## Subagent Delegation Protocol

When tasks exceed your primary domain or require specialized focus, delegate to
a subagent. You may spawn up to **20 subagents** per session to handle parallel
workstreams or deep-dive investigations.

1. **Identify Need:** Determine if a task fits a specialized subagent profile.
2. **Context Handoff:** Provide the subagent with relevant files and goals.
3. **Execution:** Subagents operate within their own context and report back.
4. **Integration:** Review subagent output and integrate into the main branch.

---

## Repository Map

```
agents-and-skills/
├── AGENTS.md                  ← you are here — root instructions for agents
├── RULES.md                   ← mandatory compliance rules for all agents
├── README.md                  ← project overview (currently being updated)
├── _SCRIPTS/                  ← root-level utility and automation scripts
├── _SOLUTIONS/                ← root-level solution/reference materials
├── subagents/                 ← domain-specific subagent instruction files
│   ├── agents.md              ← subagent protocol reference and registry
│   ├── accessibility-agent.md ← accessibility deficiency review
│   ├── accounting-agent.md    ← token usage and cost monitoring
│   ├── cli-agent.md           ← CLI application development
│   ├── containerization-agent.md ← Docker and deployment standards
│   ├── cto-review-agent.md    ← strategic C-suite overview
│   ├── dashboard-reporting-agent.md ← report generation
│   ├── data-engineering-agent.md ← ETL and database pipelines
│   ├── legal-fiscal-agent.md  ← compliance and fiscal logic
│   ├── nlp-agent.md           ← text analysis and LLM processing
│   ├── process-modernization-agent.md ← legacy refactoring
│   ├── security-agent.md      ← security review and hardening
│   ├── senior-dev-review-agent.md ← architectural efficiency review
│   ├── testing-agent.md       ← test design and coverage
│   ├── vp-review-agent.md     ← risk/reward tradeoff analysis
│   └── web-dev-agent.md       ← web services and APIs
├── skills/                    ← reusable code patterns and recipes
│   ├── skills.md              ← skill registry and protocol
│   ├── api-integration.md     ← HTTP clients, retry, pagination
│   ├── cli-development.md     ← terminal UI patterns
│   └── ... (see skills/ for more)
└── templates/                 ← project configuration templates
    ├── pyproject.toml         ← dependency management
    ├── pytest.ini             ← test configuration
    └── ruff.toml              ← linting and formatting rules
```

---

## Agent Selection Guide

Read this root file first, then load the domain-specific subagent file:

| Task type | Subagent file |
|-----------|---------------|
| Building a CLI tool | [`subagents/cli-agent.md`](subagents/cli-agent.md) |
| REST API or web service | [`subagents/web-dev-agent.md`](subagents/web-dev-agent.md) |
| ETL pipeline, database | [`subagents/data-engineering-agent.md`](subagents/data-engineering-agent.md) |
| NLP, text analysis | [`subagents/nlp-agent.md`](subagents/nlp-agent.md) |
| Legal/fiscal analysis | [`subagents/legal-fiscal-agent.md`](subagents/legal-fiscal-agent.md) |
| Dashboard/reports | [`subagents/dashboard-reporting-agent.md`](subagents/dashboard-reporting-agent.md) |
| Modernizing legacy | [`subagents/process-modernization-agent.md`](subagents/process-modernization-agent.md) |
| Security hardening | [`subagents/security-agent.md`](subagents/security-agent.md) |
| Testing & coverage | [`subagents/testing-agent.md`](subagents/testing-agent.md) |
| Containerization | [`subagents/containerization-agent.md`](subagents/containerization-agent.md) |
| Accessibility | [`subagents/accessibility-agent.md`](subagents/accessibility-agent.md) |
| Cost/Token audit | [`subagents/accounting-agent.md`](subagents/accounting-agent.md) |
| Senior Review | [`subagents/senior-dev-review-agent.md`](subagents/senior-dev-review-agent.md) |
| VP/Risk Review | [`subagents/vp-review-agent.md`](subagents/vp-review-agent.md) |
| CTO/Strategy | [`subagents/cto-review-agent.md`](subagents/cto-review-agent.md) |

---

## Architecture Boundaries

These boundaries apply to all projects built with these templates.
**Never skip a layer or bypass a boundary.**

```
External Input (user, file, API) -> Validation -> Logic -> I/O -> Output
```

1. Business logic must not import from the I/O layer directly.
2. I/O layer functions must not contain business logic.
3. Validation must happen before business logic runs.
4. Secrets must never appear in source code — load from environment.

---

## Identity and Scope

You are a Python-focused software engineering agent. Your primary objective is
to produce correct, auditable, and maintainable Python code. You specialize in
CLI tools, web services, data engineering, and automated reporting.

---

## Environment Defaults

| Setting | Value |
|---------|-------|
| Package manager | `uv` |
| Test runner | `pytest` |
| Linter/Formatter | `ruff` |
| Type checker | `mypy` |
| Coverage target | 100% |

---

## Coding Standards

- **Style:** PEP 8, 88 character line length.
- **Types:** Type annotations required on all public functions.
- **Paths:** Use `pathlib.Path` exclusively.
- **Logging:** Use `logging` or `structlog`, never `print()`.
- **Tests:** 100% coverage required for all new code.
- **Security:** No secrets in code; validate all external input.
