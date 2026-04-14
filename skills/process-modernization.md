# Skill: Process Modernization

Patterns and recipes for converting manual, brittle, and undocumented
processes into maintainable, auditable Python automation.

---

## Modernization Decision Framework

Before writing any code, answer these questions:

1. **What is the current process doing?** Document it in plain English.
2. **What are the inputs?** (files, databases, APIs, manual entry)
3. **What are the outputs?** (files, reports, emails, database writes)
4. **What are the business rules?** (thresholds, conditions, formulas)
5. **What currently breaks?** (error modes, edge cases, undocumented behavior)
6. **How will success be verified?** (comparison to current output)

---

## Configuration-Driven Design

Replace hard-coded values with a TOML config file:

```toml
# config/settings.toml
[pipeline]
source_path = "data/raw/input.csv"
output_path = "data/processed/output.csv"
batch_size = 1000

[validation]
required_columns = ["id", "date", "amount", "category"]
max_amount = 1_000_000
date_format = "%Y-%m-%d"

[notifications]
email_recipients = ["team@example.com"]
smtp_host = "smtp.example.com"
smtp_port = 587

[column_renames]
"Invoice Date" = "invoice_date"
"Vendor Name" = "vendor"
"Total Amount" = "amount"
```

```python
"""Load TOML configuration with validation."""

from __future__ import annotations

import tomllib
from pathlib import Path
from typing import Any


def load_config(path: Path = Path("config/settings.toml")) -> dict[str, Any]:
    """Load and return configuration from TOML file.

    Raises:
        FileNotFoundError: If config file does not exist.
    """
    if not path.exists():
        raise FileNotFoundError(
            f"Config not found: {path}\n"
            f"Copy config/settings.example.toml to {path} and edit it."
        )
    with path.open("rb") as f:
        return tomllib.load(f)
```

---

## ETL Patterns

### Extract
```python
"""Data extraction from various source formats."""

from pathlib import Path
import pandas as pd


def extract(path: Path) -> pd.DataFrame:
    """Load data from CSV, Excel, or JSON based on file extension.

    Args:
        path: Path to the source file.

    Returns:
        Raw DataFrame.

    Raises:
        FileNotFoundError: If file does not exist.
        ValueError: If format is not supported.
    """
    if not path.exists():
        raise FileNotFoundError(f"Source not found: {path}")

    loaders = {
        ".csv": lambda p: pd.read_csv(p, dtype=str),        # str dtype for safe coercion later
        ".xlsx": lambda p: pd.read_excel(p, dtype=str, engine="openpyxl"),
        ".xls": lambda p: pd.read_excel(p, dtype=str),
        ".json": lambda p: pd.read_json(p, dtype=False),
    }
    loader = loaders.get(path.suffix.lower())
    if loader is None:
        raise ValueError(f"Unsupported format: {path.suffix}")
    return loader(path)
```

### Transform
```python
"""Data transformation and business rule application."""

import logging
from typing import Any

import pandas as pd

logger = logging.getLogger(__name__)


def apply_column_renames(df: pd.DataFrame, renames: dict[str, str]) -> pd.DataFrame:
    """Rename columns as specified in config.

    Args:
        df: Input DataFrame.
        renames: Dict mapping old name to new name.

    Returns:
        DataFrame with renamed columns.
    """
    missing = [k for k in renames if k not in df.columns]
    if missing:
        logger.warning("Rename targets not found in data: %s", missing)
    return df.rename(columns={k: v for k, v in renames.items() if k in df.columns})


def normalize_column_names(df: pd.DataFrame) -> pd.DataFrame:
    """Normalize column names to snake_case."""
    df.columns = [
        c.strip().lower().replace(" ", "_").replace("-", "_")
        for c in df.columns
    ]
    return df


def validate_required_columns(df: pd.DataFrame, required: list[str]) -> None:
    """Raise if any required column is missing.

    Raises:
        ValueError: With list of missing column names.
    """
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")


def coerce_numeric(df: pd.DataFrame, columns: list[str]) -> tuple[pd.DataFrame, list[str]]:
    """Coerce columns to numeric, logging and dropping unparseable rows.

    Returns:
        Tuple of (cleaned DataFrame, list of warning messages).
    """
    warnings: list[str] = []
    for col in columns:
        if col not in df.columns:
            continue
        original_len = len(df)
        df[col] = pd.to_numeric(df[col], errors="coerce")
        dropped = original_len - df[col].notna().sum()
        if dropped > 0:
            msg = f"Column '{col}': {dropped} rows had non-numeric values and were set to NaN"
            warnings.append(msg)
            logger.warning(msg)
    return df, warnings
```

### Load
```python
"""Data output to various formats."""

from pathlib import Path
import pandas as pd


def load(df: pd.DataFrame, path: Path) -> None:
    """Write DataFrame to file, creating parent directories as needed.

    Args:
        df: Transformed data.
        path: Destination file (.csv or .xlsx).

    Raises:
        ValueError: If the output format is not supported.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    writers = {
        ".csv": lambda: df.to_csv(path, index=False, encoding="utf-8"),
        ".xlsx": lambda: df.to_excel(path, index=False, engine="openpyxl"),
        ".json": lambda: df.to_json(path, orient="records", indent=2),
    }
    writer = writers.get(path.suffix.lower())
    if writer is None:
        raise ValueError(f"Unsupported output format: {path.suffix}")
    writer()
```

---

## Pipeline Orchestration

```python
"""Pipeline orchestration with result tracking."""

import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


@dataclass
class RunResult:
    """Result summary from a pipeline run."""
    records_read: int = 0
    records_written: int = 0
    records_skipped: int = 0
    warnings: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)

    @property
    def success(self) -> bool:
        return not self.errors


def run(config: dict[str, Any]) -> RunResult:
    """Execute the full ETL pipeline.

    Args:
        config: Loaded configuration dictionary.

    Returns:
        RunResult with counts and any warnings/errors.
    """
    result = RunResult()
    source = Path(config["pipeline"]["source_path"])
    output = Path(config["pipeline"]["output_path"])
    renames = config.get("column_renames", {})
    required = config.get("validation", {}).get("required_columns", [])

    logger.info("Pipeline start: %s → %s", source, output)

    try:
        raw = extract(source)
        result.records_read = len(raw)

        df = normalize_column_names(raw)
        df = apply_column_renames(df, renames)
        validate_required_columns(df, required)
        df, warnings = coerce_numeric(df, [])
        result.warnings.extend(warnings)

        before = len(df)
        df = df.dropna(how="all")
        skipped = before - len(df)
        if skipped:
            result.warnings.append(f"Dropped {skipped} empty rows")
        result.records_skipped = skipped

        load(df, output)
        result.records_written = len(df)
        logger.info("Pipeline complete. Written: %d", result.records_written)

    except Exception as exc:
        logger.error("Pipeline error: %s", exc, exc_info=True)
        result.errors.append(str(exc))

    return result
```

---

## Legacy VBA → Python Mapping

| VBA Pattern | Python Equivalent |
|------------|------------------|
| `ActiveSheet.Cells(r, c)` | `df.iloc[r, c]` or `df.at[r, col_name]` |
| `On Error Resume Next` | `try/except` with specific exception types |
| `Range("A1").Value` | `df["column_name"].iloc[0]` |
| `MsgBox "Done"` | `logger.info("Done")` |
| `Dim arr() As String` | `items: list[str] = []` |
| `For Each cell In Range` | `for value in df["col"]:` |
| `VLOOKUP` | `df.merge()` or `df.set_index().loc[]` |
| `IF/ELSEIF/ELSE` | `if/elif/else` or `np.where()` |
| Hard-coded file path | `Path(config["paths"]["input"])` |

---

## Data Quality Reporting

```python
"""Generate a data quality report for a DataFrame."""

from dataclasses import dataclass
import pandas as pd


@dataclass
class ColumnQuality:
    """Quality metrics for a single DataFrame column."""
    name: str
    dtype: str
    null_count: int
    null_pct: float
    unique_count: int
    sample_values: list


def profile_dataframe(df: pd.DataFrame) -> list[ColumnQuality]:
    """Profile each column for data quality metrics.

    Args:
        df: DataFrame to profile.

    Returns:
        List of ColumnQuality objects, one per column.
    """
    report = []
    for col in df.columns:
        series = df[col]
        null_count = int(series.isna().sum())
        report.append(
            ColumnQuality(
                name=col,
                dtype=str(series.dtype),
                null_count=null_count,
                null_pct=round(null_count / len(df) * 100, 2) if len(df) else 0.0,
                unique_count=int(series.nunique()),
                sample_values=series.dropna().head(3).tolist(),
            )
        )
    return report
```

---

## Automated Change Detection

```python
"""Detect changes between old and new data snapshots."""

import pandas as pd


def detect_new_records(
    old: pd.DataFrame, new: pd.DataFrame, key_col: str
) -> pd.DataFrame:
    """Return rows in new that are not in old (by key).

    Args:
        old: Previous snapshot DataFrame.
        new: Current snapshot DataFrame.
        key_col: Column name to use as the unique key.

    Returns:
        DataFrame of new records not in old.
    """
    return new[~new[key_col].isin(old[key_col])].copy()


def detect_changed_records(
    old: pd.DataFrame, new: pd.DataFrame, key_col: str, compare_cols: list[str]
) -> pd.DataFrame:
    """Return records whose values changed between snapshots.

    Args:
        old: Previous snapshot.
        new: Current snapshot.
        key_col: Unique key column name.
        compare_cols: Columns to compare for changes.

    Returns:
        DataFrame of changed records (from new), with a 'changed_columns' column.
    """
    merged = new.merge(old, on=key_col, suffixes=("_new", "_old"))
    changed_rows = []
    for _, row in merged.iterrows():
        changed = [
            c for c in compare_cols
            if row.get(f"{c}_new") != row.get(f"{c}_old")
        ]
        if changed:
            record = {key_col: row[key_col], "changed_columns": changed}
            for c in compare_cols:
                record[f"{c}_old"] = row.get(f"{c}_old")
                record[f"{c}_new"] = row.get(f"{c}_new")
            changed_rows.append(record)
    return pd.DataFrame(changed_rows)
```

---

## Testing Process Code

```python
"""Tests for pipeline transform functions."""

from pathlib import Path
import pandas as pd
import pytest

from my_process.transform import (
    normalize_column_names,
    validate_required_columns,
    apply_column_renames,
)
from my_process.quality import detect_new_records


def test_normalize_column_names() -> None:
    df = pd.DataFrame({"First Name": [1], "Total-Amount": [2]})
    result = normalize_column_names(df)
    assert "first_name" in result.columns
    assert "total_amount" in result.columns


def test_validate_required_columns_raises_on_missing() -> None:
    df = pd.DataFrame({"a": [1], "b": [2]})
    with pytest.raises(ValueError, match="Missing required columns"):
        validate_required_columns(df, required=["a", "c"])


def test_validate_required_columns_passes_when_present() -> None:
    df = pd.DataFrame({"a": [1], "b": [2]})
    validate_required_columns(df, required=["a", "b"])  # should not raise


def test_apply_column_renames_maps_correctly() -> None:
    df = pd.DataFrame({"Old Name": [1]})
    result = apply_column_renames(df, {"Old Name": "new_name"})
    assert "new_name" in result.columns
    assert "Old Name" not in result.columns


def test_detect_new_records_finds_additions() -> None:
    old = pd.DataFrame({"id": [1, 2], "val": ["a", "b"]})
    new = pd.DataFrame({"id": [1, 2, 3], "val": ["a", "b", "c"]})
    added = detect_new_records(old, new, key_col="id")
    assert len(added) == 1
    assert added.iloc[0]["id"] == 3
```

---

## See Also

- [`agents/process-modernization-agent.md`](../agents/process-modernization-agent.md)
- [`skills/python-testing.md`](python-testing.md)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
