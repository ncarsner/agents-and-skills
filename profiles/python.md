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
| Add to a named dependency group | `uv add --group <group> <package>` |
| Remove a dependency | `uv remove <package>` |
| Install project and default groups | `uv sync` |
| Install a specific group | `uv sync --group <group>` |
| Regenerate lock file | `uv lock` |
| Export pinned requirements | `uv export --all-groups --no-emit-project --format requirements-txt` |

`uv sync` installs the project itself in editable mode. There is no separate
editable-install step.

### Prohibited commands

```bash
# NEVER use these:
pip install <package>
pip3 install <package>
conda install <package>
poetry add <package>
uv pip install -e ".[dev]"   # pip shim; dev deps belong in a dependency group
```

### Dependency groups vs. optional dependencies

Declare development dependencies in `[dependency-groups]` (PEP 735), never in
`[project.optional-dependencies]` and never in the pre-standard
`[tool.uv] dev-dependencies` table.

```toml
# Correct: local-only, not published in package metadata
[dependency-groups]
dev = ["pytest>=8.0", "ruff>=0.4", "mypy>=1.12"]

# Wrong: deprecated pre-standard form
[tool.uv]
dev-dependencies = [...]
```

| Table | Purpose |
|-------|---------|
| `[dependency-groups]` | Local development and CI tooling. Not published to an index. |
| `[project.optional-dependencies]` | Optional *runtime* features consumers opt into via `package[extra]`. |

Dev tooling is never a published extra. Reserve extras for features a consumer
of the package can actually enable.

### Rationale

`uv` provides deterministic installs via `uv.lock`, is significantly faster
than pip, and is the single source of truth for dependency management across
all projects in this repository. `[dependency-groups]` is the standard
(PEP 735) replacement for tool-specific dev-dependency tables.

---

## Python Executable

**Rule:** Always invoke Python and its tooling through `uv run`. Never call a
bare `python`, `python3`, or `py` from `$PATH`.

### Correct usage

```bash
uv run pytest                  # run tests
uv run python -m <package>     # run package as module
uv run ruff check .            # run a dev-group tool
uv run python --version        # verify interpreter version
```

### Standalone scripts

For a one-off script outside a project, declare its dependencies inline with
PEP 723 metadata and run it directly. `uv` builds the environment on demand,
so no virtual environment or `requirements.txt` is needed.

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx>=0.27"]
# ///

import httpx
```

```bash
uv run report.py               # uv reads the PEP 723 header
```

### Prohibited usage

```bash
# NEVER use these:
python script.py
py script.py
python3 -m pytest              # may resolve outside the project environment
```

### Rationale

`uv run` guarantees the project's locked environment and pinned interpreter,
so a command behaves identically on every machine and in CI. A bare `python3`
resolves against `$PATH` and can silently pick up a system interpreter with a
different version and different packages installed.

PEP 668 marks system Python installations as externally managed precisely
because installing into them is unsafe. Routing every invocation through
`uv run` means the project never touches one.

---

## Code Quality

**Rule:** Every public module, class, function, and method under `src/` MUST
include a docstring, type hints on all parameters and return values, and
inline comments where the logic is non-obvious.

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

This rule is enforced, not advisory. The project ruff config selects the `D`
(pydocstyle) rule set with `convention = "google"`, so a missing or malformed
docstring fails `ruff check`. A config that ignores `D1xx` codes without
selecting `D` enforces nothing.

**Scope: `src/`.** The rule exists to protect the package's public API, so that
is where it is enforced. `tests/` is already exempt via `per-file-ignores` in
`templates/pyproject.toml` and `templates/ruff.toml`.

The CI examples in `skills/python-linting.md` and `skills/python-formatting.md`
run `ruff check .` from the repository root, so a project that also keeps
Python outside `src/` and `tests/` (`scripts/`, `noxfile.py`, `conftest.py`,
`docs/conf.py`) will see `D` fire there too. None of that is public API. Add
what the project actually has, rather than carrying entries for a layout it
does not use:

```toml
[tool.ruff.lint.per-file-ignores]
"scripts/**/*.py" = ["D"]
"noxfile.py"      = ["D"]
"conftest.py"     = ["D"]
"docs/conf.py"    = ["D"]
```

The templates deliberately ship none of these. An unused ignore is its own kind
of noise, and it hides the moment a directory starts holding real API.

### Type hints

Baseline interpreter is **Python 3.12** (`.python-version`, `requires-python`,
ruff `target-version`, and mypy `python_version` all state 3.12). Write for that
version without compatibility hedges.

- Annotate every function/method signature, including `self`-less methods and
  standalone functions.
- Use built-in generics: `list[str]`, `dict[str, int]`, `tuple[int, ...]`
  (PEP 585). `typing.List`, `typing.Dict`, `typing.Tuple`, and `typing.Set` are
  prohibited.
- Use `X | None` and `X | Y` (PEP 604). `typing.Optional` and `typing.Union` are
  prohibited.

```python
# Good
def fetch_records(limit: int, offset: int = 0) -> list[dict[str, str]]:
    ...

# Bad — missing annotations
def fetch_records(limit, offset=0):
    ...

# Bad: legacy typing aliases
def fetch_records(limit: int) -> List[Optional[Dict[str, str]]]:
    ...
```

#### Deferred annotations

Do **not** add `from __future__ import annotations` by default.

The import turns every annotation into a string, which breaks any library that
reads annotations at runtime: Pydantic models, FastAPI route signatures,
`dataclasses` with resolved field types, and anything calling
`typing.get_type_hints()` on a type it cannot resolve from the module namespace.
PEP 563 (which introduced the import) is Superseded, and PEP 649/749 make
deferred evaluation the default in Python 3.14 without it.

For a genuine import cycle, quote the individual annotation instead:

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from myapp.billing import Invoice


def summarize(invoice: "Invoice") -> str:
    """Render a one-line summary of an invoice."""
```

The quotes are mandatory here. Without the blanket future import, an unquoted
`Invoice` in a signature raises `NameError` at import time, because the
`TYPE_CHECKING` block never executed. Coverage configs exclude
`if TYPE_CHECKING:` blocks, so this pattern is common and the failure is easy
to introduce.

Add the future import to a specific module only when that module has a cycle
that quoting cannot resolve, and note the reason in a comment.

#### Modern typing constructs (available, not mandatory)

Python 3.12 supports these. Use them where they read more clearly than the
older spelling; none is required.

| Construct | PEP | Use for |
|-----------|-----|---------|
| `def f[T](x: T) -> T`, `class Box[T]`, `type Alias = ...` | 695 | Generics without a module-level `TypeVar` |
| `**kwargs: Unpack[ParamsDict]` | 692 | Precisely typing `**kwargs` |
| `@override` | 698 | Marking an intentional base-class override |

PEP 695 requires `mypy>=1.12`, which is the floor set in the project template.
Runtime introspection of `type` aliases is still uneven across libraries, so
prefer explicit `TypeVar` in code that reflects over its own annotations.

### Distributing types (`py.typed`)

Any package that is installed or published MUST ship a `py.typed` marker so
downstream type checkers use its inline annotations (PEP 561). Without it, an
otherwise fully annotated package is treated as untyped by consumers.

```
src/<package_name>/py.typed      # empty file
```

With the standard `src/` layout and hatchling's
`packages = ["src/<package_name>"]`, the marker is included in the wheel
automatically. No extra build configuration is required.

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
uv run ruff format <file_path>        # auto-format
uv run ruff check --fix <file_path>   # auto-fix lint issues
uv run mypy src/                      # verify type correctness
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
uv run pytest --cov=src --cov-fail-under=100
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

### Exception chaining

When translating an exception into a domain-specific type, always chain it with
`raise ... from exc` (PEP 3134). This preserves the original traceback under
"The above exception was the direct cause of the following exception". A bare
`raise NewError(...)` inside an `except` block reports the original as an
incidental "During handling of the above exception", which reads as a bug in the
handler rather than the real cause.

```python
# Good: cause is explicit
try:
    payload = json.loads(raw)
except json.JSONDecodeError as exc:
    raise InvoiceParseError(f"malformed invoice payload: {exc}") from exc

# Deliberately suppressing the cause is also explicit
except LookupError:
    raise InvoiceParseError("unknown invoice schema") from None
```

### Additional rules

- Use custom exception classes (subclasses of `Exception`) for domain-specific
  errors.
- Always log the exception before re-raising or swallowing it.
- Never silently swallow exceptions unless there is an explicit and documented
  reason.
- Propagate errors upward to a defined error boundary; do not let errors leak
  silently across layers.
- Attach diagnostic context with `exc.add_note(...)` (PEP 678) rather than
  rebuilding the exception message, when re-raising the same exception type.
- For concurrent fan-out where several tasks can fail independently
  (`asyncio.TaskGroup`, batch workers), raise an `ExceptionGroup` and handle it
  with `except*` (PEP 654). Do not discard all but the first failure.

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

### Runtime Budgets

Batch jobs must declare a runtime budget in the task spec before starting, in
addition to meeting the reference target in the table above.

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
