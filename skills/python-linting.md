# Skill: Python Linting

Reusable patterns and configuration for Python static analysis using `ruff`
(linting) and `mypy` (type checking).

---

## Tools

| Tool | Purpose | Install |
|------|---------|---------|
| `ruff` | Fast linter + formatter (replaces flake8, isort, pylint) | `uv add --dev ruff` |
| `mypy` | Static type checker | `uv add --dev mypy` |

---

## Ruff Linting

### Commands
```bash
ruff check .                  # lint all Python files
ruff check . --fix            # auto-fix safe issues
ruff check . --fix --unsafe-fixes  # also apply unsafe fixes (review changes)
ruff check src/               # lint a specific directory
ruff check path/to/file.py    # lint a single file
ruff check . --output-format=github  # GitHub Actions annotation format
```

### Rule Selection (in `pyproject.toml`)

```toml
[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "B",    # flake8-bugbear
    "C4",   # flake8-comprehensions
    "UP",   # pyupgrade
    "S",    # flake8-bandit (security)
    "N",    # pep8-naming
    "D",    # pydocstyle
    "ANN",  # flake8-annotations (type hints)
    "RUF",  # ruff-specific rules
    "PT",   # flake8-pytest-style
    "SIM",  # flake8-simplify
    "TCH",  # flake8-type-checking
    "TID",  # flake8-tidy-imports
    "ERA",  # eradicate (commented-out code)
    "PL",   # pylint
    "BLE",  # flake8-blind-except
]
ignore = [
    "D100",  # allow missing docstring in public module (file-level)
    "D104",  # allow missing docstring in public package (__init__.py)
    "D203",  # conflicts with D211
    "D213",  # conflicts with D212
    "ANN101", # `self` type annotation not required
    "ANN102", # `cls` type annotation not required
]
fixable = ["ALL"]
unfixable = ["ERA"]            # never auto-delete commented code
```

### Per-File Rule Overrides

```toml
[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = [
    "S101",   # allow `assert` in tests
    "ANN",    # type annotations optional in tests
    "D",      # docstrings optional in tests
    "PLR2004", # allow magic values in tests
]
"src/**/migrations/*.py" = [
    "N",    # naming rules relaxed for generated migration files
]
"src/**/__init__.py" = [
    "F401",  # allow unused imports in __init__.py (re-exports)
]
```

---

## Mypy Type Checking

### Commands
```bash
mypy src/                     # type-check the src directory
mypy src/ --strict            # enable all optional error codes
mypy src/ --ignore-missing-imports  # suppress missing stub warnings
mypy src/ --html-report reports/mypy/  # generate HTML report
```

### Configuration (in `pyproject.toml`)

```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_any_generics = true
check_untyped_defs = true
disallow_untyped_decorators = true
warn_redundant_casts = true
warn_unused_ignores = true
no_implicit_reexport = true
namespace_packages = true
show_error_codes = true

# Per-module overrides for third-party libraries without stubs
[[tool.mypy.overrides]]
module = [
    "pdfplumber.*",
    "reportlab.*",
    "questionary.*",
    "schedule.*",
]
ignore_missing_imports = true
```

---

## Common Lint Errors and Fixes

### `B006` — Mutable default argument
```python
# Bad
def add_item(item: str, items: list[str] = []) -> list[str]:
    items.append(item)
    return items

# Good
def add_item(item: str, items: list[str] | None = None) -> list[str]:
    if items is None:
        items = []
    items.append(item)
    return items
```

### `BLE001` — Blind except
```python
# Bad
try:
    result = process()
except:
    pass

# Good
try:
    result = process()
except ValueError as exc:
    logger.error("Processing failed: %s", exc)
```

### `S101` — Assert in non-test code
```python
# Bad (in production code)
assert user is not None

# Good
if user is None:
    raise ValueError("user must not be None")
```

### `UP006` / `UP007` — Use modern type hints (Python 3.10+)
```python
# Bad (old style)
from typing import List, Optional, Union
def process(items: List[str], count: Optional[int] = None) -> Union[str, int]:
    ...

# Good (modern style)
def process(items: list[str], count: int | None = None) -> str | int:
    ...
```

### `ANN001` — Missing function argument annotation
```python
# Bad
def calculate(income, rate):
    return income * rate

# Good
def calculate(income: float, rate: float) -> float:
    return income * rate
```

### `SIM108` — Use ternary instead of if-else block
```python
# Bad
if condition:
    result = "yes"
else:
    result = "no"

# Good
result = "yes" if condition else "no"
```

### `PLR0913` — Too many arguments
```python
# Bad — too many positional args
def create_user(name, email, age, phone, address, city, state):
    ...

# Good — use a dataclass or Pydantic model
from dataclasses import dataclass

@dataclass
class UserData:
    name: str
    email: str
    age: int
    phone: str
    address: str
    city: str
    state: str

def create_user(data: UserData) -> User:
    ...
```

---

## Inline Suppressions

Use sparingly and always include a reason:

```python
result = some_function()  # noqa: S603 -- subprocess call is intentional, input is validated
items: list = []  # type: ignore[assignment]  -- legacy API returns untyped list
```

---

## CI Integration

```yaml
# .github/workflows/lint.yml
- name: Run ruff lint
  run: ruff check . --output-format=github

- name: Run ruff format check
  run: ruff format . --check

- name: Run mypy
  run: mypy src/
```

---

## Lint Checklist

- [ ] `ruff check .` passes with no errors
- [ ] `ruff format . --check` passes (no formatting changes needed)
- [ ] `mypy src/` passes with no errors
- [ ] No bare `# noqa` without a specific rule code
- [ ] No `# type: ignore` without a comment explaining why
- [ ] All public functions have type annotations

---

## See Also

- [`skills/python-formatting.md`](python-formatting.md)
- [`skills/python-testing.md`](python-testing.md)
- [`templates/ruff.toml`](../templates/ruff.toml)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
