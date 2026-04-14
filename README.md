# agents-and-skills

A reusable library of **AGENTS** and **SKILLS** markdown templates for AI
coding agents working in Python. Designed to be copied into new projects or
referenced directly, these files encode best practices for:

- 🖥️ **Terminal-based (CLI) applications**
- 🌐 **Web development** (FastAPI, Flask, Django)
- 🔤 **Natural language processing** (spaCy, Transformers)
- ⚖️ **Legal and fiscal analysis**
- 📊 **Dashboarding and reporting** (Plotly, Dash, Matplotlib)
- ⚙️ **Process modernization** (ETL, automation, legacy migration)

---

## Quick Start

1. **Copy `AGENTS.md`** to the root of your new project. This is the primary
   instruction file read by AI coding agents.
2. **Copy the relevant `agents/` file** for your domain (e.g.,
   `agents/cli-agent.md` for CLI tools).
3. **Copy `templates/pyproject.toml`** and fill in the `<PLACEHOLDER>` values.
4. **Run `uv venv && uv sync`** to set up the development environment.

---

## Repository Structure

```
agents-and-skills/
│
├── AGENTS.md                          # Root agent instructions (start here)
│
├── agents/                            # Domain-specific agent files
│   ├── cli-agent.md                   # CLI / terminal applications
│   ├── web-dev-agent.md               # Web APIs and applications
│   ├── nlp-agent.md                   # Natural language processing
│   ├── legal-fiscal-agent.md          # Legal and fiscal analysis
│   ├── dashboard-reporting-agent.md   # Dashboards and reports
│   └── process-modernization-agent.md # Process automation and ETL
│
├── skills/                            # Reusable skill files (patterns + recipes)
│   ├── python-formatting.md           # ruff format configuration and usage
│   ├── python-testing.md              # pytest, coverage, mocking cookbook
│   ├── python-linting.md              # ruff lint + mypy configuration
│   ├── python-uv-workflow.md          # uv package manager complete reference
│   ├── cli-development.md             # argparse / click patterns
│   ├── web-development.md             # FastAPI / Flask / Django patterns
│   ├── nlp-processing.md              # spaCy / Transformers / sklearn patterns
│   ├── legal-fiscal-analysis.md       # Decimal arithmetic, tax rules, audit trails
│   ├── dashboarding-reporting.md      # Matplotlib / Plotly / Dash / Excel patterns
│   └── process-modernization.md       # ETL, data quality, change detection
│
└── templates/                         # Ready-to-copy configuration files
    ├── pyproject.toml                 # Full project config (pytest, ruff, mypy)
    ├── pytest.ini                     # Standalone pytest config
    ├── ruff.toml                      # Standalone ruff linter/formatter config
    └── .python-version                # Pin Python 3.12 for uv/pyenv
```

---

## Toolchain Defaults

| Setting | Value |
|---------|-------|
| Python executable | `python3` |
| Package manager | `uv` |
| Linter + formatter | `ruff` |
| Type checker | `mypy` |
| Test runner | `pytest` |
| Coverage target | **100%** (enforced via `pytest-cov`) |

---

## Key Commands

```bash
# Set up a project
uv venv && uv sync

# Run tests with 100% coverage check
python3 -m pytest --cov=src --cov-fail-under=100

# Lint
ruff check .

# Format
ruff format .

# Type check
mypy src/
```

---

## Usage in a New Project

```bash
# 1. Copy the root agent file
cp path/to/agents-and-skills/AGENTS.md ./AGENTS.md

# 2. Copy the domain agent file (example: CLI)
cp path/to/agents-and-skills/agents/cli-agent.md ./agents/cli-agent.md

# 3. Copy the project config template
cp path/to/agents-and-skills/templates/pyproject.toml ./pyproject.toml
# Then edit pyproject.toml to fill in <PLACEHOLDER> values

# 4. Copy the Python version pin
cp path/to/agents-and-skills/templates/.python-version ./.python-version

# 5. Initialize uv environment
uv venv && uv sync --all-extras
```
