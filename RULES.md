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
11. [Architecture Boundaries](#11-architecture-boundaries)
12. [Local-Only Agent Directory](#12-local-only-agent-directory)
13. [AI Agent Compliance](#13-ai-agent-compliance)
14. [Performance Standards](#14-performance-standards)
15. [Accessibility and Internationalization](#15-accessibility-and-internationalization)
16. [Data Privacy and Compliance](#16-data-privacy-and-compliance)
17. [Deployment and Environment Parity](#17-deployment-and-environment-parity)
18. [Code Review and Approval Workflow](#18-code-review-and-approval-workflow)

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

### Authorship

**Agents are workers, not authors.** The git author identity must always reflect
the human who owns the work. Agents must never run `git config user.name` or
`git config user.email` to set an agent identity. No agent attribution of any
kind — including `Co-Authored-By:` trailers — may appear in commits, PRs, or
any version control artifact.

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
- Add `.env-template` that mimics `.env` with expected keys but includes no values. 
- Use `parameterized queries` for all database interactions — never use string
  concatenation to build SQL.
- Validate and sanitize **all** external input before it reaches business logic.
- Install `pre-commit` with `detect-secrets` on every new project before the first
  commit. Copy `templates/.pre-commit-config.yaml` to the project root and follow
  the setup steps in `skills/secret-scanning.md`. This is mandatory — not optional.

### If a secret is accidentally committed

This is a security incident. Follow the full remediation playbook in
`skills/secret-scanning.md`. Summary:

1. Immediately rotate/revoke the exposed credential — assume it is compromised.
2. Scrub the history using BFG Repo Cleaner (preferred over `git filter-branch`).
3. Force-push the cleaned history with human approval (see §6).
4. Notify all parties with a clone of the repository.
5. Audit access logs for use of the exposed credential.
6. Document the incident in the project's incident log or PR.

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

## 11. Architecture Boundaries

**Rule:** All code in this repository must respect the following layer boundaries.
Never skip a layer or bypass a boundary.

```
External Input (user, file, API) -> Validation -> Logic -> I/O -> Output
```

1. Business logic must not import from the I/O layer directly.
2. I/O layer functions must not contain business logic.
3. Validation must happen before business logic runs.
4. Secrets must never appear in source code — load from environment.

---

## 12. Local-Only Agent Directory

**Rule:** When copying this repository's agentic materials into another project,
place them in an `AGENTS/` directory and immediately add `AGENTS/` to that
project's `.gitignore`. The `AGENTS/` directory must remain untracked and must
never be committed to another repository. This repository is the master source.

---

## 13. AI Agent Compliance

**Rule:** All AI agents operating in this repository must observe the following
directives in addition to every other rule in this file.

### Identity and attribution

- Never set `git config user.name` or `user.email` to an agent identity.
- No `Co-Authored-By:` trailers or any agent attribution in commits, PRs, or
  any version-control artifact (see §6).

### Scope and escalation

- Validate task scope before acting; reject out-of-scope requests with a clear
  explanation.
- Escalate to a human for any ambiguous, potentially destructive, or irreversible
  action. Do not guess or proceed unilaterally.
- Take the least-privilege action necessary — never modify files outside declared
  scope without explicit human approval.

### Session startup

- Re-read `RULES.md` at the start of every session before acting.
- Run `/orient [task]` to load full context; do not skip this step.

### Decision-making and output

- Every non-trivial decision must include a brief rationale in the response.
- Never fabricate context, file paths, or behavior — request clarification instead.
- If a skill invocation fails, log the error and halt unless a fallback is defined.

---

## 14. Performance Standards

**Rule:** All agents must design for performance from the start. Performance
regressions introduced by an agent must be identified, documented, and resolved
before the PR is merged.

### Latency Targets

| Workload type | Target | Measurement |
|---------------|--------|-------------|
| Synchronous API endpoint | p95 < 200 ms | Load test at expected peak QPS |
| Background / async task | p95 < 2 s | End-to-end wall time |
| Batch ETL job (per 10 k rows) | < 60 s | Wall time on reference hardware |
| CLI command (interactive) | p95 < 500 ms | Cold-start wall time |

Targets may be adjusted in the project's `AGENTS.md` with a written rationale.
Exceeding a target by >2× requires escalation before shipping.

### Memory Limits

| Process type | Soft limit | Hard limit |
|--------------|-----------|-----------|
| API service (per worker) | 256 MB RSS | 512 MB RSS |
| CLI tool | 128 MB RSS | 256 MB RSS |
| Batch job | 1 GB RSS | 4 GB RSS |

Soft limit breach → log a `WARNING`. Hard limit breach → log `ERROR` and halt.

### Approved Profiling Tools

| Tool | Install | Best for |
|------|---------|---------|
| `cProfile` | stdlib | CPU-bound function hotspots |
| `memray` | `uv add --dev memray` | Memory allocation flamegraphs |

Run profiling before claiming a performance fix. Attach the flamegraph to the PR.

### Caching

Approved caching libraries:

| Library | Use case |
|---------|---------|
| `functools.lru_cache` / `functools.cache` | In-process memoization (stdlib) |
| `diskcache` | Persistent cross-process local cache |
| `redis-py` | Distributed cache / message broker |

Do not cache secrets, PII, or session tokens (§16). Cache TTLs must be explicit —
never cache indefinitely without a documented reason.

### Regression Escalation

A performance regression must be escalated to a human reviewer when:

- A measured p95 latency increases by >25% vs. the prior release.
- Memory usage increases by >50% vs. the prior release.
- A batch job runtime budget is exceeded by >2×.

Escalation means: open a GitHub issue tagged `perf`, block the PR, and notify
the project owner before merging.

---

## 15. Accessibility and Internationalization

**Rule:** Any web UI, CLI output, or document produced by an agent must meet
the accessibility and internationalization standards below. These apply when the
project serves end users — not to internal tooling or agent-only pipelines.

### Web UI — WCAG 2.1 AA Compliance

All agent-generated web interfaces must satisfy WCAG 2.1 Level AA:

| Criterion | Requirement |
|-----------|------------|
| Color contrast | Text/background ratio ≥ 4.5:1 (normal text), ≥ 3:1 (large text) |
| Keyboard navigation | All interactive elements reachable and operable via keyboard alone |
| Focus indicators | Visible focus ring on all focusable elements |
| Alt text | Every non-decorative image has a descriptive `alt` attribute |
| Form labels | Every input has an associated `<label>` or `aria-label` |
| Error messages | Errors identified in text — never by color alone |
| Heading structure | Headings used semantically (`h1`→`h2`→`h3`), not for styling |

Required accessibility testing before any web UI ships:

```bash
# axe-core CLI (install once)
npm install -g @axe-core/cli

# Run against a running local server
axe http://localhost:8000 --exit
```

Zero WCAG 2.1 AA violations allowed. Critical and serious violations block the
PR; moderate violations must be documented as known issues with a remediation
timeline.

### CLI — Color and Terminal Output

- Never use color as the sole means of conveying information (e.g., red = error,
  green = success must also include a text label).
- Test with `NO_COLOR=1` — all output must be fully readable in plain text.
- Minimum contrast for terminal color pairs: verify with the ANSI color contrast
  table in `skills/cli-development.md`.

### Internationalization (i18n)

**Locale and timezone:**

```python
from zoneinfo import ZoneInfo

# Always use explicit timezone — never datetime.now() without tz
from datetime import datetime
now = datetime.now(tz=ZoneInfo("UTC"))

# Format for display using babel (locale-aware)
from babel.dates import format_datetime
display = format_datetime(now, locale="en_US")
```

Approved i18n libraries:

| Library | Install | Use for |
|---------|---------|--------|
| `zoneinfo` | stdlib (3.9+) | Timezone-aware datetimes |
| `babel` | `uv add babel` | Locale-aware date, number, currency formatting |
| `gettext` | stdlib | String externalization for translated UIs |

**String externalization rules:**

- All user-visible strings in web UIs must be wrapped in `gettext` calls (`_("...")`).
- Source strings are English; translations live in `locale/<lang>/LC_MESSAGES/`.
- Do not concatenate translated strings — use format strings with named placeholders:
  ```python
  # Correct
  _("Found {count} records").format(count=n)
  # Wrong — breaks in languages with different word order
  _("Found") + f" {n} " + _("records")
  ```
- Dates, numbers, and currency must use `babel` formatters, never f-strings, when
  locale-aware output is required.

### Scope Exceptions

These rules apply only when the project:
- Serves end users via a web browser or terminal interface, **and**
- Targets a locale other than the deployment default (for i18n string rules).

Pure data pipelines, internal CLI tools, and agent-only scripts are exempt from
the WCAG and i18n string externalization requirements, but must still follow
the color/`NO_COLOR` rule for any terminal output.

---

## 16. Data Privacy and Compliance

**Rule:** All agents must handle personal and sensitive data according to the
classification level, applicable regulatory frameworks, and the practices defined
in this section. Non-compliance is a blocking defect.

### Data Classification Levels

| Level | Definition | Examples |
|-------|-----------|---------|
| **Public** | Intended for open publication | Documentation, marketing copy |
| **Internal** | Not for external disclosure; no special controls | Internal metrics, system logs |
| **Confidential** | Restricted access; limited retention | Business contracts, employee data |
| **Restricted** | Highest sensitivity; strict controls + audit trail | PII, PHI, credentials, payment data |

Agents must determine the classification level before writing any data handling
code. When in doubt, treat as **Restricted**.

### PII Detection and Handling

Use `subagents/data-collection-agent.md` `PII_PATTERNS` as the baseline field
name detection list. Additional detection rules:

- Scan all inbound column names and JSON keys against the PII pattern list before
  processing.
- Never log Restricted or Confidential data. Redact before logging:
  ```python
  log.info("Processing record", user_id="[REDACTED]")
  ```
- Mask PII in error messages, stack traces, and exception payloads.
- Do not write raw PII to intermediate files, temp dirs, or caches (§14).

### Anonymization Requirements

Before storing or transmitting Confidential/Restricted data downstream:

| Technique | When to apply |
|-----------|--------------|
| Pseudonymization (hash + salt) | User IDs in analytics pipelines |
| Tokenization | Payment card data |
| Aggregation / generalization | Statistical reporting |
| Suppression | Fields with <5 unique values in aggregate output |

Hashing must use SHA-256 with a per-project salt stored in an environment
variable (never hardcoded). See `tools/hashing-encoding.md`.

### Retention and Deletion

| Classification | Maximum retention | Deletion method |
|---------------|------------------|----------------|
| Public | Indefinite | N/A |
| Internal | 2 years | Standard delete |
| Confidential | 1 year | Secure delete + audit log |
| Restricted | 90 days (or legal minimum) | Secure delete + audit log + confirmation |

Agents must not retain Restricted data beyond the defined window. Implement a
deletion job; do not rely on manual cleanup.

### Audit Trail Requirements

Any operation that reads, transforms, exports, or deletes Restricted data must
emit a structured audit log entry containing:

```python
{
    "event": "data_access",          # or data_export | data_delete | data_transform
    "classification": "restricted",
    "actor": "<agent_id or user_id>",
    "timestamp": "<ISO-8601 UTC>",
    "record_count": <int>,
    "legal_basis": "<purpose>",      # e.g. "consent" | "contract" | "legal_obligation"
    "destination": "<system or path>"
}
```

Audit logs are **Internal** classification and must be retained for 2 years.

### Regulatory Frameworks

| Framework | Scope | Key agent obligations |
|-----------|-------|----------------------|
| **GDPR** | EU residents' personal data | Lawful basis required; data subject rights (access, deletion, portability); 72-hour breach notification |
| **CCPA** | California residents' personal data | Right to know, opt-out of sale, deletion on request |
| **HIPAA** | US protected health information (PHI) | PHI must be encrypted at rest and in transit; minimum necessary access; BAA required with third parties |

When a project processes data under any of these frameworks:

1. Document the applicable framework in the project's `AGENTS.md`.
2. Implement the audit trail (above) for all Restricted data operations.
3. Encrypt Restricted data at rest (AES-256) and in transit (TLS 1.2+).
4. Never pass Restricted data to an external LLM API without explicit written
   authorization from the data owner and legal review.

---

## 17. Deployment and Environment Parity

**Rule:** All deployed services must maintain parity between local development,
staging, and production. Differences must be limited to environment variable
values — never to code paths, installed packages, or dependency versions.

### Required Environment Variables per Tier

| Variable | Local | Staging | Production |
|----------|-------|---------|-----------|
| `APP_ENV` | `development` | `staging` | `production` |
| `LOG_LEVEL` | `DEBUG` | `INFO` | `WARNING` |
| `DATABASE_URL` | local connection string | staging DB URL | prod DB URL |
| `SECRET_KEY` | any local value | rotated secret | rotated secret |

All required variables must be defined in `.env-template`. Actual values are
never committed (RULES.md §8).

### Local Development Setup

Use Docker Compose for local multi-service development. See
`skills/containerization.md` for the canonical `docker-compose.yml` pattern.

```bash
docker compose up --build   # start all services
docker compose down         # tear down
```

### Mandatory CI/CD Gates

All of the following must pass before any deployment proceeds:

1. `pre-commit run --all-files` — secret scanning (§8)
2. `ruff check .` — no lint errors
3. `mypy src/` — no type errors
4. `python3 -m pytest --cov=src --cov-fail-under=100` — full test suite at 100%
5. `trivy image --exit-code 1 --severity HIGH,CRITICAL <image>:<tag>` — no critical CVEs

No deployment may proceed if any gate fails.

### Blue/Green Deployment Conventions

1. Build and push the new image tagged with the git SHA: `<image>:<sha>`.
2. Deploy to the green (inactive) environment.
3. Run smoke tests against green before switching traffic.
4. Switch the load balancer to green only when all smoke tests pass.
5. Keep blue (previous version) running for one hour as a rollback target.
6. Rollback trigger: 5xx error rate >1% sustained for 5 minutes → restore blue.

Agents must not trigger a cutover without human approval (RULES.md §18).

---

## 18. Code Review and Approval Workflow

**Rule:** All code changes must pass automated checks and receive human approval
before merging. Required approvals and the review checklist vary by PR type.

### PR Types and Minimum Approvals

| PR type | Definition | Required approvals |
|---------|-----------|-------------------|
| Hotfix | Critical bug fix; no new features | 1 human |
| Feature | New capability, skill file, or agent definition | 1 human |
| Architectural | Changes to RULES.md, AGENTS.md, subagents.md, or any file that governs agent behavior | 2 humans |
| Breaking | Removes or renames a public interface, agent, or skill | 2 humans |

### Automated Checks (must all pass before requesting review)

1. `pre-commit run --all-files` — secret scanning and hook suite (§8)
2. `ruff check .` — no lint errors
3. `mypy src/` — no type errors (where `src/` exists)
4. `python3 -m pytest --cov=src --cov-fail-under=100` — tests pass at 100% coverage

No review may be requested while any automated check is failing.

### Review Checklist

Reviewers must verify each item before approving:

- [ ] **Security** — No secrets or credentials in source. Pre-commit hooks are installed and passing.
- [ ] **Coverage** — Test coverage did not decrease. All new code has tests.
- [ ] **Type safety** — No new `# type: ignore` without a documented reason on the same line.
- [ ] **RULES.md compliance** — Change does not violate any enforced section (§§1–13).
- [ ] **Scope** — PR is atomic; unrelated changes are absent.
- [ ] **Documentation** — README updated if public-facing behavior changed (§4).
- [ ] **Dependencies** — Any new library is listed in `authorized_libraries.md` (§5).

### Handling Disagreements

1. The reviewer documents the objection as a PR comment citing a specific rule or rationale.
2. The author must respond to every blocking objection before re-requesting review.
3. If unresolved within one working day, escalate to the architectural review path.
4. The project owner's decision is final. Do not merge over an unresolved blocking objection.

### Escalation Path for Architectural Decisions

A decision is architectural if it:

- Changes the agent invocation protocol (`subagents/subagents.md` §§2–8)
- Adds, removes, or renames a registered agent or skill
- Modifies RULES.md §§1–13 (enforced sections)
- Changes the directory structure of `skills/`, `subagents/`, or `templates/`

Architectural decisions require:

1. An open GitHub issue documenting the proposed change and rationale.
2. At least two human approvals on the PR.
3. The project owner as one of the approvers.
4. A RULES.md changelog entry in the same commit.

---

*Draft rules under development: see [RULES-DRAFTS.md](RULES-DRAFTS.md).*

---

## Changelog

| Date | Change |
|------|--------|
| 2026-05-15 | §15: Accessibility and Internationalization filled — WCAG 2.1 AA criteria, axe-core testing, CLI NO_COLOR rule, babel/zoneinfo/gettext i18n standards, scope exceptions. |
| 2026-05-15 | §14: Performance Standards filled — latency targets, memory limits, approved profiling tools, caching libraries, regression escalation criteria. |
| 2026-05-15 | §16: Data Privacy and Compliance filled — classification levels, PII handling, anonymization, retention/deletion policy, audit trail schema, GDPR/CCPA/HIPAA obligations. |
| 2026-05-14 | §8: pre-commit hook requirement made mandatory; reference to `skills/secret-scanning.md` and `templates/.pre-commit-config.yaml` added. Remediation steps expanded. |
| 2026-05-14 | Initial version. Placeholder sections §14–§16 remain unfilled (see open GitHub issues). §17 and §18 filled. |

---

*Last updated: 2026-05-14. Maintained by the repository owner. All agents must
re-read this file at the start of every session.*
