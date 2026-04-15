# RULES.md — Agent Compliance Rules

This file defines mandatory rules that **all agents** operating in this
repository (or any project that copies these templates) MUST follow. Rules are
non-negotiable unless explicitly overridden in writing by a human reviewer.

---

## Table of Contents

1. [Package Management](#1-package-management)
2. [Python Executable](#2-python-executable)
3. [Code Quality — Docstrings, Type Hints, and Comments](#3-code-quality--docstrings-type-hints-and-comments)
4. [Documentation — Keeping README Current](#4-documentation--keeping-readme-current)
5. [Third-Party Library Authorization](#5-third-party-library-authorization)
6. [Version Control and Commits](#6-version-control-and-commits)
7. [Testing and Coverage](#7-testing-and-coverage)
8. [Security and Secrets](#8-security-and-secrets)
9. [Error Handling](#9-error-handling)
10. [Logging and Observability](#10-logging-and-observability)
11. [Placeholder: Performance Standards](#placeholder-performance-standards)
12. [Placeholder: Accessibility and Internationalization](#placeholder-accessibility-and-internationalization)
13. [Placeholder: Data Privacy and Compliance](#placeholder-data-privacy-and-compliance)
14. [Placeholder: Deployment and Environment Parity](#placeholder-deployment-and-environment-parity)
15. [Placeholder: Code Review and Approval Workflow](#placeholder-code-review-and-approval-workflow)

---

## 1. Package Management

**Rule:** Always use `uv` as the Python package manager. Never use `pip`,
`pip3`, `conda`, `poetry`, or any other package manager.

### Mandatory commands

| Action | Command |
|--------|---------|
| Create virtual environment | `uv venv` |
| Add a runtime dependency | `uv add <package>` |
| Add a dev-only dependency | `uv add --dev <package>` |
| Remove a dependency | `uv remove <package>` |
| Install all dependencies | `uv sync` |
| Regenerate lock file | `uv lock` |
| Install project in editable mode | `uv pip install -e ".[dev]"` |

### Prohibited commands

```bash
# NEVER use these:
pip install <package>
pip3 install <package>
conda install <package>
poetry add <package>
```

### Rationale

`uv` provides deterministic installs via `uv.lock`, is significantly faster
than pip, and is the single source of truth for dependency management across
all projects in this repository.

---

## 2. Python Executable

**Rule:** Always invoke Python using `python3`. Never use `python` (which may
resolve to Python 2 on some systems) or a bare `py` alias.

### Correct usage

```bash
python3 -m pytest              # run tests
python3 -m <package_name>      # run package as module
python3 src/<entry>.py         # run script directly
python3 --version              # verify interpreter version
```

### Prohibited usage

```bash
# NEVER use these:
python script.py
py script.py
```

### Rationale

Using `python3` ensures the correct interpreter is always invoked, regardless
of system-level alias configuration. This prevents silent failures caused by
Python 2 being picked up from `$PATH`.

---

## 3. Code Quality — Docstrings, Type Hints, and Comments

**Rule:** Every public module, class, function, and method MUST include a
docstring, type hints on all parameters and return values, and inline comments
where the logic is non-obvious.

### Docstrings

Use Google-style docstrings for all public symbols:

```python
def parse_invoice(raw: str, currency: str = "USD") -> dict[str, float]:
    """Parse a raw invoice string into a structured line-item dict.

    Args:
        raw: The raw invoice text as received from the upstream source.
        currency: ISO 4217 currency code. Defaults to "USD".

    Returns:
        A mapping of line-item description to amount in the given currency.

    Raises:
        ValueError: If `raw` is empty or cannot be parsed.
        KeyError: If a required field is missing from the invoice.
    """
```

Rules:
- One-line summary on the first line, followed by a blank line if there are
  additional sections.
- Document every parameter (`Args:`), return value (`Returns:`), and exception
  that can propagate (`Raises:`).
- Private helpers (`_name`) should have at minimum a one-line docstring.

### Type hints

- Annotate every function/method signature, including `self`-less methods and
  standalone functions.
- Use `from __future__ import annotations` at the top of modules that reference
  forward-declared types.
- Prefer built-in generics (`list[str]`, `dict[str, int]`) over `typing.List`
  and `typing.Dict` (Python ≥ 3.9).
- Use `Optional[X]` only for clarity; prefer `X | None` in Python ≥ 3.10.

```python
# Good
def fetch_records(limit: int, offset: int = 0) -> list[dict[str, str]]:
    ...

# Bad — missing annotations
def fetch_records(limit, offset=0):
    ...
```

### Inline comments

- Add a comment above any block of logic that is not immediately obvious from
  reading the code (e.g., algorithmic tricks, regex patterns, bitwise ops).
- Do **not** add comments that merely restate what the code already says.

```python
# Good — explains the "why"
# Retry up to 3 times with exponential back-off to handle transient HTTP 429s.
for attempt in range(MAX_RETRIES):
    ...

# Bad — restates the "what"
# Add 1 to counter
counter += 1
```

### Enforcement

Run the following after every edit:

```bash
ruff format <file_path>        # auto-format
ruff check --fix <file_path>   # auto-fix lint issues
mypy src/                      # verify type correctness
```

---

## 4. Documentation — Keeping README Current

**Rule:** Whenever a code change affects public-facing behavior, adds or removes
a feature, changes a configuration option, or modifies the project's setup
steps, the `README.md` MUST be updated in the same commit or PR.

### What always requires a README update

- Adding or removing a CLI command, API endpoint, or major feature
- Changing setup, installation, or configuration instructions
- Modifying required environment variables or secrets
- Adding or removing a supported Python version
- Changing the project's public interface (imports, function signatures)

### What does NOT require a README update

- Pure refactors with no behavioral change
- Internal test additions or updates
- Dependency version bumps with no user-visible impact
- Fixing a bug whose behavior was never documented

### Process

1. Make your code change.
2. Ask: *"Does this change affect anything a user or operator of this project
   needs to know?"*
3. If yes, update the relevant section(s) of `README.md` before opening a PR.
4. If a new feature deserves its own section, add it under a descriptive heading.

---

## 5. Third-Party Library Authorization

**Rule:** Before adding any third-party library to a project, verify it is
listed in the project's **authorized library file**. If it is not listed,
**stop and request human approval** before proceeding.

### Authorized library file

The authorized library file is located at:

```
<project-root>/authorized_libraries.md   # preferred location
```

If no such file exists in the project, create one using the template below and
request human sign-off before populating it.

### Authorized libraries template

```markdown
# Authorized Third-Party Libraries

Last updated: YYYY-MM-DD
Approved by: <name or team>

| Library | Version constraint | Purpose | Approved by | Date |
|---------|--------------------|---------|-------------|------|
| requests | >=2.31,<3 | HTTP client | <name> | YYYY-MM-DD |
| pydantic | >=2.0,<3 | Data validation | <name> | YYYY-MM-DD |
```

### Process for adding a new library

1. Check `authorized_libraries.md` — if the library is already listed,
   proceed with `uv add <library>`.
2. If the library is **not** listed, create a proposal comment in the PR or
   issue that includes:
   - Library name and link to PyPI
   - Proposed version constraint
   - Purpose and justification
   - Any known security advisories (check via `pip-audit` or GitHub Advisory DB)
3. **Do not add the library to `pyproject.toml` until a human approver has
   explicitly approved the proposal.**
4. Once approved, add the library to `authorized_libraries.md` with the
   approver's name and date, then run `uv add <library>`.

### Security check (mandatory for new libraries)

Before requesting approval, run a vulnerability scan:

```bash
uv add --dev pip-audit
python3 -m pip_audit --requirement <(uv pip compile pyproject.toml)
```

Any HIGH or CRITICAL vulnerabilities must be resolved or explicitly accepted
before the library may be added.

---

## 6. Version Control and Commits

**Rule:** Every commit must be atomic, descriptive, and traceable to a task or
issue.

### Commit message format

Use the [Conventional Commits](https://www.conventionalcommits.org/) standard:

```
<type>(<scope>): <short imperative description>

[optional body]

[optional footer: BREAKING CHANGE, Closes #123, etc.]
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`,
`perf`, `ci`, `build`, `revert`.

### Rules

- Never bundle unrelated changes in a single commit.
- Never commit directly to `main` or `master` — always use a feature branch.
- Every PR must reference an issue (e.g., `Closes #42`).
- Merge commits are preferred over squash when the history is meaningful.

---

## 7. Testing and Coverage

**Rule:** All new code MUST be accompanied by tests. The minimum acceptable
coverage is **100%** for new modules; legacy modules must not decrease in
coverage.

### Required practices

- Test files named `test_<module>.py` in the `tests/` directory.
- Test functions named `test_<behavior_under_test>`.
- Use `pytest.fixture` for shared state; use `pytest.mark.parametrize` for
  data-driven cases.
- Mock all external I/O (network, filesystem, database) with `unittest.mock`
  or `pytest-mock`.
- Run the full suite before every PR:

```bash
python3 -m pytest --cov=src --cov-fail-under=100
```

### Prohibited practices

- Do NOT delete or comment out tests to make a build pass.
- Do NOT use `# noqa` or `# type: ignore` to suppress errors without a
  documented reason in the same line or adjacent comment.

---

## 8. Security and Secrets

**Rule:** No secret, credential, API key, token, or password may ever appear in
source code or be committed to the repository.

### Mandatory practices

- Load all secrets via environment variables using `python-dotenv` or
  `os.environ`.
- Add `.env` to `.gitignore` immediately when creating a new project.
- Use `parameterized queries` for all database interactions — never use string
  concatenation to build SQL.
- Validate and sanitize **all** external input before it reaches business logic.
- Run `git-secrets` or `trufflehog` as a pre-commit hook if available.

### If a secret is accidentally committed

1. Immediately rotate/revoke the exposed credential.
2. Use `git filter-branch` or `BFG Repo Cleaner` to scrub the history.
3. Force-push the cleaned history and notify affected parties.

---

## 9. Error Handling

**Rule:** Never use bare `except:` clauses. Always catch specific exceptions and
handle or re-raise them with context.

```python
# Good
try:
    result = risky_operation()
except ValueError as exc:
    logger.error("Invalid value in risky_operation: %s", exc)
    raise

# Bad
try:
    result = risky_operation()
except:          # catches KeyboardInterrupt, SystemExit, etc.
    pass
```

### Additional rules

- Use custom exception classes (subclasses of `Exception`) for domain-specific
  errors.
- Always log the exception before re-raising or swallowing it.
- Never silently swallow exceptions unless there is an explicit and documented
  reason.
- Propagate errors upward to a defined error boundary; do not let errors leak
  silently across layers.

---

## 10. Logging and Observability

**Rule:** Use the standard `logging` module (or `structlog` for services) for
all diagnostic output. Never use `print()` in library or service code.

```python
import logging

logger = logging.getLogger(__name__)

# Good
logger.info("Processing %d records", len(records))
logger.warning("Rate limit approaching: %d remaining", remaining)
logger.error("Failed to connect to %s: %s", host, exc)

# Bad
print(f"Processing {len(records)} records")
```

### Log level guidelines

| Level | When to use |
|-------|-------------|
| `DEBUG` | Detailed trace information for development |
| `INFO` | Normal operational events (start, stop, milestone) |
| `WARNING` | Something unexpected that is recoverable |
| `ERROR` | A failure that prevented an operation from completing |
| `CRITICAL` | A failure that requires immediate human attention |

---

## Placeholder: Performance Standards

> **TODO:** Define acceptable response-time and throughput thresholds for
> services, batch jobs, and CLI tools. Include profiling requirements and
> guidance on when to escalate a performance regression to a human reviewer.
>
> Suggested topics:
> - Maximum acceptable latency for API endpoints (e.g., p95 < 200 ms)
> - Batch job runtime budgets
> - Memory usage limits
> - When to use caching and which caching libraries are authorized
> - Profiling tools (`cProfile`, `py-spy`, `memray`)

---

## Placeholder: Accessibility and Internationalization

> **TODO:** Define rules for building accessible CLI and web interfaces,
> including internationalization (i18n) requirements for user-facing strings.
>
> Suggested topics:
> - Locale and timezone handling (`zoneinfo`, `babel`)
> - String externalization for i18n (`gettext` / `fluent`)
> - WCAG compliance requirements for web UIs
> - Accessibility testing tools

---

## Placeholder: Data Privacy and Compliance

> **TODO:** Define data handling rules for projects that process personal,
> financial, or legally sensitive data (PII, PHI, PCI, GDPR, CCPA).
>
> Suggested topics:
> - Data classification levels (public, internal, confidential, restricted)
> - Required anonymization or pseudonymization steps
> - Retention and deletion policies
> - Audit trail requirements
> - Applicable regulatory frameworks and how they map to code practices

---

## Placeholder: Deployment and Environment Parity

> **TODO:** Define rules that ensure development, staging, and production
> environments remain consistent.
>
> Suggested topics:
> - Required environment variables per deployment tier
> - Docker / container image conventions
> - CI/CD pipeline gates (must pass tests + lint + type-check before deploy)
> - Feature flag management
> - Blue/green or canary deployment patterns

---

## Placeholder: Code Review and Approval Workflow

> **TODO:** Define the human code review process that agents must trigger
> before merging any changes.
>
> Suggested topics:
> - Minimum number of human approvals required per PR
> - Automated checks that must pass before review is requested
> - Review checklist items (security, performance, test coverage)
> - Rules for handling reviewer disagreements
> - Escalation path for architectural decisions

---

*Last updated: 2026-04-15. Maintained by the repository owner. All agents must
re-read this file at the start of every session.*
