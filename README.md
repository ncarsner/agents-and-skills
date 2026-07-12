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
- 🧾 **GitHub issue creation** with explicit user-request safeguards

---

## Repository Structure

```
agents-and-skills/
│
├── CLAUDE.md                          # Universal root agent instructions (start here)
├── RULES.md                           # Mandatory compliance rules for all agents
├── CHANGELOG.md                       # Notable changes by date
├── STRATEGY.md                        # Repository strategy notes
├── ralph.sh                           # Agent loop script — runs Claude tasks until success
├── _SCRIPTS/                          # Root-level utility and automation scripts
├── _SOLUTIONS/                        # Root-level solution and reference materials
│
├── .claude/
│   └── skills/                        # Invokable slash commands (Claude Code)
│       ├── ideate/                    # /ideate  — surface risks and edge cases
│       ├── grill-me/                  # /grill-me — interview to shared understanding
│       ├── prd/                       # /prd      — write a Product Requirements Document
│       ├── prd-to-issues/             # /prd-to-issues — convert PRD to GitHub issues
│       ├── ralph/                     # /ralph    — invoke ralph.sh agent loop
│       ├── orient/                    # /orient   — bootstrap agent context
│       ├── format/                    # /format   — ruff format + lint
│       ├── test/                      # /test     — pytest with coverage
│       ├── project-review/            # /project-review — multi-lens project audit
│       ├── stress-test/               # /stress-test — stress-test a design or proposal
│       ├── write-a-skill/             # /write-a-skill — scaffold a new skill
│       └── caveman/                   # /caveman  — ultra-compressed responses
│
├── plans/                             # PRD and task-list files for ralph loops
│   ├── prd.json                       # Active PRD task list (consumed by ralph --prd)
│   └── test-coverage-ralph.sh         # Specialised coverage loop
│
├── subagents/                         # Agent protocol and domain-specific guides
│   ├── subagents.md                   # Base protocol all subagents must follow
│   ├── accounting-agent.md            # Token usage and cost monitoring
│   ├── cli-agent.md                   # CLI / terminal applications
│   ├── containerization-agent.md      # Docker and deployment standards
│   ├── dashboard-reporting-agent.md   # Dashboards and reports
│   ├── data-engineering-agent.md      # ETL and database pipelines
│   ├── legal-fiscal-agent.md          # Compliance and fiscal logic
│   ├── nlp-agent.md                   # Text analysis and LLM processing
│   ├── process-modernization-agent.md # Legacy refactoring
│   ├── security-agent.md              # Security review and hardening
│   ├── testing-agent.md               # Test design and coverage
│   ├── web-dev-agent.md               # Web APIs and applications
│   ├── project-review-accessibility.md        # Accessibility deficiency review
│   ├── project-review-change-manager.md       # Rollout readiness and stakeholder impact
│   ├── project-review-cto.md                  # Strategic C-suite overview
│   ├── project-review-enterprise-architect.md # Architecture standards and integration governance
│   ├── project-review-interoperability.md     # API contracts and integration compatibility
│   ├── project-review-observability.md        # Logging, metrics, tracing, and audit coverage
│   ├── project-review-pm.md                   # Product value and release readiness
│   ├── project-review-scrum-master.md         # Sprint health and Definition of Done
│   ├── project-review-senior-dev.md           # Architectural efficiency review
│   └── project-review-vp.md                   # Risk/reward tradeoff analysis
│
├── skills/                            # Reference docs loaded by agents on demand
│   ├── skills.md                      # Skill registry and slash command index
│   ├── api-integration.md             # HTTP clients, retry, pagination
│   ├── approved-packages.md           # Approved library list
│   ├── cli-development.md             # argparse / click patterns
│   ├── configuration-management.md    # Config file handling
│   ├── dashboarding-reporting.md      # Matplotlib / Plotly / Dash / Excel patterns
│   ├── database-access.md             # Database query patterns
│   ├── error-handling.md              # Exception handling patterns
│   ├── github-issue-creation.md       # Safe GitHub issue creation workflow
│   ├── legal-fiscal-analysis.md       # Decimal arithmetic, tax rules, audit trails
│   ├── logging-observability.md       # Structured logging and observability
│   ├── nlp-processing.md              # spaCy / Transformers / sklearn patterns
│   ├── process-modernization.md       # ETL, data quality, change detection
│   ├── python-formatting.md           # ruff format configuration and usage
│   ├── python-linting.md              # ruff lint + mypy configuration
│   ├── python-testing.md              # pytest, coverage, mocking cookbook
│   ├── python-uv-workflow.md          # uv package manager complete reference
│   └── web-development.md             # FastAPI / Flask / Django patterns
│
├── tools/                             # Deterministic code tools and recipes
│   ├── tools.md                       # Tool registry and usage protocol
│   ├── collections.md                 # Counter, group_by, deduplicate, chunk, bisect
│   ├── datetime.md                    # Parse, format, ranges, timezone conversion
│   ├── file-io.md                     # pathlib read/write, find, atomic write
│   ├── hashing-encoding.md            # SHA-256, HMAC, Base64, UUID, secure tokens
│   ├── itertools-functools.md         # Sliding windows, partition, memoize
│   ├── math-statistics.md             # Clamp, percentile, moving average, summary
│   ├── serialization.md               # JSON, CSV, TOML parsing and serialization
│   └── string-processing.md           # Slugify, regex extraction, normalization
│
└── templates/                         # Ready-to-copy configuration files
    ├── .dockerignore                  # Copy-to-root dockerignore for uv-managed Python projects
    ├── .pre-commit-config.yaml        # Pre-commit hook config using detect-secrets
    ├── .python-version                # Pin Python 3.12 for uv/pyenv
    ├── authorized_libraries.md        # Template for the approved third-party library list
    ├── Dockerfile                     # Two-stage (build/runtime) Dockerfile for uv-managed projects
    ├── epilogue.md                    # Session shutdown protocol — run when closing a session
    ├── onboarding-checklist.md        # New-agent onboarding checklist for downstream projects
    ├── pyproject.toml                 # Full project config (pytest, ruff, mypy)
    ├── pytest.ini                     # Standalone pytest config
    └── ruff.toml                      # Standalone ruff linter/formatter config
```

---

## Workflows

### Idea-to-implementation pipeline

Use the slash command pipeline to take a raw idea all the way to automated
implementation via a series of Claude Code commands:

```
/ideate → /grill-me → /prd → /prd-to-issues → /ralph
```

| Step | Command | What it does |
|------|---------|--------------|
| 1 | `/ideate [idea]` | Surfaces risks, edge cases, and gaps using SWOT, premortem, and 5 Whys |
| 2 | `/grill-me [topic]` | Interviews you one question at a time until reaching shared design understanding |
| 3 | `/prd [project-name]` | Writes a structured PRD to `plans/<project>-prd.md` + task JSON to `plans/<project>-prd.json` |
| 4 | `/prd-to-issues [prd-path]` | Converts the PRD into GitHub issues — previews before creating |
| 5 | `/ralph --prd plans/<project>-prd.json` | Runs the `ralph.sh` agent loop to work through PRD tasks iteratively |

### ralph.sh — agent loop

`ralph.sh` at the repo root is a general-purpose agent loop that runs Claude
against a task until it succeeds (or a max iteration cap is reached).

```bash
# Work through a PRD task list (recommended for pipeline output)
./ralph.sh --prd plans/my-project-prd.json

# Run a one-off task until success
./ralph.sh "refactor src/pipeline.py to use dataclasses"

# Load task from a goal file with an iteration cap
./ralph.sh --goal goal.md --max 10

# Override model or tools
RALPH_MODEL=claude-opus-4-7 ./ralph.sh --prd plans/my-project-prd.json
```

In `--prd` mode the loop reads the task JSON each iteration, works the
highest-priority incomplete task, marks it done, appends to a sibling
`*-progress.txt` file, and commits. It exits automatically when all tasks are
complete, with a safety cap of 20 iterations (override with `--max`).

### Closing a session

When finishing a session, run the shutdown protocol to capture work, update
context files, and leave the repo in a clean state:

```
templates/epilogue.md
```

The protocol covers: session summary, skill updates, context file refresh,
git commit and push, and a final clean-state verification. `CLAUDE.md`, the
sole root context file, links to this file under "On-demand resources →
Session shutdown protocol."

---

## Getting Started

### Reading the References

Agents should load and internalize these files before executing any task:

1. `subagents/subagents.md` — defines the base agent protocol all agents must follow.
2. `RULES.md` — mandatory compliance rules every agent must obey.
3. `skills/skills.md` — lists all registered skills with their input/output contracts.
4. `CLAUDE.md` — Python-specific toolchain defaults, coding standards, and domain links.

### Adding a New Agent

Follow the template at the bottom of `subagents/subagents.md` and create a new file in the `subagents/` directory:

```
subagents/
└── <agent-name>.md
```

### Adding a New Reference Skill

Reference skills are markdown docs in `skills/` loaded by agents on demand — they are not invokable by users.

1. Create `skills/<name>.md` following the pattern of an existing file.
2. Add a row to the reference table in `skills/skills.md`.

### Adding a New Slash Command

Slash commands are invokable skills that live in `.claude/skills/` and appear as `/command-name` in Claude Code. Use `/write-a-skill` to scaffold one interactively, or follow these steps manually:

1. Create `.claude/skills/<name>/SKILL.md` with the required frontmatter (`name`, `description`, `disable-model-invocation`, `allowed-tools`).
2. Add a row to the invokable skills table in `skills/skills.md`.

---

## Quick Start (Python Projects)

1. **Copy this repo's agentic materials** (`CLAUDE.md`, `RULES.md`, `skills/`,
   `subagents/`, etc.) into an `AGENTS/` directory in your new project and add
   `AGENTS/` to `.gitignore` (RULES.md §12).
2. **Copy `templates/context-file-stub.md`** to `CLAUDE.md` at the project
   root — this stub is all Claude Code needs to auto-load; the full content
   lives at `AGENTS/CLAUDE.md`.
3. **Copy the relevant `subagents/` file** for your domain (e.g., `subagents/cli-agent.md`).
4. **Copy `templates/pyproject.toml`** and fill in the `<PLACEHOLDER>` values.
5. **Run `uv venv && uv sync`** to set up the development environment.

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

## Credits

The `/caveman`, `/grill-me`, and `/write-a-skill` skills are adapted from
[Matt Pocock's skills library](https://github.com/mattpocock/skills/tree/main/skills/productivity).

The `/debt-scan`, `/dissent`, `/migrate-draft`, `/preflight`, `/rebuild`, `/refactor-safe`, and `/ship` commands [courtesy of Avi Chawla](https://www.dailydoseofds.com/p/10-must-use-slash-commands-in-claude-code/).
