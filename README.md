# agents-and-skills

A reusable library of **AGENTS** and **SKILLS** markdown reference files for AI
coding agents working in Python. Provides human- and machine-readable files
that coding agents can read to understand how to behave, what skills are
available, and how to extend the system. Designed to be copied into new
projects or referenced directly, these files encode best practices for:

- 🖥️ **Terminal-based (CLI) applications**
- 🌐 **Web development** (FastAPI, Flask, Django)
- 🔤 **Natural language processing** (spaCy, Transformers)
- ⚖️ **Legal and fiscal analysis**
- 📊 **Dashboarding and reporting** (Plotly, Dash, Matplotlib)
- ⚙️ **Process modernization** (ETL, automation, legacy migration)

---

## Repository Structure

```
agents-and-skills/
│
├── AGENTS.md                          # Root agent instructions (start here)
├── RULES.md                           # Mandatory compliance rules for all agents
│
├── agents/                            # Agent protocol and domain-specific guides
│   ├── agents.md                      # Base agent protocol all agents must follow
│   ├── cli-agent.md                   # CLI / terminal applications
│   ├── web-dev-agent.md               # Web APIs and applications
│   ├── nlp-agent.md                   # Natural language processing
│   ├── legal-fiscal-agent.md          # Legal and fiscal analysis
│   ├── dashboard-reporting-agent.md   # Dashboards and reports
│   └── process-modernization-agent.md # Process automation and ETL
│
├── skills/                            # Skill registry and reusable patterns
│   ├── skills.md                      # Skill registry, invocation contract, and templates
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

## Getting Started

### Reading the References

Agents should load and internalize these files before executing any task:

1. `agents/agents.md` — defines the base agent protocol all agents must follow.
2. `RULES.md` — mandatory compliance rules every agent must obey.
3. `skills/skills.md` — lists all registered skills with their input/output contracts.
4. `AGENTS.md` — Python-specific toolchain defaults, coding standards, and domain links.

### Adding a New Agent

Follow the template at the bottom of `agents/agents.md` and create a new file in the `agents/` directory:

```
agents/
└── <agent-name>.md
```

### Adding a New Skill

Add an entry to the skill registry in `skills/skills.md` following the template at the bottom of that file, then create a corresponding detail file in `skills/`.

---

## Quick Start (Python Projects)

1. **Copy `AGENTS.md`** to the root of your new project.
2. **Copy the relevant `agents/` file** for your domain (e.g., `agents/cli-agent.md`).
3. **Copy `templates/pyproject.toml`** and fill in the `<PLACEHOLDER>` values.
4. **Run `uv venv && uv sync`** to set up the development environment.

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
