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
uv run pytest

# Run specific file or directory
uv run pytest tests/unit/test_core.py
uv run pytest tests/unit/

# Run with coverage (terminal report)
uv run pytest --cov=src --cov-report=term-missing

# Run with coverage (HTML report — open htmlcov/index.html)
uv run pytest --cov=src --cov-report=html

# Enforce 100% coverage (fails build if below threshold)
uv run pytest --cov=src --cov-fail-under=100

# Stop on first failure
uv run pytest -x

# Verbose output
uv run pytest -v

# Run only tests matching a keyword
uv run pytest -k "tax or invoice"

# Run tests marked as "unit"
uv run pytest -m unit

# Show locals on failure
uv run pytest -l

# Re-run failed tests from last run
uv run pytest --lf
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

## Integration & End-to-End Tests

### Boundary: What to Mock vs. Hit Live

| Boundary type | Unit tests | Integration tests |
|---------------|-----------|------------------|
| External HTTP APIs | Always mock | Mock with approved library |
| Database (SQLite) | In-memory or mock | Real in-memory instance |
| Database (Postgres/MySQL) | Mock | Real test instance (Docker) |
| File system | `tmp_path` fixture | `tmp_path` fixture |
| Environment variables | `monkeypatch` | `monkeypatch` |
| Time / datetime | `freezegun` | `freezegun` |
| Third-party SDK | Mock | Mock unless testing the integration itself |

**Rule:** Integration tests hit real boundaries within the repo's control
(in-memory DBs, `tmp_path`). They mock boundaries outside the repo's control
(external APIs, third-party services).

### Directory and Marker

```
tests/
├── conftest.py
├── unit/
│   └── test_<module>.py
└── integration/
    ├── conftest.py          # integration-specific fixtures (e.g., test DB setup)
    └── test_<feature>.py
```

Mark all integration tests:

```python
@pytest.mark.integration
def test_pipeline_writes_to_database(test_db_url: str) -> None:
    """Full pipeline run should persist a record to the test database."""
    ...
```

Run integration tests in isolation:

```bash
uv run pytest tests/integration/ -m integration
```

### Coverage Minimum

| Tier | Minimum | Enforcement |
|------|---------|------------|
| Unit tests | 100% | `--cov-fail-under=100` in CI |
| Integration tests | 80% of integration-boundary paths | Advisory; document gaps with `# pragma: no cover` and reason |

### Approved HTTP Mocking Libraries

| Library | Install | Best for |
|---------|---------|---------|
| `pytest-httpx` | `uv add --dev pytest-httpx` | `httpx`-based clients (recommended) |
| `responses` | `uv add --dev responses` | `requests`-based clients |

Do not use `httpretty` — it patches at the socket level and can cause test
isolation failures when run alongside other mocking tools.

#### pytest-httpx example

```python
import pytest
from httpx import AsyncClient

from my_package.client import fetch_user


@pytest.mark.asyncio
@pytest.mark.integration
async def test_fetch_user_returns_name(httpx_mock) -> None:
    """HTTP client should parse name from a mocked API response."""
    httpx_mock.add_response(json={"id": 1, "name": "Alice"})
    result = await fetch_user(client=AsyncClient(), user_id=1)
    assert result.name == "Alice"
```

#### responses example

```python
import responses


@responses.activate
@pytest.mark.integration
def test_fetch_weather_returns_temperature() -> None:
    """Should extract temperature from a mocked weather API response."""
    responses.add(
        responses.GET,
        "https://api.weather.example.com/current",
        json={"temp": 295.15},
        status=200,
    )
    result = fetch_weather()
    assert result.temperature_kelvin == 295.15
```

### When E2E Tests Are Required

Write an E2E test when:
- A CLI command orchestrates multiple modules end-to-end.
- A workflow spans multiple external API calls (auth → fetch → transform → store).
- A regression in the full pipeline has been reported and fixed.

E2E tests live in `tests/integration/` with the `@pytest.mark.integration` marker.
Use live third-party sandboxes when available; otherwise mock at the outermost
boundary only.

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

## Property-Based Testing (Hypothesis)

Apply to any module that: parses or serializes structured data, performs financial
or decimal arithmetic, implements sorting/filtering/search, or validates user input.

```bash
uv add --dev hypothesis
```

```python
from decimal import Decimal

from hypothesis import given, settings
from hypothesis import strategies as st

from my_package.tax import calculate_tax


@given(
    income=st.decimals(min_value=0, max_value=1_000_000, places=2),
    rate=st.decimals(min_value=0, max_value=1, places=4),
)
@settings(max_examples=500)
def test_tax_never_negative(income: Decimal, rate: Decimal) -> None:
    """Tax result must always be non-negative for valid inputs."""
    result = calculate_tax(income, rate)
    assert result >= Decimal("0")


@given(st.text(min_size=0, max_size=1000))
def test_parser_never_crashes(raw: str) -> None:
    """Parser must handle any string without raising an unhandled exception."""
    try:
        parse_record(raw)
    except ValueError:
        pass  # expected for invalid input
```

### Hypothesis Strategies Quick Reference

| Strategy | Use for |
|----------|---------|
| `st.integers()` | Integer inputs with optional bounds |
| `st.decimals()` | Decimal arithmetic testing |
| `st.text()` | String parsing robustness |
| `st.lists(st.integers())` | Collection operations |
| `st.sampled_from([...])` | Enumerated valid values |
| `st.builds(MyClass, ...)` | Dataclass / model construction |

---

## Mutation Testing (mutmut)

Mutation testing verifies that your tests actually catch logic errors, not just
execute lines. Apply to modules with 100% unit coverage and financial/legal logic.

```bash
uv add --dev mutmut
```

```bash
# Run against the src/ directory
mutmut run --paths-to-mutate src/

# Show summary
mutmut results

# Inspect a specific surviving mutant
mutmut show <id>
```

### Interpreting Mutation Scores

| Score | Interpretation |
|-------|---------------|
| 90–100% | Excellent — tests catch most logic errors |
| 75–89% | Acceptable — review surviving mutants for assertion gaps |
| < 75% | Investigate — surviving mutants indicate under-tested branches |

### CI Integration

Mutation testing is slow. Do not run it on every commit.

- Run as a pre-release gate, not in standard CI.
- To limit scope: `mutmut run --paths-to-mutate src/<changed-module>.py`
- Set a minimum score in the release checklist rather than as a hard pipeline gate.

---

## See Also

- [`skills/python-linting.md`](python-linting.md)
- [`templates/pytest.ini`](../templates/pytest.ini)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
