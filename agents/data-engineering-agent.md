# Data Engineering Agent Instructions

This file extends `AGENTS.md` with instructions specific to **data engineering**
projects in Python: ETL pipelines, database integrations, data validation, and
scheduled batch processing. Read root `AGENTS.md` first.

---

## Purpose

Data engineering agents build systems that:

- Ingest data from heterogeneous sources (CSV, Excel, APIs, databases, message queues)
- Validate, clean, and transform data according to business rules
- Load results into target systems (databases, data warehouses, file stores)
- Run reliably on a schedule with full observability and error recovery

---

## Recommended Libraries

| Need | Library | Install |
|------|---------|---------|
| Data wrangling | `pandas` | `uv add pandas` |
| Database ORM | `sqlalchemy` | `uv add sqlalchemy` |
| Async database | `databases` | `uv add databases` |
| Data validation | `pydantic` | `uv add pydantic` |
| HTTP ingestion | `httpx` | `uv add httpx` |
| Arrow/Parquet | `pyarrow` | `uv add pyarrow` |
| CSV/TSV | `csv` | stdlib |
| Excel I/O | `openpyxl` | `uv add openpyxl` |
| Scheduling | `APScheduler` | `uv add apscheduler` |
| Config files | `tomllib` | stdlib (3.11+) |
| Environment variables | `python-dotenv` | `uv add python-dotenv` |
| Retry logic | `tenacity` | `uv add tenacity` |

---

## Architecture Boundaries

Respect these layer boundaries. Never skip layers.

```
Source Systems
      │
      ▼
  Ingestion Layer     ← read-only access to sources; never write back
      │
      ▼
 Validation Layer     ← reject or quarantine invalid records; never silently drop
      │
      ▼
  Transform Layer     ← pure functions; no I/O; fully unit-testable
      │
      ▼
   Load Layer         ← write to target; idempotent when possible
      │
      ▼
 Target Systems
```

---

## Project Structure

```
my-pipeline/
├── pyproject.toml
├── uv.lock
├── .python-version
├── .env.example
├── README.md
├── AGENTS.md
├── config/
│   ├── settings.toml          # pipeline parameters (not secrets)
│   └── settings.example.toml
├── src/
│   └── my_pipeline/
│       ├── __init__.py
│       ├── __main__.py        # CLI entry point
│       ├── config.py          # config/settings loader
│       ├── ingestion.py       # extract from sources
│       ├── validation.py      # pydantic models + validation rules
│       ├── transform.py       # pure transformation functions
│       ├── load.py            # write to targets
│       ├── pipeline.py        # orchestration (calls all layers)
│       ├── db/
│       │   ├── __init__.py
│       │   ├── models.py      # SQLAlchemy ORM models
│       │   └── session.py     # engine and session factory
│       └── notifications.py   # alerts on failure
└── tests/
    ├── conftest.py
    ├── unit/
    │   ├── test_validation.py
    │   └── test_transform.py
    └── integration/
        └── test_pipeline.py
```

---

## Database Session Pattern (SQLAlchemy)

```python
"""Database engine and session factory."""

from collections.abc import Generator
from contextlib import contextmanager

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    """Shared declarative base for all ORM models."""


def make_session_factory(database_url: str) -> sessionmaker[Session]:
    """Create a session factory bound to the given database URL.

    Args:
        database_url: SQLAlchemy-compatible connection string.

    Returns:
        Configured sessionmaker.
    """
    engine = create_engine(database_url, echo=False, pool_pre_ping=True)
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine, expire_on_commit=False)


@contextmanager
def get_session(factory: sessionmaker[Session]) -> Generator[Session, None, None]:
    """Provide a transactional scope around a series of operations.

    Args:
        factory: The sessionmaker to use.

    Yields:
        An active SQLAlchemy Session.
    """
    session = factory()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
```

---

## Validation Pattern (Pydantic)

```python
"""Row-level validation using Pydantic models."""

import logging
from dataclasses import dataclass, field
from typing import Any

from pydantic import BaseModel, ValidationError

logger = logging.getLogger(__name__)


class SalesRow(BaseModel):
    """Validated representation of a single sales record."""

    order_id: str
    product_sku: str
    quantity: int
    unit_price: float
    region: str

    model_config = {"str_strip_whitespace": True}


@dataclass
class ValidationResult:
    """Outcome of batch validation."""

    valid: list[SalesRow] = field(default_factory=list)
    invalid: list[dict[str, Any]] = field(default_factory=list)

    @property
    def error_rate(self) -> float:
        """Fraction of records that failed validation."""
        total = len(self.valid) + len(self.invalid)
        return len(self.invalid) / total if total > 0 else 0.0


def validate_rows(raw_rows: list[dict[str, Any]]) -> ValidationResult:
    """Validate a list of raw row dicts against the SalesRow schema.

    Args:
        raw_rows: List of dicts parsed from the source file.

    Returns:
        ValidationResult containing valid models and invalid raw dicts.
    """
    result = ValidationResult()
    for row in raw_rows:
        try:
            result.valid.append(SalesRow.model_validate(row))
        except ValidationError as exc:
            logger.warning("Validation failed for row %r: %s", row, exc)
            result.invalid.append(row)
    return result
```

---

## Retry Pattern (Tenacity)

```python
"""HTTP ingestion with automatic retry on transient failures."""

import logging

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

logger = logging.getLogger(__name__)


@retry(
    retry=retry_if_exception_type((httpx.TimeoutException, httpx.NetworkError)),
    wait=wait_exponential(multiplier=1, min=2, max=30),
    stop=stop_after_attempt(5),
    reraise=True,
)
def fetch_json(url: str, *, timeout: float = 10.0) -> dict:
    """Fetch JSON from a URL with exponential-backoff retry.

    Args:
        url: Target URL.
        timeout: Request timeout in seconds.

    Returns:
        Parsed JSON response as a dict.

    Raises:
        httpx.HTTPStatusError: On non-2xx responses (no retry).
        httpx.TimeoutException: After all retry attempts exhausted.
    """
    logger.debug("GET %s", url)
    with httpx.Client(timeout=timeout) as client:
        response = client.get(url)
        response.raise_for_status()
        return response.json()
```

---

## Idempotent Load Pattern

```python
"""Write records to the database using upsert for idempotency."""

import logging

from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.orm import Session

from my_pipeline.db.models import OrderRecord

logger = logging.getLogger(__name__)


def upsert_orders(session: Session, rows: list[dict]) -> int:
    """Insert or update order records; safe to run multiple times.

    Args:
        session: Active SQLAlchemy session.
        rows: List of dicts matching the OrderRecord table columns.

    Returns:
        Number of rows affected.
    """
    if not rows:
        return 0
    stmt = sqlite_insert(OrderRecord).values(rows)
    stmt = stmt.on_conflict_do_update(
        index_elements=["order_id"],
        set_={col: stmt.excluded[col] for col in rows[0] if col != "order_id"},
    )
    result = session.execute(stmt)
    logger.info("Upserted %d order records", result.rowcount)
    return result.rowcount
```

---

## Observability Checklist

- [ ] Log pipeline start/end with record counts at INFO level
- [ ] Log validation error rate; alert if above threshold (e.g., > 5%)
- [ ] Log each layer's duration using `time.monotonic()` (never `time.time()`)
- [ ] Emit a structured summary on completion (`records_read`, `records_valid`, `records_written`, `errors`)
- [ ] Write failed/quarantined records to a separate output for manual review
- [ ] Use `structlog` for JSON-formatted logs in production deployments

---

## Testing Data Pipelines

```python
"""Integration tests for the full ETL pipeline."""

from pathlib import Path

import pandas as pd
import pytest

from my_pipeline.pipeline import run_pipeline


@pytest.fixture
def sample_csv(tmp_path: Path) -> Path:
    """Write a minimal valid CSV to a temp directory."""
    p = tmp_path / "orders.csv"
    p.write_text(
        "order_id,product_sku,quantity,unit_price,region\n"
        "ORD-001,SKU-A,2,19.99,North\n"
        "ORD-002,SKU-B,1,49.99,South\n",
        encoding="utf-8",
    )
    return p


def test_pipeline_processes_valid_csv(sample_csv: Path, tmp_path: Path) -> None:
    """Pipeline should write all valid rows to the output database."""
    db_url = f"sqlite:///{tmp_path / 'output.db'}"
    result = run_pipeline(source=sample_csv, database_url=db_url)
    assert result.success
    assert result.records_written == 2
    assert result.error_rate == 0.0


def test_pipeline_quarantines_invalid_rows(tmp_path: Path) -> None:
    """Pipeline should quarantine rows that fail validation."""
    bad_csv = tmp_path / "bad_orders.csv"
    bad_csv.write_text(
        "order_id,product_sku,quantity,unit_price,region\n"
        "ORD-001,SKU-A,-5,19.99,North\n",  # negative quantity is invalid
        encoding="utf-8",
    )
    db_url = f"sqlite:///{tmp_path / 'output.db'}"
    result = run_pipeline(source=bad_csv, database_url=db_url)
    assert result.records_written == 0
    assert result.records_invalid == 1
```

---

## See Also

- [`skills/database-access.md`](../skills/database-access.md) — SQLAlchemy patterns
- [`skills/api-integration.md`](../skills/api-integration.md) — HTTP client patterns
- [`skills/error-handling.md`](../skills/error-handling.md) — retry and exception handling
- [`skills/python-testing.md`](../skills/python-testing.md) — testing cookbook
- [`templates/pyproject.toml`](../templates/pyproject.toml) — starter config
