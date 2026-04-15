# Testing Agent Instructions

This file extends `AGENTS.md` with instructions specific to **writing,
organizing, and maintaining tests** for Python projects. Read root `AGENTS.md`
first.

---

## Purpose

Testing agents design, implement, and maintain test suites that:

- Achieve and enforce 100% line and branch coverage
- Run fast (unit tests in < 1 second each; integration tests in < 30 seconds)
- Are readable, deterministic, and free of hidden inter-test dependencies
- Serve as living documentation of expected behavior

---

## Quick Reference: Test Commands

```bash
python3 -m pytest                              # run all tests
python3 -m pytest tests/unit/                 # unit tests only
python3 -m pytest tests/integration/          # integration tests only
python3 -m pytest -x                          # stop on first failure
python3 -m pytest -v                          # verbose (show test names)
python3 -m pytest -k "tax"                    # filter by name fragment
python3 -m pytest --cov=src --cov-report=term-missing   # coverage report
python3 -m pytest --cov=src --cov-fail-under=100        # enforce 100%
python3 -m pytest --tb=short                  # shorter traceback format
python3 -m pytest --durations=10              # show 10 slowest tests
```

---

## Test Taxonomy

| Layer | Location | Purpose | Speed |
|-------|----------|---------|-------|
| Unit | `tests/unit/` | Test pure functions in isolation; mock all I/O | < 100 ms |
| Integration | `tests/integration/` | Test real component interactions (DB, files) | < 30 s |
| End-to-end | `tests/e2e/` | Test full user-facing workflows | < 5 min |

Unit tests run on every commit. Integration tests run on every PR. E2E tests run
on merge to main.

---

## File and Naming Conventions

- Test files: `test_<module>.py` (e.g., `test_transform.py` for `transform.py`)
- Test functions: `test_<behavior>` (e.g., `test_calculate_tax_negative_income_raises`)
- Fixtures: nouns describing state (e.g., `sample_invoice`, `db_session`)
- Parametrize IDs: descriptive strings (e.g., `"zero_rate"`, `"max_rate"`)

---

## Fixture Patterns

```python
"""Shared fixtures for the test suite."""

from decimal import Decimal
from pathlib import Path

import pytest

from my_app.db.session import make_session_factory, get_session


@pytest.fixture(scope="session")
def db_factory(tmp_path_factory: pytest.TempPathFactory):
    """Session-scoped in-memory database factory."""
    db_path = tmp_path_factory.mktemp("db") / "test.db"
    return make_session_factory(f"sqlite:///{db_path}")


@pytest.fixture
def db_session(db_factory):
    """Function-scoped transactional session; rolls back after each test."""
    with get_session(db_factory) as session:
        yield session
        session.rollback()


@pytest.fixture
def sample_csv(tmp_path: Path) -> Path:
    """Write a minimal CSV to a temporary path."""
    p = tmp_path / "data.csv"
    p.write_text("id,name,value\n1,alpha,10\n2,beta,20\n", encoding="utf-8")
    return p
```

---

## Parametrize Pattern

```python
"""Data-driven tests with pytest.mark.parametrize."""

from decimal import Decimal

import pytest

from my_app.tax import calculate_tax


@pytest.mark.parametrize(
    "income,rate,expected",
    [
        pytest.param(Decimal("50000"), Decimal("0.22"), Decimal("11000.00"), id="standard_22pct"),
        pytest.param(Decimal("0"),     Decimal("0.22"), Decimal("0.00"),     id="zero_income"),
        pytest.param(Decimal("50000"), Decimal("0.00"), Decimal("0.00"),     id="zero_rate"),
    ],
)
def test_calculate_tax(income: Decimal, rate: Decimal, expected: Decimal) -> None:
    """Tax calculation should return correct amount for all rate/income pairs."""
    assert calculate_tax(income, rate) == expected


@pytest.mark.parametrize(
    "income,rate,match",
    [
        pytest.param(Decimal("-1"), Decimal("0.22"), "income must be non-negative", id="negative_income"),
        pytest.param(Decimal("50000"), Decimal("1.1"), "rate must be between 0 and 1", id="rate_above_one"),
    ],
)
def test_calculate_tax_raises(income: Decimal, rate: Decimal, match: str) -> None:
    """Invalid inputs should raise ValueError with a descriptive message."""
    with pytest.raises(ValueError, match=match):
        calculate_tax(income, rate)
```

---

## Mocking External Dependencies

```python
"""Mock patterns for isolating units under test."""

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from my_app.notifier import send_alert


def test_send_alert_calls_smtp(monkeypatch: pytest.MonkeyPatch) -> None:
    """send_alert should open an SMTP connection and send one message."""
    mock_smtp = MagicMock()
    monkeypatch.setattr("my_app.notifier.smtplib.SMTP", mock_smtp)

    send_alert(to="admin@example.com", subject="Test", body="Hello")

    mock_smtp.assert_called_once()
    instance = mock_smtp.return_value.__enter__.return_value
    instance.send_message.assert_called_once()


@patch("my_app.ingestion.httpx.Client")
def test_fetch_json_retries_on_timeout(mock_client_cls: MagicMock) -> None:
    """fetch_json should retry up to 5 times on TimeoutException."""
    import httpx
    mock_client = mock_client_cls.return_value.__enter__.return_value
    mock_client.get.side_effect = [
        httpx.TimeoutException("timeout"),
        httpx.TimeoutException("timeout"),
        MagicMock(json=lambda: {"ok": True}, raise_for_status=lambda: None),
    ]

    from my_app.ingestion import fetch_json
    result = fetch_json("https://example.com/api")
    assert result == {"ok": True}
    assert mock_client.get.call_count == 3
```

---

## Testing CLI Commands

```python
"""Tests for CLI entry points using Click's CliRunner."""

from pathlib import Path

import pytest
from click.testing import CliRunner

from my_app.cli import cli


@pytest.fixture
def runner() -> CliRunner:
    """Provide a Click test runner with isolated file system."""
    return CliRunner(mix_stderr=False)


def test_cli_help_exits_zero(runner: CliRunner) -> None:
    """--help should exit 0 and print usage."""
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "Usage:" in result.output


def test_process_command_success(runner: CliRunner, sample_csv: Path) -> None:
    """process command should succeed with a valid input file."""
    with runner.isolated_filesystem():
        result = runner.invoke(cli, ["process", str(sample_csv)])
        assert result.exit_code == 0, result.output
```

---

## Coverage Configuration (`pyproject.toml`)

```toml
[tool.coverage.run]
source = ["src"]
branch = true
omit = ["src/*/__main__.py"]

[tool.coverage.report]
show_missing = true
fail_under = 100
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
    "@(abc\\.)?abstractmethod",
]
```

---

## Test Quality Checklist

Before submitting tests for review:

- [ ] Every test has a one-line docstring stating what it asserts
- [ ] No test depends on execution order (each test is self-contained)
- [ ] No `time.sleep()` in tests — use monkeypatching or faketime
- [ ] No network calls in unit tests — mock all HTTP/database I/O
- [ ] Parametrize repeated similar assertions instead of duplicating tests
- [ ] Fixtures use the narrowest required scope (`function` > `class` > `module` > `session`)
- [ ] Temporary files use `tmp_path` fixture (never hard-coded paths)
- [ ] Coverage is 100% line and branch before marking PR ready

---

## What NOT to Test

| Avoid | Reason |
|-------|--------|
| Testing Python's built-in behavior | Not your code |
| Testing third-party library internals | Not your responsibility |
| Asserting that a mock was called with exact internal args | Tests implementation, not behavior |
| Tests that only pass if run in a specific order | Hidden coupling; a sign of design problems |

---

## See Also

- [`skills/python-testing.md`](../skills/python-testing.md) — detailed testing recipes
- [`skills/python-linting.md`](../skills/python-linting.md) — linting and coverage CI setup
- [`templates/pytest.ini`](../templates/pytest.ini) — pytest configuration template
