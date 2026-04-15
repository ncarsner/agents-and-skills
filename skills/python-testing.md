# Skill: Python Testing

Comprehensive cookbook for writing and running Python tests using `pytest`,
`pytest-cov`, and related plugins. The goal is **100% line and branch coverage**
for all new code.

---

## Core Tools

| Tool | Purpose | Install |
|------|---------|---------|
| `pytest` | Test runner | `uv add --dev pytest` |
| `pytest-cov` | Coverage reporting | `uv add --dev pytest-cov` |
| `pytest-mock` | Mocking fixtures | `uv add --dev pytest-mock` |
| `pytest-httpx` | Mock HTTP calls | `uv add --dev pytest-httpx` |
| `pytest-asyncio` | Async test support | `uv add --dev pytest-asyncio` |
| `freezegun` | Freeze `datetime.now()` | `uv add --dev freezegun` |
| `factory-boy` | Test data factories | `uv add --dev factory-boy` |

---

## Essential Commands

```bash
# Run all tests
python3 -m pytest

# Run specific file or directory
python3 -m pytest tests/unit/test_core.py
python3 -m pytest tests/unit/

# Run with coverage (terminal report)
python3 -m pytest --cov=src --cov-report=term-missing

# Run with coverage (HTML report — open htmlcov/index.html)
python3 -m pytest --cov=src --cov-report=html

# Enforce 100% coverage (fails build if below threshold)
python3 -m pytest --cov=src --cov-fail-under=100

# Stop on first failure
python3 -m pytest -x

# Verbose output
python3 -m pytest -v

# Run only tests matching a keyword
python3 -m pytest -k "tax or invoice"

# Run tests marked as "unit"
python3 -m pytest -m unit

# Show locals on failure
python3 -m pytest -l

# Re-run failed tests from last run
python3 -m pytest --lf
```

---

## `pytest.ini` / `pyproject.toml` Configuration

```toml
# In pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = [
    "-v",
    "--strict-markers",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-fail-under=100",
]
markers = [
    "unit: fast, isolated unit tests",
    "integration: tests that touch external systems",
    "slow: long-running tests",
]
```

---

## File and Function Naming Conventions

```
tests/
├── conftest.py              # shared fixtures for all tests
├── unit/
│   ├── __init__.py
│   ├── conftest.py          # fixtures for unit tests only
│   └── test_<module>.py    # one file per source module
└── integration/
    ├── __init__.py
    └── test_<feature>.py
```

- Test files: `test_<module>.py`
- Test functions: `test_<behavior_under_test>()`
- Test classes (optional): `TestClassName`

---

## Fixture Patterns

### Basic fixtures
```python
import pytest
from pathlib import Path


@pytest.fixture
def tmp_config_file(tmp_path: Path) -> Path:
    """Create a temporary TOML config file."""
    config = tmp_path / "settings.toml"
    config.write_text('[app]\nname = "test"\n', encoding="utf-8")
    return config


@pytest.fixture
def sample_dataframe():
    """Provide a small DataFrame for testing."""
    import pandas as pd
    return pd.DataFrame({"a": [1, 2, 3], "b": [4, 5, 6]})
```

### Fixture scope
```python
@pytest.fixture(scope="module")  # created once per test module
def database_connection():
    conn = create_test_db()
    yield conn
    conn.close()

@pytest.fixture(scope="session")  # created once for the entire test session
def shared_model():
    return load_heavy_model()
```

### Autouse fixtures
```python
@pytest.fixture(autouse=True)
def reset_logging(caplog):
    """Ensure log level is reset before each test."""
    caplog.set_level(logging.DEBUG)
    yield
```

---

## Parametrize Pattern

```python
import pytest
from decimal import Decimal

from my_package.tax import calculate_tax


@pytest.mark.parametrize(
    "income,rate,expected",
    [
        (Decimal("50000"), Decimal("0.22"), Decimal("11000.00")),
        (Decimal("0"), Decimal("0.22"), Decimal("0.00")),
        (Decimal("100000"), Decimal("0.00"), Decimal("0.00")),
    ],
)
def test_calculate_tax(income: Decimal, rate: Decimal, expected: Decimal) -> None:
    """Tax calculation should return correct amounts for various inputs."""
    assert calculate_tax(income, rate) == expected
```

---

## Exception Testing Pattern

```python
def test_raises_on_negative_income() -> None:
    """Negative income should raise ValueError with a descriptive message."""
    with pytest.raises(ValueError, match="income must be non-negative"):
        calculate_tax(Decimal("-1"), Decimal("0.22"))


def test_raises_file_not_found() -> None:
    """Missing input file should raise FileNotFoundError."""
    with pytest.raises(FileNotFoundError):
        load_data(Path("/nonexistent/file.csv"))
```

---

## Mocking Patterns

### Mock external API call
```python
from unittest.mock import MagicMock, patch


def test_fetch_weather_returns_temperature(mocker) -> None:
    """Should return temperature from API response."""
    mock_response = MagicMock()
    mock_response.json.return_value = {"main": {"temp": 295.15}}
    mock_response.status_code = 200

    mocker.patch("requests.get", return_value=mock_response)

    result = fetch_current_weather("Nashville")
    assert result.temperature_kelvin == 295.15


@patch("my_module.datetime")
def test_uses_current_date(mock_dt) -> None:
    """Should use today's date when generating report filename."""
    from datetime import date
    mock_dt.today.return_value = date(2024, 6, 15)
    filename = generate_report_filename()
    assert filename == "report_2024-06-15.csv"
```

### Mock file system (use `tmp_path` instead of mocking)
```python
def test_writes_output_file(tmp_path: Path) -> None:
    """Function should create an output file in the given directory."""
    output = tmp_path / "results.csv"
    write_results([{"id": 1, "value": 42}], output)
    assert output.exists()
    assert "id,value" in output.read_text()
```

---

## Async Test Pattern

```python
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_async_fetch_returns_data() -> None:
    """Async fetch should return expected data."""
    result = await fetch_data_async("https://example.com/api")
    assert result is not None
```

Add to `pyproject.toml`:
```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
```

---

## Coverage Exclusions

Use `# pragma: no cover` sparingly — only for code that is genuinely untestable
(e.g., `__main__` blocks, abstract method stubs):

```python
if __name__ == "__main__":  # pragma: no cover
    main()
```

Configure in `pyproject.toml`:
```toml
[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
    "@(abc\\.)?abstractmethod",
]
```

---

## Test Quality Checklist

- [ ] Every public function has at least one test
- [ ] Every exception path has a test verifying the exception type and message
- [ ] Parametrize is used for data-driven tests (not repeated test functions)
- [ ] No hardcoded file paths — use `tmp_path` fixture
- [ ] External HTTP calls are mocked
- [ ] Database calls are mocked or use an in-memory test database
- [ ] `--cov-fail-under=100` is set in CI

---

## See Also

- [`skills/python-linting.md`](python-linting.md)
- [`templates/pytest.ini`](../templates/pytest.ini)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
