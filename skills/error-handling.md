# Skill: Error Handling

Patterns for robust, readable error handling in Python: custom exception
hierarchies, retry logic, fallback strategies, and error boundary patterns.

---

## Core Principles

1. **Be specific.** Catch the narrowest exception type that makes semantic sense.
   Never use bare `except:` or `except Exception:` unless you log and re-raise.
2. **Fail loudly.** An uncaught exception with a traceback is easier to diagnose
   than silent corruption or wrong output.
3. **Preserve context.** Use `raise NewError(...) from original_exc` to keep the
   original traceback.
4. **Don't swallow.** If you catch and suppress an error, log it first.

---

## Custom Exception Hierarchy

Define a project-level base exception and domain-specific subclasses.
This allows callers to catch broadly (`AppError`) or narrowly (`ValidationError`).

```python
"""Project exception hierarchy."""


class AppError(Exception):
    """Base class for all application-level errors.

    Prefer catching specific subclasses over this base class.
    """


class ConfigurationError(AppError):
    """Raised when the application cannot be configured correctly.

    Examples: missing required environment variable, invalid config file.
    """


class ValidationError(AppError):
    """Raised when input data fails schema or business rule validation."""

    def __init__(self, field: str, value: object, constraint: str) -> None:
        self.field = field
        self.value = value
        self.constraint = constraint
        super().__init__(f"Validation failed for '{field}': {constraint} (got {value!r})")


class NotFoundError(AppError):
    """Raised when a requested resource does not exist."""

    def __init__(self, resource_type: str, identifier: object) -> None:
        self.resource_type = resource_type
        self.identifier = identifier
        super().__init__(f"{resource_type} not found: {identifier!r}")


class ExternalServiceError(AppError):
    """Raised when a call to an external service fails after retries."""
```

---

## Exception Chaining

Always chain exceptions so the original context is preserved in tracebacks.

```python
"""Demonstrate exception chaining with 'raise ... from ...'."""

from pathlib import Path

from my_app.exceptions import AppError


def load_data(path: Path) -> list[dict]:
    """Load data from a CSV file, translating low-level errors.

    Args:
        path: Path to the CSV file.

    Returns:
        List of row dicts.

    Raises:
        AppError: If the file cannot be read, with original cause attached.
    """
    try:
        return _parse_csv(path)
    except FileNotFoundError as exc:
        raise AppError(f"Data file not found: {path}") from exc
    except PermissionError as exc:
        raise AppError(f"Cannot read data file (permission denied): {path}") from exc
    except UnicodeDecodeError as exc:
        raise AppError(f"Data file is not valid UTF-8: {path}") from exc
```

---

## Retry Pattern (Tenacity)

```python
"""Retry transient failures with exponential backoff."""

import logging

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
    before_sleep_log,
    after_log,
)

logger = logging.getLogger(__name__)

RETRYABLE_ERRORS = (httpx.TimeoutException, httpx.NetworkError, ConnectionError)


@retry(
    retry=retry_if_exception_type(RETRYABLE_ERRORS),
    wait=wait_exponential(multiplier=1, min=2, max=60),
    stop=stop_after_attempt(5),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    after=after_log(logger, logging.DEBUG),
    reraise=True,
)
def call_external_api(url: str) -> dict:
    """Call an external API with automatic retry on transient errors.

    Args:
        url: The endpoint URL.

    Returns:
        Parsed JSON response.

    Raises:
        httpx.HTTPStatusError: Non-retryable HTTP error (4xx/5xx).
        httpx.TimeoutException: All retry attempts exhausted.
    """
    with httpx.Client(timeout=10.0) as client:
        response = client.get(url)
        response.raise_for_status()
        return response.json()
```

---

## Result Type Pattern

For operations where failure is expected and not exceptional (e.g., validation),
return a typed result object instead of raising.

```python
"""Result type for operations with expected success/failure paths."""

from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E", bound=Exception)


@dataclass
class Ok(Generic[T]):
    """Successful result wrapping a value."""

    value: T

    @property
    def ok(self) -> bool:
        return True


@dataclass
class Err(Generic[E]):
    """Failed result wrapping an error."""

    error: E

    @property
    def ok(self) -> bool:
        return False


Result = Ok[T] | Err[Exception]


def parse_positive_int(text: str) -> Result:
    """Parse a string as a positive integer without raising.

    Returns:
        Ok[int] on success, Err[ValueError] on failure.

    Example::

        match parse_positive_int("42"):
            case Ok(value=n):
                print(f"Got {n}")
            case Err(error=e):
                print(f"Bad input: {e}")
    """
    try:
        n = int(text)
        if n <= 0:
            raise ValueError(f"Expected positive integer, got {n}")
        return Ok(n)
    except ValueError as exc:
        return Err(exc)
```

---

## Error Boundary Pattern (CLI / Service Entry Points)

Catch and categorize all errors at the outermost boundary to return meaningful
exit codes or HTTP status codes.

```python
"""CLI error boundary — translate exceptions to exit codes."""

import logging
import sys

from my_app.exceptions import AppError, ConfigurationError, ValidationError
from my_app.pipeline import run

logger = logging.getLogger(__name__)


def main() -> int:
    """Application entry point. Returns an exit code."""
    try:
        run()
        return 0
    except ConfigurationError as exc:
        logger.critical("Configuration error: %s", exc)
        return 78   # EX_CONFIG (sysexits.h)
    except ValidationError as exc:
        logger.error("Validation error in field '%s': %s", exc.field, exc)
        return 65   # EX_DATAERR
    except AppError as exc:
        logger.error("Application error: %s", exc)
        return 1
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
        return 130
    except Exception as exc:  # noqa: BLE001  # top-level boundary converts all unhandled exceptions to exit code
        logger.critical("Unexpected error: %s", exc, exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
```

---

## Testing Error Paths

```python
"""Tests for error handling paths."""

import pytest

from my_app.exceptions import NotFoundError, ValidationError


def test_validation_error_message_includes_field() -> None:
    """ValidationError message should identify the offending field."""
    exc = ValidationError(field="quantity", value=-5, constraint="must be > 0")
    assert "quantity" in str(exc)
    assert "-5" in str(exc)


def test_not_found_error_message_includes_identifier() -> None:
    """NotFoundError message should include the resource type and ID."""
    exc = NotFoundError(resource_type="User", identifier=42)
    assert "User" in str(exc)
    assert "42" in str(exc)


def test_load_data_translates_file_not_found(tmp_path) -> None:
    """load_data should raise AppError when the file is missing."""
    from my_app.exceptions import AppError
    from my_app.loader import load_data

    with pytest.raises(AppError, match="Data file not found"):
        load_data(tmp_path / "missing.csv")


def test_load_data_preserves_original_cause(tmp_path) -> None:
    """load_data should chain the original FileNotFoundError."""
    from my_app.exceptions import AppError
    from my_app.loader import load_data

    with pytest.raises(AppError) as exc_info:
        load_data(tmp_path / "missing.csv")

    assert isinstance(exc_info.value.__cause__, FileNotFoundError)
```

---

## Exit Code Reference

| Code | Meaning | Constant |
|------|---------|---------|
| `0` | Success | — |
| `1` | Generic error | — |
| `64` | Bad usage (wrong arguments) | `EX_USAGE` |
| `65` | Bad input data | `EX_DATAERR` |
| `66` | Input file not found | `EX_NOINPUT` |
| `73` | Cannot create output file | `EX_CANTCREAT` |
| `74` | I/O error | `EX_IOERR` |
| `78` | Configuration error | `EX_CONFIG` |
| `130` | Interrupted by Ctrl-C | — |

---

## See Also

- [`agents/security-agent.md`](../agents/security-agent.md) — error messages must not leak internals
- [`skills/logging-observability.md`](logging-observability.md) — log before suppressing errors
- [`skills/api-integration.md`](api-integration.md) — retry patterns for HTTP clients
- [`skills/python-testing.md`](python-testing.md) — testing error paths
