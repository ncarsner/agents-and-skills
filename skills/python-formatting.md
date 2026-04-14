# Skill: Python Formatting

Reusable patterns and configuration for consistent Python code formatting using
`ruff format` (Black-compatible). Apply this skill to every Python project.

---

## Tool: `ruff format`

`ruff format` is a Black-compatible formatter built into the `ruff` tool. It
enforces consistent style automatically with zero configuration required
for defaults. Use it instead of maintaining separate `black` and `isort` tools.

### Install
```bash
uv add --dev ruff
```

### Usage
```bash
ruff format .               # format all Python files in place
ruff format src/ tests/     # format specific directories
ruff format . --check       # exit non-zero if any file would change (CI)
ruff format path/to/file.py # format a single file
```

---

## Configuration (add to `pyproject.toml`)

```toml
[tool.ruff]
line-length = 88              # Black-compatible default
target-version = "py311"      # minimum supported Python version
src = ["src"]                 # treat src/ as first-party for import ordering

[tool.ruff.format]
quote-style = "double"        # "double" or "single"
indent-style = "space"        # "space" or "tab"
magic-trailing-comma = true   # respect trailing commas in collections
line-ending = "auto"          # "auto", "lf", or "crlf"
```

---

## Import Sorting

`ruff` handles import sorting via the `isort` rules (rule prefix `I`). Enable
it in the lint section:

```toml
[tool.ruff.lint]
select = ["I"]                # enable isort rules
```

Import order enforced by ruff:
1. `__future__` imports
2. Standard library
3. Third-party libraries
4. First-party (your package)
5. Local relative imports

```python
# Correct import order
from __future__ import annotations

import os
import sys
from pathlib import Path

import pandas as pd
import requests

from my_package.utils import helper
from .models import MyModel
```

---

## Pre-commit Hook

Add to `.pre-commit-config.yaml` to format on every commit:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.0
    hooks:
      - id: ruff-format
        args: []
      - id: ruff
        args: [--fix]
```

Install pre-commit hooks:
```bash
uv add --dev pre-commit
pre-commit install
```

---

## CI Integration

Add a formatting check step to your GitHub Actions workflow:

```yaml
- name: Check formatting
  run: ruff format . --check
```

---

## Formatting Rules (Quick Reference)

| Pattern | Formatted Style |
|---------|----------------|
| String quotes | Double quotes `"` |
| Trailing commas | Added to multi-line collections |
| Line length | Wrapped at 88 characters |
| Blank lines | 2 between top-level defs, 1 between methods |
| Magic trailing comma | Preserves intentional `[a, b, c,]` expansion |

---

## Common Formatting Examples

### Function signatures
```python
# Before
def my_func(arg1,arg2,arg3="default",*args,**kwargs):
    pass

# After (ruff format)
def my_func(arg1, arg2, arg3="default", *args, **kwargs):
    pass
```

### Long function calls
```python
# Before
result = my_function(very_long_argument_one, very_long_argument_two, very_long_argument_three, keyword=True)

# After (ruff format)
result = my_function(
    very_long_argument_one,
    very_long_argument_two,
    very_long_argument_three,
    keyword=True,
)
```

### Dictionary literals
```python
# After (ruff format with magic trailing comma)
config = {
    "key1": "value1",
    "key2": "value2",
    "key3": "value3",
}
```

---

## See Also

- [`skills/python-linting.md`](python-linting.md)
- [`templates/ruff.toml`](../templates/ruff.toml)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
