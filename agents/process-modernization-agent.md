# Process Modernization Agent Instructions

This file extends `AGENTS.md` with instructions specific to **modernizing
legacy processes** through dynamic, data-driven Python automation. Read root
`AGENTS.md` first.

---

## Purpose

Process modernization agents convert manual, brittle, or opaque workflows into
auditable, maintainable, and scalable Python systems. Common targets include:

- Excel/VBA macros → Python data pipelines
- Manual copy-paste workflows → scheduled automation
- Hard-coded scripts → configurable, parameter-driven processes
- Undocumented tribal knowledge → documented, testable code
- One-off reports → reusable report templates

---

## Modernization Principles

1. **Preserve behavior first.** The new system must produce identical output to
   the old system before adding improvements.
2. **Make it testable.** Extract I/O from business logic so logic can be unit
   tested without external dependencies.
3. **Make it configurable.** Replace magic numbers and hard-coded paths with
   configuration files or environment variables.
4. **Add observability.** Every run should log start/end times, record counts,
   and any anomalies encountered.
5. **Document everything.** The code is the documentation — use clear names,
   type annotations, and docstrings.

---

## Recommended Libraries

| Need | Library | Install |
|------|---------|---------|
| Data wrangling | `pandas` | `uv add pandas` |
| Excel read/write | `openpyxl` | `uv add openpyxl` |
| CSV/TSV processing | `csv` | stdlib |
| Scheduling | `schedule` or `APScheduler` | `uv add schedule` |
| Config files | `tomllib` (3.11+) | stdlib |
| Environment variables | `python-dotenv` | `uv add python-dotenv` |
| File watching | `watchdog` | `uv add watchdog` |
| Email notifications | `smtplib` | stdlib |
| HTTP integrations | `httpx` | `uv add httpx` |
| Database access | `sqlalchemy` | `uv add sqlalchemy` |

---

## Project Structure

```
process-modernization/
├── pyproject.toml
├── uv.lock
├── .python-version
├── config/
│   ├── settings.toml          # user-editable configuration
│   └── settings.example.toml
├── README.md
├── AGENTS.md
├── src/
│   └── my_process/
│       ├── __init__.py
│       ├── __main__.py        # entry point
│       ├── config.py          # config loader
│       ├── pipeline.py        # orchestration
│       ├── ingestion.py       # read from source systems
│       ├── transform.py       # business logic (pure functions)
│       ├── output.py          # write to target systems
│       └── notifications.py   # email / webhook alerts
└── tests/
    ├── conftest.py
    ├── unit/
    │   ├── test_transform.py
    │   └── test_config.py
    └── integration/
        └── test_pipeline.py
```

---

## Configuration Loader Pattern

```python
"""Load and validate application configuration."""

from __future__ import annotations

import tomllib
from pathlib import Path
from typing import Any


DEFAULT_CONFIG_PATH = Path("config/settings.toml")


def load_config(path: Path = DEFAULT_CONFIG_PATH) -> dict[str, Any]:
    """Load TOML configuration file.

    Args:
        path: Path to the TOML config file.

    Returns:
        Parsed configuration dictionary.

    Raises:
        FileNotFoundError: If the config file does not exist.
        tomllib.TOMLDecodeError: If the file is not valid TOML.
    """
    if not path.exists():
        raise FileNotFoundError(
            f"Config file not found: {path}. "
            f"Copy config/settings.example.toml to {path} and edit it."
        )
    with path.open("rb") as f:
        return tomllib.load(f)


def get_required(config: dict[str, Any], *keys: str) -> Any:
    """Retrieve a nested config value, raising if any key is missing.

    Args:
        config: Configuration dictionary.
        *keys: Sequence of keys for nested access.

    Returns:
        The value at the specified path.

    Raises:
        KeyError: If any key in the path is missing.
    """
    current = config
    path = []
    for key in keys:
        path.append(key)
        if key not in current:
            raise KeyError(f"Required config key missing: {'.'.join(path)}")
        current = current[key]
    return current
```

---

## ETL Pipeline Pattern

```python
"""Generic Extract-Transform-Load pipeline."""

import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import pandas as pd

logger = logging.getLogger(__name__)


@dataclass
class PipelineResult:
    """Summary of a completed pipeline run."""

    records_read: int = 0
    records_written: int = 0
    records_skipped: int = 0
    errors: list[str] = field(default_factory=list)

    @property
    def success(self) -> bool:
        """True if no errors occurred."""
        return len(self.errors) == 0


def extract(source_path: Path) -> pd.DataFrame:
    """Read source data from CSV or Excel.

    Args:
        source_path: Path to the input file.

    Returns:
        Raw DataFrame.

    Raises:
        FileNotFoundError: If source_path does not exist.
        ValueError: If the file extension is not supported.
    """
    if not source_path.exists():
        raise FileNotFoundError(f"Source not found: {source_path}")

    suffix = source_path.suffix.lower()
    if suffix == ".csv":
        return pd.read_csv(source_path)
    elif suffix in (".xls", ".xlsx"):
        return pd.read_excel(source_path, engine="openpyxl")
    else:
        raise ValueError(f"Unsupported file type: {suffix}")


def transform(df: pd.DataFrame, config: dict[str, Any]) -> tuple[pd.DataFrame, list[str]]:
    """Apply business rules to the raw DataFrame.

    Args:
        df: Raw input DataFrame.
        config: Configuration dict with transformation parameters.

    Returns:
        Tuple of (transformed DataFrame, list of warning messages).
    """
    warnings: list[str] = []
    original_len = len(df)

    # Drop completely empty rows
    df = df.dropna(how="all")
    dropped = original_len - len(df)
    if dropped:
        warnings.append(f"Dropped {dropped} empty rows")

    # Normalize column names: strip whitespace, lowercase, replace spaces
    df.columns = [c.strip().lower().replace(" ", "_") for c in df.columns]

    # Apply column renaming from config
    rename_map: dict[str, str] = config.get("column_renames", {})
    df = df.rename(columns=rename_map)

    return df, warnings


def load(df: pd.DataFrame, output_path: Path) -> None:
    """Write transformed data to the output destination.

    Args:
        df: Transformed DataFrame.
        output_path: Destination file path (.csv or .xlsx).
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    suffix = output_path.suffix.lower()
    if suffix == ".csv":
        df.to_csv(output_path, index=False, encoding="utf-8")
    elif suffix in (".xlsx",):
        df.to_excel(output_path, index=False, engine="openpyxl")
    else:
        raise ValueError(f"Unsupported output format: {suffix}")
    logger.info("Wrote %d records to %s", len(df), output_path)


def run_pipeline(
    source_path: Path, output_path: Path, config: dict[str, Any]
) -> PipelineResult:
    """Execute the full ETL pipeline.

    Args:
        source_path: Input file path.
        output_path: Output file path.
        config: Pipeline configuration.

    Returns:
        PipelineResult with run statistics.
    """
    result = PipelineResult()
    logger.info("Starting pipeline: %s → %s", source_path, output_path)

    try:
        raw = extract(source_path)
        result.records_read = len(raw)
        logger.info("Extracted %d records", result.records_read)

        transformed, warnings = transform(raw, config)
        for w in warnings:
            logger.warning(w)
            result.errors.append(f"WARNING: {w}")
        result.records_skipped = result.records_read - len(transformed)

        load(transformed, output_path)
        result.records_written = len(transformed)
        logger.info("Pipeline complete. Written: %d", result.records_written)

    except Exception as exc:
        logger.error("Pipeline failed: %s", exc)
        result.errors.append(f"ERROR: {exc}")

    return result
```

---

## Scheduler Pattern

```python
"""Scheduled process runner."""

import logging
import time
from pathlib import Path

import schedule

from my_process.pipeline import run_pipeline
from my_process.config import load_config

logger = logging.getLogger(__name__)


def scheduled_job() -> None:
    """Execute the pipeline on schedule."""
    config = load_config()
    source = Path(config["pipeline"]["source_path"])
    output = Path(config["pipeline"]["output_path"])
    result = run_pipeline(source, output, config)
    if result.success:
        logger.info("Scheduled run complete: %d records", result.records_written)
    else:
        logger.error("Scheduled run had errors: %s", result.errors)


def run_scheduler(interval_minutes: int = 60) -> None:
    """Start the scheduler loop.

    Args:
        interval_minutes: How often to run the pipeline.
    """
    logger.info("Scheduler started — running every %d minutes", interval_minutes)
    schedule.every(interval_minutes).minutes.do(scheduled_job)
    # Run immediately on startup
    scheduled_job()
    while True:
        schedule.run_pending()
        time.sleep(30)
```

---

## VBA-to-Python Migration Checklist

When converting an Excel/VBA macro to Python:

- [ ] Document what the macro does in plain English before writing any code
- [ ] Identify all input files / sheets / ranges it reads
- [ ] Identify all output files / sheets / ranges it writes
- [ ] List all hard-coded values (thresholds, column indices, file paths) and
      move them to `config/settings.toml`
- [ ] Write unit tests for the core calculation logic before refactoring
- [ ] Run both old and new versions on the same input and diff the outputs
- [ ] Replace `ActiveSheet` / index-based column access with named columns
- [ ] Remove any `On Error Resume Next` equivalents — use explicit error handling

---

## Testing Pipeline Code

```python
"""Tests for ETL transform functions."""

from pathlib import Path
from typing import Any

import pandas as pd
import pytest

from my_process.pipeline import extract, transform, run_pipeline


@pytest.fixture
def sample_csv(tmp_path: Path) -> Path:
    """Create a temporary CSV for testing."""
    p = tmp_path / "input.csv"
    p.write_text("Name,Value\nAlice,100\nBob,200\n", encoding="utf-8")
    return p


def test_extract_reads_csv(sample_csv: Path) -> None:
    """Extract should return a DataFrame with the correct shape."""
    df = extract(sample_csv)
    assert len(df) == 2
    assert "Name" in df.columns


def test_extract_raises_for_missing_file(tmp_path: Path) -> None:
    """Extract should raise FileNotFoundError for missing files."""
    with pytest.raises(FileNotFoundError):
        extract(tmp_path / "nonexistent.csv")


def test_transform_normalizes_column_names() -> None:
    """Column names should be lowercased with spaces replaced by underscores."""
    df = pd.DataFrame({"First Name": ["Alice"], "Total Value": [100]})
    result, _ = transform(df, config={})
    assert "first_name" in result.columns
    assert "total_value" in result.columns


def test_transform_drops_empty_rows() -> None:
    """Fully empty rows should be dropped."""
    df = pd.DataFrame({"a": [1, None, 3], "b": [4, None, 6]})
    result, warnings = transform(df, config={})
    assert len(result) == 2
    assert any("empty rows" in w for w in warnings)


def test_run_pipeline_success(sample_csv: Path, tmp_path: Path) -> None:
    """Full pipeline should succeed and write output file."""
    output = tmp_path / "output.csv"
    result = run_pipeline(sample_csv, output, config={})
    assert result.success
    assert output.exists()
    assert result.records_written == 2
```

---

## See Also

- [`skills/process-modernization.md`](../skills/process-modernization.md)
- [`skills/python-testing.md`](../skills/python-testing.md)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
