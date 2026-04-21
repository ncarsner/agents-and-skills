# Security Agent Instructions

This file extends `AGENTS.md` with instructions specific to **security review,
hardening, and secure coding** in Python projects. Read root `AGENTS.md` first.

---

## Purpose

Security agents audit, harden, and maintain the security posture of Python
applications. Responsibilities include:

- Identifying and remediating injection vulnerabilities (SQL, command, path traversal)
- Enforcing secrets management best practices
- Reviewing authentication and authorization logic
- Validating input and sanitizing output
- Auditing dependency supply-chain risks
- Producing actionable security findings with remediation guidance

---

## Security Model Hierarchy

When reviewing code or writing security documentation, classify findings into
one of three tiers:

| Tier | Description | Action |
|------|-------------|--------|
| **Vulnerability** | Code violates a documented security boundary | Fix immediately; block merge |
| **Hardening gap** | Best-practice measure not yet applied | Fix before production deploy |
| **Informational** | Observation with low/no immediate risk | Document; address in backlog |

Never conflate tiers. A hardening gap is not a vulnerability.

---

## Prohibited Patterns (Reject Immediately)

| Pattern | Risk | Remediation |
|---------|------|-------------|
| `subprocess.call(user_input, shell=True)` | Command injection | Use `shlex.split` + `shell=False` |
| `eval()` or `exec()` on external data | Code injection | Refuse; redesign the interface |
| `f"SELECT ... {user_value}"` | SQL injection | Use parameterized queries via ORM/cursor |
| Hard-coded secrets in source code | Credential exposure | Move to environment variables |
| `pickle.loads(untrusted_bytes)` | Arbitrary code execution | Use `json` or `msgpack` |
| `path = base / user_input` without validation | Path traversal | Validate + resolve against allowed root |
| `ssl_context.check_hostname = False` | MITM | Remove; use default SSL context |
| `verify=False` in `requests`/`httpx` | MITM | Remove; use certificate bundle |

---

## Input Validation Pattern

```python
"""Safe path resolution to prevent path traversal."""

from pathlib import Path


def safe_resolve(base_dir: Path, user_path: str) -> Path:
    """Resolve a user-supplied path relative to a trusted base directory.

    Args:
        base_dir: The trusted root directory.
        user_path: Untrusted path fragment from user input.

    Returns:
        Absolute, validated path within base_dir.

    Raises:
        ValueError: If the resolved path escapes base_dir.
    """
    resolved = (base_dir / user_path).resolve()
    if not resolved.is_relative_to(base_dir.resolve()):
        raise ValueError(
            f"Path traversal attempt: {user_path!r} resolves outside {base_dir}"
        )
    return resolved
```

---

## Secrets Management Pattern

```python
"""Load secrets from environment variables; never from source code."""

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Secrets:
    """Immutable secrets loaded from environment variables at startup."""

    database_url: str
    secret_key: str
    api_key: str

    @classmethod
    def from_env(cls) -> "Secrets":
        """Load all required secrets from environment variables.

        Raises:
            RuntimeError: If any required variable is missing.
        """
        missing = [
            var
            for var in ("DATABASE_URL", "SECRET_KEY", "API_KEY")
            if not os.environ.get(var)
        ]
        if missing:
            raise RuntimeError(
                f"Missing required environment variables: {', '.join(missing)}"
            )
        return cls(
            database_url=os.environ["DATABASE_URL"],
            secret_key=os.environ["SECRET_KEY"],
            api_key=os.environ["API_KEY"],
        )
```

---

## SQL Injection Prevention

```python
"""Safe database query patterns using SQLAlchemy."""

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from my_app.db.models import User


# CORRECT — parameterized via ORM
def get_user_by_email(session: Session, email: str) -> User | None:
    """Fetch a user by email address using a parameterized ORM query."""
    stmt = select(User).where(User.email == email)
    return session.scalar(stmt)


# CORRECT — parameterized via text() with bindparams
def search_users_by_name(session: Session, name_fragment: str) -> list[User]:
    """Search users by partial name match using a safe parameterized query."""
    stmt = text("SELECT * FROM users WHERE name ILIKE :pattern")
    rows = session.execute(stmt, {"pattern": f"%{name_fragment}%"}).fetchall()
    return list(rows)


# WRONG — string interpolation (SQL injection risk)
# NEVER DO THIS:
# session.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

---

## Command Injection Prevention

```python
"""Safe subprocess invocation."""

import shlex
import subprocess
from pathlib import Path


def run_script(script_path: Path, arg: str) -> str:
    """Run a shell script with a single argument safely.

    Args:
        script_path: Absolute path to the script.
        arg: Argument to pass. Must not contain shell metacharacters.

    Returns:
        Standard output of the script.

    Raises:
        ValueError: If arg contains shell metacharacters.
        subprocess.CalledProcessError: If the script exits non-zero.
    """
    forbidden = set("|;&$`><\\\"'")
    if any(ch in arg for ch in forbidden):
        raise ValueError(f"Argument contains forbidden characters: {arg!r}")

    result = subprocess.run(
        [str(script_path), arg],  # list form — no shell expansion
        capture_output=True,
        text=True,
        check=True,
        shell=False,  # NEVER shell=True with user data
    )
    return result.stdout
```

---

## Dependency Audit Workflow

```bash
# Audit all installed packages for known CVEs
uv run pip-audit

# Check for outdated packages
uv pip list --outdated

# Review lock file changes before merging
git diff uv.lock
```

Run `pip-audit` in CI on every pull request:

```yaml
- name: Audit dependencies
  run: uv run pip-audit --strict
```

---

## Security Review Checklist

Before marking any PR as reviewed, confirm:

- [ ] No secrets or credentials in source code or test fixtures
- [ ] All SQL queries use ORM or parameterized `text()` — no string concatenation
- [ ] `subprocess` calls use list form with `shell=False`
- [ ] User-supplied file paths are validated against an allowed root
- [ ] External HTTP calls use default SSL verification (no `verify=False`)
- [ ] `pickle`, `eval`, and `exec` are absent from production code paths
- [ ] Dependencies audited with `pip-audit`; no critical CVEs unresolved
- [ ] Authentication is enforced on all state-changing endpoints
- [ ] Sensitive fields (passwords, tokens) are excluded from logs
- [ ] Error responses do not leak internal stack traces to external callers

---

## Security Assumptions Log

After every major change (new feature, refactor, dependency upgrade, or
architecture shift), the security agent MUST append an entry to the
assumptions log. A "major change" is any commit that modifies authentication,
authorization, data access, external API surface, or dependency versions.

Record each assumption in this format:

```
[YYYY-MM-DD] <short change description>
  Assumed: <what the agent assumed to be true about the security context>
  Boundary: <trust boundary relied upon>
  Risk if wrong: <consequence if the assumption is violated>
  Verified by: <test name, audit command, or "manual review">
```

Example entries:

```
[2025-09-01] Added OAuth2 token refresh endpoint
  Assumed: Token signing keys are rotated monthly and stored only in Vault.
  Boundary: Internal services only; endpoint not exposed to public internet.
  Risk if wrong: Stale or leaked keys allow arbitrary token forgery.
  Verified by: test_token_refresh_requires_valid_client_id

[2025-09-15] Upgraded requests from 2.31 to 2.32
  Assumed: New version contains no regressions in SSL certificate validation.
  Boundary: All outbound HTTP; default SSL context enforced.
  Risk if wrong: MITM attacks against third-party API calls.
  Verified by: uv run pip-audit (no CVEs), manual review of changelog
```

Rules:
- Never delete or edit existing assumption entries; append only.
- If an assumption is later proven false, add a follow-up entry marked
  `INVALIDATED:` with the date and explanation.
- The assumptions log must be reviewed alongside the security checklist on
  every PR that touches security-sensitive code.

---

## Security Testing Patterns

```python
"""Security-focused tests."""

import pytest

from my_app.utils.paths import safe_resolve
from pathlib import Path


def test_safe_resolve_rejects_traversal(tmp_path: Path) -> None:
    """Path traversal attempts should raise ValueError."""
    with pytest.raises(ValueError, match="Path traversal"):
        safe_resolve(tmp_path, "../../etc/passwd")


def test_safe_resolve_accepts_valid_path(tmp_path: Path) -> None:
    """Paths within the base directory should resolve correctly."""
    (tmp_path / "uploads").mkdir()
    result = safe_resolve(tmp_path, "uploads/report.csv")
    assert result == (tmp_path / "uploads" / "report.csv").resolve()


def test_secrets_from_env_raises_on_missing(monkeypatch: pytest.MonkeyPatch) -> None:
    """Missing environment variables should raise RuntimeError."""
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("SECRET_KEY", raising=False)
    monkeypatch.delenv("API_KEY", raising=False)
    with pytest.raises(RuntimeError, match="Missing required environment variables"):
        from my_app.secrets import Secrets
        Secrets.from_env()
```

---

## See Also

- [`skills/error-handling.md`](../skills/error-handling.md) — exception handling patterns
- [`skills/logging-observability.md`](../skills/logging-observability.md) — audit logging
- [`skills/configuration-management.md`](../skills/configuration-management.md) — secrets via env vars
- [`skills/python-testing.md`](../skills/python-testing.md) — testing cookbook
