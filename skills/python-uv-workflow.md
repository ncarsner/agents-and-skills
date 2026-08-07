# Skill: Python uv Workflow

Complete reference for using `uv` as the Python package manager for all
projects. `uv` replaces `pip`, `pip-tools`, `poetry`, `virtualenv`, and `venv`.

---

## Why uv

- 10–100× faster than pip for installs and resolves
- Single tool for venv creation, dependency management, and script running
- Reproducible builds via `uv.lock`
- Compatible with standard `pyproject.toml` (PEP 517/518/621)
- Cross-platform (macOS, Linux, Windows)

---

## Installation

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Via pip (not recommended for primary use)
pip install uv
```

---

## Project Initialization

```bash
# Create a new project from scratch
uv init my-project
cd my-project

# Initialize uv in an existing project directory
uv init

# Specify Python version at init time
uv init --python 3.12
```

This creates:
```
my-project/
├── pyproject.toml
├── .python-version      # pins Python version for this project
├── README.md
└── src/
    └── my_project/
        └── __init__.py
```

---

## Virtual Environment

```bash
# Create venv (auto-detects Python from .python-version or pyproject.toml)
uv venv

# Create venv with a specific Python version
uv venv --python 3.12

# Activate (the venv is at .venv/ by default)
source .venv/bin/activate        # macOS/Linux
.venv\Scripts\activate           # Windows

# uv commands work WITHOUT activating the venv
uv run python script.py          # auto-uses project's venv
```

---

## Dependency Management

### Adding dependencies
```bash
uv add requests                  # add runtime dependency
uv add "requests>=2.28,<3"       # with version constraint
uv add --dev pytest pytest-cov   # -> [dependency-groups] dev (PEP 735)
uv add --group docs mkdocs       # -> [dependency-groups] docs

# Add an optional RUNTIME feature (published extra, not dev tooling)
uv add --optional excel openpyxl # -> [project.optional-dependencies] excel

# Add with extras
uv add "fastapi[standard]"
uv add "pydantic[email]"
```

### Removing dependencies
```bash
uv remove requests               # remove runtime dependency
uv remove --dev pytest           # remove dev dependency
```

### Syncing the environment
```bash
uv sync                          # project (editable) + dev group, from uv.lock
uv sync --no-dev                 # runtime deps only (production)
uv sync --group docs             # add a named dependency group
uv sync --all-groups             # every dependency group
uv sync --extra excel            # a published runtime extra
```

`uv sync` installs the project itself in editable mode. Never run
`uv pip install -e ".[dev]"`.

### Locking
```bash
uv lock                          # regenerate uv.lock from pyproject.toml
uv lock --upgrade                # upgrade all deps to latest compatible versions
uv lock --upgrade-package requests  # upgrade a single package
```

### Exporting the lock

`uv.lock` stays the source of truth. Export only to feed tools that cannot read
it, such as vulnerability scanners or a non-uv deployment target.

```bash
# requirements.txt with hashes, for pip-audit
uv export --all-groups --no-emit-project \
  --format requirements-txt > audit-requirements.txt

# add --no-hashes only for a legacy pipeline that rejects hash lines

# pylock.toml, the standardized lock interchange format (PEP 751)
uv export --format pylock.toml -o pylock.toml
```

### Listing installed packages
```bash
uv pip list                      # list all installed packages
uv pip show requests             # show details for a specific package
uv pip freeze                    # requirements.txt format output
```

---

## Running Code

```bash
# Run a module using the project's venv
uv run python -m my_package

# Run pytest
uv run pytest

# Run any command in the project's venv context
uv run ruff check .
uv run mypy src/

# Run a script with inline dependencies (no project required)
uv run --with requests fetch.py
```

### Standalone scripts with PEP 723 metadata

A script can declare its own dependencies in a comment header. `uv run` builds
a throwaway environment for it, so no project, venv, or `requirements.txt` is
involved.

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx>=0.27", "rich>=13.0"]
# ///

import httpx
from rich import print
```

```bash
uv run report.py                 # uv reads the header and resolves deps
uv add --script report.py httpx  # add a dependency to the header
```

Prefer this over `uv run --with <pkg>`: the dependency list lives with the
script instead of in shell history.

---

## pyproject.toml Structure

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "What this project does"
readme = "README.md"
requires-python = ">=3.12"
license = "MIT"
license-files = ["LICENSE"]
authors = [{ name = "Nicholas Carsner", email = "nicholascarsner@gmail.com" }]

dependencies = [
    "requests>=2.28",
    "pandas>=2.0",
]

[project.scripts]
my-tool = "my_project.cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/my_project"]

# Dependency groups (PEP 735): local dev tooling, never published.
# NOT [project.optional-dependencies]; extras are for optional runtime
# features consumers opt into via `my-project[extra]`.
[dependency-groups]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "pytest-mock>=3.14",
    "ruff>=0.4",
    "mypy>=1.12",
]
```

The pre-standard `[tool.uv] dev-dependencies` table is deprecated. If a project
still has one, `uv add --dev` keeps writing to it, so migrate the table by hand
and re-run `uv lock` to confirm the resolution is unchanged.

---

## `.python-version` File

Pin the Python version for this project:

```
3.12
```

`uv` reads this file automatically. Also used by `pyenv`.

---

## Common Workflows

### Start a new project
```bash
uv init my-project && cd my-project
uv venv
uv add fastapi uvicorn
uv add --dev pytest pytest-cov ruff mypy
```

### Clone and set up an existing project
```bash
git clone https://github.com/org/repo && cd repo
uv venv
uv sync
```

### Update all dependencies
```bash
uv lock --upgrade
uv sync
uv run pytest                   # verify nothing broke
```

### Add a new feature with its dependency
```bash
uv add pypdf
# ... write code ...
uv run pytest --cov=src --cov-fail-under=100
```

### Run CI checks locally
```bash
uv run ruff check .
uv run ruff format . --check
uv run mypy src/
uv run pytest --cov=src --cov-fail-under=100
```

---

## CI/CD Integration (GitHub Actions)

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          version: "latest"

      - name: Set up Python
        run: uv python install

      - name: Install dependencies
        run: uv sync

      - name: Lint
        run: uv run ruff check . --output-format=github

      - name: Format check
        run: uv run ruff format . --check

      - name: Type check
        run: uv run mypy src/

      - name: Tests with coverage
        run: uv run pytest --cov=src --cov-fail-under=100
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `uv: command not found` | Add `~/.cargo/bin` to `PATH` or reinstall uv |
| Python version not found | Run `uv python install 3.12` |
| Lock file out of sync | Run `uv lock && uv sync` |
| Package conflict | Run `uv lock --upgrade` to resolve |
| Import error after `uv add` | Run `uv sync` to install into venv |

---

## See Also

- [`templates/pyproject.toml`](../templates/pyproject.toml)
- [`templates/.python-version`](../templates/.python-version)
- [uv documentation](https://docs.astral.sh/uv/)
