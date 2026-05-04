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
uv run python3 script.py         # auto-uses project's venv
```

---

## Dependency Management

### Adding dependencies
```bash
uv add requests                  # add runtime dependency
uv add "requests>=2.28,<3"       # with version constraint
uv add --dev pytest pytest-cov   # dev-only dependencies
uv add --optional dev mypy ruff  # optional dependency group

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
uv sync                          # install all deps from uv.lock
uv sync --no-dev                 # install only runtime deps (production)
uv sync --extra dev              # install with optional dev group
```

### Locking
```bash
uv lock                          # regenerate uv.lock from pyproject.toml
uv lock --upgrade                # upgrade all deps to latest compatible versions
uv lock --upgrade-package requests  # upgrade a single package
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
# Run a script using the project's venv
uv run python3 src/my_package/__main__.py

# Run pytest
uv run python3 -m pytest

# Run any command in the project's venv context
uv run ruff check .
uv run mypy src/

# Run a script with inline dependencies (no project required)
uv run --with requests python3 fetch.py
```

---

## pyproject.toml Structure

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "What this project does"
readme = "README.md"
requires-python = ">=3.12"
license = { text = "MIT" }
authors = [{ name = "Nicholas Carsner", email = "nicholascarsner@gmail.com" }]

dependencies = [
    "requests>=2.28",
    "pandas>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "pytest-mock>=3.14",
    "ruff>=0.4",
    "mypy>=1.10",
]

[project.scripts]
my-tool = "my_project.cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/my_project"]

[tool.uv]
dev-dependencies = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "ruff>=0.4",
    "mypy>=1.10",
]
```

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
python3 -m pytest               # verify nothing broke
```

### Add a new feature with its dependency
```bash
uv add pypdf
# ... write code ...
python3 -m pytest --cov=src --cov-fail-under=100
```

### Run CI checks locally
```bash
uv run ruff check .
uv run ruff format . --check
uv run mypy src/
uv run python3 -m pytest --cov=src --cov-fail-under=100
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
        run: uv sync --all-extras

      - name: Lint
        run: uv run ruff check . --output-format=github

      - name: Format check
        run: uv run ruff format . --check

      - name: Type check
        run: uv run mypy src/

      - name: Tests with coverage
        run: uv run python3 -m pytest --cov=src --cov-fail-under=100
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
