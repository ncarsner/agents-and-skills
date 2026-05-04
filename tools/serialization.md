# Tools: Serialization

Deterministic functions for reading and writing structured data in JSON, CSV,
and TOML formats. All functions are pure transformations over strings or file
paths — given the same input they always produce the same output.

---

## json_loads — parse JSON string with error context

```python
import json
from typing import Any


def json_loads(text: str) -> Any:
    """Parse a JSON string, raising a descriptive error on failure.

    Args:
        text: JSON-encoded string.

    Returns:
        Decoded Python object (dict, list, str, int, float, bool, or None).

    Raises:
        ValueError: If `text` is not valid JSON, with position info included.

    Example::

        >>> json_loads('{"key": "value", "count": 3}')
        {'key': 'value', 'count': 3}
    """
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON at line {exc.lineno}, col {exc.colno}: {exc.msg}") from exc
```

---

## json_dumps — serialize to pretty-printed JSON string

```python
import json
from datetime import date, datetime
from typing import Any


def _default_serializer(obj: Any) -> Any:
    """Fallback serializer for types json.dumps doesn't handle natively."""
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError(f"Object of type {type(obj).__name__} is not JSON serializable")


def json_dumps(obj: Any, *, indent: int = 2, sort_keys: bool = False) -> str:
    """Serialize a Python object to a JSON string.

    Handles `datetime` and `date` objects by converting them to ISO 8601.

    Args:
        obj: Object to serialize. Must be JSON-compatible or contain
            datetime/date values.
        indent: Number of spaces for indentation. Use 0 for compact output.
        sort_keys: If True, dict keys are sorted alphabetically.

    Returns:
        JSON string.

    Raises:
        TypeError: If the object contains non-serializable types.

    Example::

        >>> json_dumps({"name": "Alice", "score": 42})
        '{\\n  "name": "Alice",\\n  "score": 42\\n}'
    """
    _indent: int | None = indent if indent > 0 else None
    return json.dumps(obj, indent=_indent, sort_keys=sort_keys, default=_default_serializer)
```

---

## read_json_file — load JSON from a Path

```python
import json
from pathlib import Path
from typing import Any


def read_json_file(path: Path, encoding: str = "utf-8") -> Any:
    """Read and parse a JSON file.

    Args:
        path: Path to the JSON file.
        encoding: File encoding.

    Returns:
        Decoded Python object.

    Raises:
        FileNotFoundError: If `path` does not exist.
        ValueError: If file contents are not valid JSON.

    Side effects:
        Reads from the filesystem.

    Example::

        >>> data = read_json_file(Path("config.json"))
    """
    try:
        return json.loads(path.read_text(encoding=encoding))
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in {path}: {exc}") from exc
```

---

## write_json_file — serialize and write JSON to a Path

```python
import json
from pathlib import Path
from typing import Any


def write_json_file(path: Path, obj: Any, *, indent: int = 2) -> None:
    """Write a Python object as JSON to a file.

    Creates parent directories as needed. Overwrites existing file.

    Args:
        path: Destination file path.
        obj: JSON-serializable Python object.
        indent: Indentation spaces for human-readable output.

    Side effects:
        Creates directories and writes to the filesystem.

    Example::

        >>> write_json_file(Path("/tmp/result.json"), {"status": "ok"})
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=indent), encoding="utf-8")
```

---

## read_csv — parse CSV file to list of dicts

```python
import csv
from pathlib import Path


def read_csv(
    path: Path,
    *,
    delimiter: str = ",",
    encoding: str = "utf-8-sig",
) -> list[dict[str, str]]:
    """Read a CSV file with a header row into a list of row dicts.

    Uses `utf-8-sig` by default to handle Excel-exported files that include
    a byte-order mark (BOM) on the first line.

    Args:
        path: Path to the CSV file.
        delimiter: Field separator character.
        encoding: File encoding.

    Returns:
        List of dicts where keys are the header column names.

    Raises:
        FileNotFoundError: If `path` does not exist.

    Side effects:
        Reads from the filesystem.

    Example::

        >>> rows = read_csv(Path("data.csv"))
        >>> rows[0]
        {'name': 'Alice', 'score': '95'}
    """
    with path.open(encoding=encoding, newline="") as f:
        return list(csv.DictReader(f, delimiter=delimiter))
```

---

## write_csv — write list of dicts to CSV

```python
import csv
from pathlib import Path


def write_csv(
    path: Path,
    rows: list[dict],
    *,
    fieldnames: list[str] | None = None,
    delimiter: str = ",",
) -> None:
    """Write a list of dicts to a CSV file with a header row.

    Args:
        path: Destination file path.
        rows: List of row dicts. All dicts should share the same keys.
        fieldnames: Column order. If omitted, uses keys from the first row.
        delimiter: Field separator.

    Raises:
        ValueError: If `rows` is empty and `fieldnames` is not provided.

    Side effects:
        Creates directories and writes to the filesystem.

    Example::

        >>> write_csv(Path("/tmp/out.csv"), [{"name": "Alice", "score": "95"}])
    """
    if not rows and not fieldnames:
        raise ValueError("Cannot write CSV: rows is empty and fieldnames not provided")
    columns = fieldnames or list(rows[0].keys())
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=columns, delimiter=delimiter, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
```

---

## parse_toml — read TOML string to dict (Python 3.11+)

```python
import tomllib
from typing import Any


def parse_toml(text: str) -> dict[str, Any]:
    """Parse a TOML string into a Python dict.

    Requires Python 3.11+ (uses stdlib `tomllib`).

    Args:
        text: Valid TOML-encoded string.

    Returns:
        Dict representation of the TOML document.

    Raises:
        tomllib.TOMLDecodeError: If the string is not valid TOML.

    Example::

        >>> parse_toml('[tool]\\nname = "myapp"')
        {'tool': {'name': 'myapp'}}
    """
    return tomllib.loads(text)
```

---

## read_toml_file — load TOML from a Path

```python
import tomllib
from pathlib import Path
from typing import Any


def read_toml_file(path: Path) -> dict[str, Any]:
    """Read and parse a TOML file.

    Requires Python 3.11+ (uses stdlib `tomllib`).

    Args:
        path: Path to the TOML file.

    Returns:
        Dict representation of the TOML document.

    Raises:
        FileNotFoundError: If `path` does not exist.
        tomllib.TOMLDecodeError: If file contents are not valid TOML.

    Side effects:
        Reads from the filesystem.

    Example::

        >>> config = read_toml_file(Path("pyproject.toml"))
        >>> config["project"]["name"]
        'myapp'
    """
    with path.open("rb") as f:
        return tomllib.load(f)
```

---

## See Also

- [`tools/file-io.md`](file-io.md) — low-level file read/write primitives
- [`tools/string-processing.md`](string-processing.md) — regex extraction before parsing
- [`tools/datetime.md`](datetime.md) — serialize datetime values in JSON payloads
- [`skills/database-access.md`](../skills/database-access.md) — structured data in SQL
