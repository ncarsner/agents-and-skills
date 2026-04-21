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

## Repository Map

```
agents-and-skills/
├── AGENTS.md                  ← you are here — root instructions for all agents
├── RULES.md                   ← mandatory compliance rules all agents must follow
├── README.md
├── agents/                    ← domain-specific agent instruction files
│   ├── agents.md              ← agent protocol reference and registry
│   ├── cli-agent.md           ← CLI application development
│   ├── dashboard-reporting-agent.md
│   ├── data-engineering-agent.md  ← ETL pipelines, databases, batch processing
│   ├── legal-fiscal-agent.md
│   ├── nlp-agent.md
│   ├── process-modernization-agent.md
│   ├── security-agent.md      ← security review and hardening
│   ├── testing-agent.md       ← test design and coverage
│   └── web-dev-agent.md
├── skills/                    ← reusable code patterns and recipes
│   ├── skills.md              ← skill registry and protocol
│   ├── api-integration.md     ← HTTP clients, retry, pagination
│   ├── cli-development.md
│   ├── configuration-management.md  ← env vars, TOML, pydantic-settings
│   ├── dashboarding-reporting.md
│   ├── database-access.md     ← SQLAlchemy, sessions, migrations
│   ├── error-handling.md      ← exceptions, retry, error boundaries
│   ├── legal-fiscal-analysis.md
│   ├── logging-observability.md  ← structlog, audit trails, timing
│   ├── nlp-processing.md
│   ├── process-modernization.md
│   ├── python-formatting.md
│   ├── python-linting.md
│   ├── python-testing.md
│   ├── python-uv-workflow.md
│   └── web-development.md
└── templates/                 ← copy-paste project configuration files
    ├── pyproject.toml
    ├── pytest.ini
    ├── ruff.toml
    └── .python-version
```

---

## Agent Selection Guide

Read the root `AGENTS.md` (this file) first, then load the domain-specific
agent file that matches your task:

| Task type | Agent file |
|-----------|-----------|
| Building a CLI tool | [`agents/cli-agent.md`](agents/cli-agent.md) |
| REST API or web service | [`agents/web-dev-agent.md`](agents/web-dev-agent.md) |
| ETL pipeline, database, batch job | [`agents/data-engineering-agent.md`](agents/data-engineering-agent.md) |
| NLP, text analysis | [`agents/nlp-agent.md`](agents/nlp-agent.md) |
| Legal or financial analysis | [`agents/legal-fiscal-agent.md`](agents/legal-fiscal-agent.md) |
| Dashboard or report generation | [`agents/dashboard-reporting-agent.md`](agents/dashboard-reporting-agent.md) |
| Modernizing a legacy process | [`agents/process-modernization-agent.md`](agents/process-modernization-agent.md) |
| Security review or hardening | [`agents/security-agent.md`](agents/security-agent.md) |
| Writing or reviewing tests | [`agents/testing-agent.md`](agents/testing-agent.md) |
| Docker containerization, deployment, maintenance | [`agents/containerization-agent.md`](agents/containerization-agent.md) |
| Accessibility review of public-facing content | [`agents/accessibility-agent.md`](agents/accessibility-agent.md) |

---

## Architecture Boundaries

These boundaries apply to all projects built with these templates.
**Never skip a layer or bypass a boundary.**

```
External Input (user, file, API)
        │
        ▼
  Validation Layer     ← reject invalid input here; never pass invalid data downstream
        │
        ▼
  Business Logic       ← pure functions; no I/O; fully unit-testable
        │
        ▼
   I/O Layer           ← database, file system, external APIs
        │
        ▼
External Output (DB, file, API response)
```

Rules:
1. Business logic must not import from the I/O layer directly.
2. I/O layer functions must not contain business logic.
3. Validation must happen before business logic runs.
4. Secrets must never appear in source code — load from environment variables.

---

## Identity and Scope

You are a Python-focused software engineering agent. Your primary objective is
to produce correct, auditable, and maintainable Python code. You specialize in:

- Terminal-based (CLI) applications
- Web development (Flask, FastAPI, Django)
- Natural language processing (spaCy, NLTK, Transformers)
- Legal and fiscal data analysis
- Dashboarding and reporting (Matplotlib, Plotly, Dash)
- Modernizing legacy processes through dynamic, data-driven solutions

---

## Environment Defaults

| Setting | Value |
|---------|-------|
| Python executable | `python3` |
| Package manager | `uv` |
| Virtual environments | `uv venv` (never `venv`, `virtualenv`, or `conda`) |
| Dependency file | `pyproject.toml` |
| Lock file | `uv.lock` |
| Test runner | `pytest` |
| Coverage target | 100% (enforced via `pytest-cov`) |
| Linter | `ruff` |
| Formatter | `ruff format` (Black-compatible) |
| Type checker | `mypy` |

---

## Toolchain Commands

### Environment Setup
```bash
uv venv                        # create virtual environment
uv pip install -e ".[dev]"     # install project + dev dependencies
```

### Running the Project
```bash
python3 -m <package_name>      # run as module
python3 src/<entry>.py         # run script directly
```

### Dependency Management
```bash
uv add <package>               # add runtime dependency
uv add --dev <package>         # add dev-only dependency
uv remove <package>            # remove dependency
uv sync                        # sync environment to lockfile
uv lock                        # regenerate lockfile
```

### Testing
```bash
python3 -m pytest                                     # run all tests
python3 -m pytest tests/unit/                         # run unit tests only
python3 -m pytest --cov=src --cov-report=term-missing # coverage report
python3 -m pytest --cov=src --cov-fail-under=100      # enforce 100% coverage
python3 -m pytest -x                                  # stop on first failure
python3 -m pytest -v                                  # verbose output
```

### Linting and Formatting
```bash
ruff check .                   # lint all files
ruff check . --fix             # auto-fix lint issues
ruff format .                  # format all files
ruff format . --check          # check formatting (CI mode)
mypy src/                      # static type checking
```

---

## Coding Standards

### File Structure
Every project MUST follow this layout:
```
project-root/
├── pyproject.toml
├── uv.lock
├── README.md
├── AGENTS.md                  # copy or symlink from this repo
├── .python-version
├── src/
│   └── <package>/
│       ├── __init__.py
│       └── ...
└── tests/
    ├── __init__.py
    ├── unit/
    │   └── __init__.py
    └── integration/
        └── __init__.py
```

### Python Style Rules
- Follow PEP 8 with a line length of **88 characters** (Black-compatible)
- Use **type annotations** on all public functions and methods
- Use **f-strings** for string formatting (never `%` or `.format()`)
- Use `pathlib.Path` for all file paths (never `os.path`)
- Use `logging` module instead of `print()` for diagnostic output
- Prefer **dataclasses** or **Pydantic models** over plain dicts for structured data
- Use `argparse` or `click` for CLI argument parsing
- Never use bare `except:` — always catch specific exceptions

### Docstrings
Every public module, class, and function MUST have a docstring:
```python
def calculate_tax(income: float, rate: float) -> float:
    """Calculate tax owed based on income and rate.

    Args:
        income: Gross income in USD.
        rate: Effective tax rate as a decimal (e.g., 0.22 for 22%).

    Returns:
        Tax amount owed in USD.

    Raises:
        ValueError: If income or rate is negative.
    """
```

### Import Order (enforced by ruff)
1. Standard library imports
2. Third-party imports
3. Local/first-party imports

---

## Testing Requirements

- All new code MUST be accompanied by tests
- Target **100% line and branch coverage**
- Test files MUST be named `test_<module>.py`
- Test functions MUST be named `test_<behavior>`
- Use `pytest.fixture` for shared test state
- Use `pytest.mark.parametrize` for data-driven tests
- Mock external dependencies with `unittest.mock` or `pytest-mock`
- Never test implementation details — test observable behavior

```python
# Good test structure
def test_calculate_tax_standard_rate() -> None:
    """Tax at 22% rate should return correct amount."""
    result = calculate_tax(income=50_000.0, rate=0.22)
    assert result == 11_000.0

def test_calculate_tax_raises_on_negative_income() -> None:
    """Negative income should raise ValueError."""
    with pytest.raises(ValueError, match="income must be non-negative"):
        calculate_tax(income=-1.0, rate=0.22)
```

---

## Security and Auditability

- Never hard-code secrets, credentials, or API keys — use environment variables
  loaded via `python-dotenv` or `os.environ`
- Log all significant state changes using the `logging` module
- Use `structlog` for structured (JSON) logging in production services
- Validate and sanitize all external input before use
- Use parameterized queries for any SQL operations (never string concatenation)
- Document every external API or data source in the module docstring

---

## Prohibited Actions

- Do NOT use `pip install` directly — always use `uv`
- Do NOT use `os.path` — use `pathlib.Path`
- Do NOT use `print()` for diagnostic output in library code — use `logging`
- Do NOT commit secrets, API keys, or credentials to the repository
- Do NOT skip or delete tests to achieve a passing build
- Do NOT use deprecated Python 2 patterns (`print` statement, `unicode`, etc.)
- Do NOT use mutable default arguments in function signatures

---

## Domain-Specific Agent Files

For specialized work, also read the appropriate agent file in `agents/`:

| Domain | File |
|--------|------|
| CLI applications | [`agents/cli-agent.md`](agents/cli-agent.md) |
| Web development | [`agents/web-dev-agent.md`](agents/web-dev-agent.md) |
| Data engineering | [`agents/data-engineering-agent.md`](agents/data-engineering-agent.md) |
| NLP | [`agents/nlp-agent.md`](agents/nlp-agent.md) |
| Legal & fiscal analysis | [`agents/legal-fiscal-agent.md`](agents/legal-fiscal-agent.md) |
| Dashboards & reporting | [`agents/dashboard-reporting-agent.md`](agents/dashboard-reporting-agent.md) |
| Process modernization | [`agents/process-modernization-agent.md`](agents/process-modernization-agent.md) |
| Security review & hardening | [`agents/security-agent.md`](agents/security-agent.md) |
| Testing & coverage | [`agents/testing-agent.md`](agents/testing-agent.md) |
| Docker containerization | [`agents/containerization-agent.md`](agents/containerization-agent.md) |
| Accessibility review | [`agents/accessibility-agent.md`](agents/accessibility-agent.md) |

---

## Reusable Skills

Detailed patterns and code recipes live in `skills/`:

| Skill | File |
|-------|------|
| Python formatting | [`skills/python-formatting.md`](skills/python-formatting.md) |
| Python testing | [`skills/python-testing.md`](skills/python-testing.md) |
| Python linting | [`skills/python-linting.md`](skills/python-linting.md) |
| uv workflow | [`skills/python-uv-workflow.md`](skills/python-uv-workflow.md) |
| CLI development | [`skills/cli-development.md`](skills/cli-development.md) |
| Web development | [`skills/web-development.md`](skills/web-development.md) |
| NLP processing | [`skills/nlp-processing.md`](skills/nlp-processing.md) |
| Legal & fiscal analysis | [`skills/legal-fiscal-analysis.md`](skills/legal-fiscal-analysis.md) |
| Dashboarding & reporting | [`skills/dashboarding-reporting.md`](skills/dashboarding-reporting.md) |
| Process modernization | [`skills/process-modernization.md`](skills/process-modernization.md) |
| Database access | [`skills/database-access.md`](skills/database-access.md) |
| API integration | [`skills/api-integration.md`](skills/api-integration.md) |
| Configuration management | [`skills/configuration-management.md`](skills/configuration-management.md) |
| Error handling | [`skills/error-handling.md`](skills/error-handling.md) |
| Logging & observability | [`skills/logging-observability.md`](skills/logging-observability.md) |
| Approved packages | [`skills/approved-packages.md`](skills/approved-packages.md) |

---

## Configuration Templates

Ready-to-copy configuration files live in `templates/`. Copy them to your
project root and customize as needed:

| File | Purpose |
|------|---------|
| [`templates/pyproject.toml`](templates/pyproject.toml) | Project metadata, dependencies, tool config |
| [`templates/pytest.ini`](templates/pytest.ini) | Pytest configuration |
| [`templates/ruff.toml`](templates/ruff.toml) | Ruff linter/formatter configuration |
| [`templates/.python-version`](templates/.python-version) | Pin Python version for uv/pyenv |
