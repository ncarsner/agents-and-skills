# profiles/python.md — Python Language Profile

Active profile for repositories using Python as the primary language.
Load this file when `RULES.md` declares `Language: profiles/python.md`.

Sections here correspond to `[LANG:PYTHON]` sections in `RULES.md`.

---

## Package Management

**Rule:** Always use `uv` as the Python package manager. Never use `pip`,
`pip3`, `conda`, `poetry`, or any other package manager.

### Mandatory commands

| Action | Command |
|--------|---------|
| Create virtual environment | `uv venv` |
| Add a runtime dependency | `uv add <package>` |
| Add a dev-only dependency | `uv add --dev <package>` |
| Remove a dependency | `uv remove <package>` |
| Install all dependencies | `uv sync` |
| Regenerate lock file | `uv lock` |
| Install project in editable mode | `uv pip install -e ".[dev]"` |

### Prohibited commands

```bash
# NEVER use these:
pip install <package>
pip3 install <package>
conda install <package>
poetry add <package>
```

### Rationale

`uv` provides deterministic installs via `uv.lock`, is significantly faster
than pip, and is the single source of truth for dependency management across
all projects in this repository.

---

## Python Executable

**Rule:** Always invoke Python using `python3`. Never use `python` (which may
resolve to Python 2 on some systems) or a bare `py` alias.

### Correct usage

```bash
python3 -m pytest              # run tests
python3 -m <package_name>      # run package as module
python3 src/<entry>.py         # run script directly
python3 --version              # verify interpreter version
```

### Prohibited usage

```bash
# NEVER use these:
python script.py
py script.py
```

### Rationale

Using `python3` ensures the correct interpreter is always invoked, regardless
of system-level alias configuration. This prevents silent failures caused by
Python 2 being picked up from `$PATH`.

---

## Code Quality

**Rule:** Every public module, class, function, and method MUST include a
docstring, type hints on all parameters and return values, and inline comments
where the logic is non-obvious.

### Docstrings

Use Google-style docstrings for all public symbols:

```python
def parse_invoice(raw: str, currency: str = "USD") -> dict[str, float]:
    """Parse a raw invoice string into a structured line-item dict.

    Args:
        raw: The raw invoice text as received from the upstream source.
        currency: ISO 4217 currency code. Defaults to "USD".

    Returns:
        A mapping of line-item description to amount in the given currency.

    Raises:
        ValueError: If `raw` is empty or cannot be parsed.
        KeyError: If a required field is missing from the invoice.
    """
```

Rules:
- One-line summary on the first line, followed by a blank line if there are
  additional sections.
- Document every parameter (`Args:`), return value (`Returns:`), and exception
  that can propagate (`Raises:`).
- Private helpers (`_name`) should have at minimum a one-line docstring.

### Type hints

- Annotate every function/method signature, including `self`-less methods and
  standalone functions.
- Use `from __future__ import annotations` at the top of modules that reference
  forward-declared types.
- Prefer built-in generics (`list[str]`, `dict[str, int]`) over `typing.List`
  and `typing.Dict` (Python ≥ 3.9).
- Use `Optional[X]` only for clarity; prefer `X | None` in Python ≥ 3.10.

```python
# Good
def fetch_records(limit: int, offset: int = 0) -> list[dict[str, str]]:
    ...

# Bad — missing annotations
def fetch_records(limit, offset=0):
    ...
```

### Inline comments

- Add a comment above any block of logic that is not immediately obvious from
  reading the code (e.g., algorithmic tricks, regex patterns, bitwise ops).
- Do **not** add comments that merely restate what the code already says.

```python
# Good — explains the "why"
# Retry up to 3 times with exponential back-off to handle transient HTTP 429s.
for attempt in range(MAX_RETRIES):
    ...

# Bad — restates the "what"
# Add 1 to counter
counter += 1
```

### Enforcement

Run the following after every edit:

```bash
ruff format <file_path>        # auto-format
ruff check --fix <file_path>   # auto-fix lint issues
mypy src/                      # verify type correctness
```

---

## Testing and Coverage

**Rule:** All new code MUST be accompanied by tests. The minimum acceptable
coverage is **100%** for new modules; legacy modules must not decrease in
coverage.

### Required practices

- Test files named `test_<module>.py` in the `tests/` directory.
- Test functions named `test_<behavior_under_test>`.
- Use `pytest.fixture` for shared state; use `pytest.mark.parametrize` for
  data-driven cases.
- Mock all external I/O (network, filesystem, database) with `unittest.mock`
  or `pytest-mock`.
- Run the full suite before every PR:

```bash
python3 -m pytest --cov=src --cov-fail-under=100
```

### Prohibited practices

- Do NOT delete or comment out tests to make a build pass.
- Do NOT use `# noqa` or `# type: ignore` to suppress errors without a
  documented reason in the same line or adjacent comment.

---

## Error Handling

**Rule:** Never use bare `except:` clauses. Always catch specific exceptions and
handle or re-raise them with context.

```python
# Good
try:
    result = risky_operation()
except ValueError as exc:
    logger.error("Invalid value in risky_operation: %s", exc)
    raise

# Bad
try:
    result = risky_operation()
except:          # catches KeyboardInterrupt, SystemExit, etc.
    pass
```

### Additional rules

- Use custom exception classes (subclasses of `Exception`) for domain-specific
  errors.
- Always log the exception before re-raising or swallowing it.
- Never silently swallow exceptions unless there is an explicit and documented
  reason.
- Propagate errors upward to a defined error boundary; do not let errors leak
  silently across layers.

---

## Logging and Observability

**Rule:** Use the standard `logging` module (or `structlog` for services) for
all diagnostic output. Never use `print()` in library or service code.

```python
import logging

logger = logging.getLogger(__name__)

# Good
logger.info("Processing %d records", len(records))
logger.warning("Rate limit approaching: %d remaining", remaining)
logger.error("Failed to connect to %s: %s", host, exc)

# Bad
print(f"Processing {len(records)} records")
```

### Log level guidelines

| Level | When to use |
|-------|-------------|
| `DEBUG` | Detailed trace information for development |
| `INFO` | Normal operational events (start, stop, milestone) |
| `WARNING` | Something unexpected that is recoverable |
| `ERROR` | A failure that prevented an operation from completing |
| `CRITICAL` | A failure that requires immediate human attention |

---

## Performance Standards

**Rule:** All agents must design for performance from the start. Performance
regressions introduced by an agent must be identified, documented, and resolved
before the PR is merged.

### Latency Targets

| Workload type | Target | Measurement |
|---------------|--------|-------------|
| Synchronous API endpoint | p95 < 200 ms | Load test at expected peak QPS |
| Background / async task | p95 < 2 s | End-to-end wall time |
| Batch ETL job (per 10 k rows) | < 60 s | Wall time on reference hardware |
| CLI command (interactive) | p95 < 500 ms | Cold-start wall time |

### Memory Limits

| Process type | Soft limit | Hard limit |
|--------------|-----------|-----------|
| API service (per worker) | 256 MB RSS | 512 MB RSS |
| CLI tool | 128 MB RSS | 256 MB RSS |
| Batch job | 1 GB RSS | 4 GB RSS |

Soft limit breach → log a `WARNING`. Hard limit breach → log `ERROR` and halt.

### Approved Profiling Tools

| Tool | Install | Best for |
|------|---------|---------|
| `cProfile` | stdlib | CPU-bound function hotspots |
| `memray` | `uv add --dev memray` | Memory allocation flamegraphs |

Run profiling before claiming a performance fix. Attach the flamegraph to the PR.

### Caching

Approved caching libraries:

| Library | Use case |
|---------|---------|
| `functools.lru_cache` / `functools.cache` | In-process memoization (stdlib) |
| `diskcache` | Persistent cross-process local cache |
| `redis-py` | Distributed cache / message broker |

Do not cache secrets, PII, or session tokens (RULES.md §16). Cache TTLs must be
explicit — never cache indefinitely without a documented reason.

### Regression Escalation

A performance regression must be escalated to a human reviewer when:

- A measured p95 latency increases by >25% vs. the prior release.
- Memory usage increases by >50% vs. the prior release.
- A batch job runtime budget is exceeded by >2×.

Escalation means: open a GitHub issue tagged `perf`, block the PR, and notify
the project owner before merging.
