# Skill: Logging and Observability

Patterns for structured logging, metrics, and runtime observability in Python
services. Covers the standard `logging` module, `structlog` for JSON output,
and audit trail patterns.

---

## Quick Reference

```bash
uv add structlog               # structured (JSON) logging for production
uv add python-json-logger      # alternative JSON formatter for stdlib logging
```

---

## Standard Library Logging (Default)

Use `logging` for all diagnostic output in library code. Never use `print()`.

```python
"""Module-level logging setup."""

import logging

# Always use __name__ — gives the full dotted module path
logger = logging.getLogger(__name__)


def process_records(records: list[dict]) -> list[dict]:
    """Process a list of records and return transformed results."""
    logger.info("Starting processing: %d records", len(records))
    results = []
    for i, record in enumerate(records):
        try:
            result = _transform(record)
            results.append(result)
        except ValueError as exc:
            logger.warning("Skipping record %d: %s", i, exc)
    logger.info("Processing complete: %d/%d records succeeded", len(results), len(records))
    return results
```

---

## Application Entry Point: Logging Configuration

Configure logging once at application startup — never inside library modules.

```python
"""Logging configuration for application entry points."""

import logging
import sys


def configure_logging(*, level: str = "INFO", json_format: bool = False) -> None:
    """Configure root logger for the application.

    Args:
        level: Log level name (DEBUG, INFO, WARNING, ERROR, CRITICAL).
        json_format: If True, emit JSON lines (production); else human-readable.
    """
    root = logging.getLogger()
    root.setLevel(level)

    if root.handlers:
        # Avoid duplicate handlers when called multiple times
        root.handlers.clear()

    handler = logging.StreamHandler(sys.stdout)

    if json_format:
        import json
        from datetime import datetime, timezone

        class JsonFormatter(logging.Formatter):
            def format(self, record: logging.LogRecord) -> str:
                payload = {
                    "timestamp": datetime.now(tz=timezone.utc).isoformat(),
                    "level": record.levelname,
                    "logger": record.name,
                    "message": record.getMessage(),
                }
                if record.exc_info:
                    payload["exception"] = self.formatException(record.exc_info)
                return json.dumps(payload)

        handler.setFormatter(JsonFormatter())
    else:
        handler.setFormatter(
            logging.Formatter("%(asctime)s %(levelname)-8s %(name)s — %(message)s")
        )

    root.addHandler(handler)
```

---

## Structlog (Production JSON Logging)

Use `structlog` in production services for machine-readable, queryable logs.

```python
"""Structlog configuration for production services."""

import logging
import sys

import structlog


def configure_structlog(*, level: str = "INFO") -> None:
    """Configure structlog for JSON output.

    Call once at application startup before any logging occurs.

    Args:
        level: Minimum log level to emit.
    """
    logging.basicConfig(
        level=level,
        stream=sys.stdout,
        format="%(message)s",
    )
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(
            getattr(logging, level.upper())
        ),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
    )
```

Usage in modules:

```python
"""Module using structlog for structured output."""

import structlog

log = structlog.get_logger(__name__)


def ingest_file(path: str) -> int:
    """Ingest a file and return the number of records read."""
    log.info("ingestion.start", path=path)
    try:
        records = _read_file(path)
        log.info("ingestion.complete", path=path, records=len(records))
        return len(records)
    except FileNotFoundError:
        log.error("ingestion.file_not_found", path=path)
        raise
```

This emits clean JSON like:

```json
{"event": "ingestion.start", "path": "/data/orders.csv", "level": "info", "timestamp": "2024-01-15T10:30:00Z"}
{"event": "ingestion.complete", "path": "/data/orders.csv", "records": 1500, "level": "info", "timestamp": "2024-01-15T10:30:02Z"}
```

---

## Audit Trail Pattern

For legal, fiscal, or compliance-sensitive operations, maintain a dedicated
audit log separate from the diagnostic log.

```python
"""Append-only audit trail for compliance-sensitive operations."""

import logging
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
import json


@dataclass
class AuditEvent:
    """A single auditable event."""

    timestamp: str
    actor: str          # user, service, or process ID
    action: str         # verb describing what happened (e.g., "invoice.approved")
    resource_type: str  # type of the affected resource
    resource_id: str    # ID of the affected resource
    outcome: str        # "success" | "failure"
    detail: str = ""    # human-readable additional context


class AuditLogger:
    """Append-only JSON-Lines audit log writer."""

    def __init__(self, log_path: Path) -> None:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        self._path = log_path
        self._logger = logging.getLogger("audit")

    def record(
        self,
        actor: str,
        action: str,
        resource_type: str,
        resource_id: str,
        *,
        outcome: str = "success",
        detail: str = "",
    ) -> None:
        """Append an audit event to the log.

        Args:
            actor: Identity of the agent/user performing the action.
            action: Verb describing the action (e.g., "user.created").
            resource_type: Type of the resource affected.
            resource_id: Identifier of the specific resource.
            outcome: "success" or "failure".
            detail: Optional human-readable context.
        """
        event = AuditEvent(
            timestamp=datetime.now(tz=timezone.utc).isoformat(),
            actor=actor,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            outcome=outcome,
            detail=detail,
        )
        line = json.dumps(asdict(event))
        self._logger.info(line)
        with self._path.open("a", encoding="utf-8") as f:
            f.write(line + "\n")
```

---

## Performance Timing Pattern

Use `time.monotonic()` for all durations — never `time.time()`.

```python
"""Timing utilities for performance observability."""

import logging
import time
from collections.abc import Generator
from contextlib import contextmanager

logger = logging.getLogger(__name__)


@contextmanager
def timed(operation: str) -> Generator[None, None, None]:
    """Log the elapsed time for a block of code.

    Args:
        operation: Human-readable label for the operation.

    Example::

        with timed("data.export"):
            write_csv(df, output_path)
    """
    start = time.monotonic()
    try:
        yield
    finally:
        elapsed = time.monotonic() - start
        logger.info("%s completed in %.3fs", operation, elapsed)
```

Usage:

```python
with timed("pipeline.transform"):
    result = transform(raw_df, config)
```

---

## Log Level Guide

| Level | When to use |
|-------|-------------|
| `DEBUG` | Detailed internal state; disabled in production by default |
| `INFO` | Normal operation milestones (start, complete, counts) |
| `WARNING` | Recoverable unexpected condition; processing continues |
| `ERROR` | Operation failed; requires attention but process continues |
| `CRITICAL` | Process cannot continue; immediate operator intervention needed |

---

## Security: What NOT to Log

Never log the following, even at DEBUG level:

- Passwords or password hashes
- API keys, tokens, or session IDs
- Full credit card numbers or PAN
- Social Security numbers or government IDs
- Full database connection strings (redact credentials)

---

## See Also

- [`agents/security-agent.md`](../agents/security-agent.md) — what not to log
- [`agents/legal-fiscal-agent.md`](../agents/legal-fiscal-agent.md) — audit trail requirements
- [`skills/configuration-management.md`](configuration-management.md) — environment-based config
