# CLI Agent Instructions

This file extends `AGENTS.md` with instructions specific to building
**terminal-based (CLI) applications** in Python. Read root `AGENTS.md` first.

---

## Purpose

CLI agents produce command-line tools that are:

- Installable as standalone executables via `pyproject.toml` entry points
- Self-documenting through `--help` output
- Composable with Unix pipes and standard I/O streams
- Testable without a real terminal (using `CliRunner` or captured I/O)

---

## Recommended Libraries

| Need | Library | Install |
|------|---------|---------|
| Argument parsing (simple) | `argparse` | stdlib |
| Argument parsing (advanced) | `click` | `uv add click` |
| Rich terminal output | `rich` | `uv add rich` |
| Progress bars | `rich.progress` | included with `rich` |
| Interactive prompts | `questionary` | `uv add questionary` |
| Table output | `rich.table` | included with `rich` |
| Config file parsing | `tomllib` | stdlib (3.11+) |
| Environment variables | `python-dotenv` | `uv add python-dotenv` |

---

## Project Structure

```
my-cli-tool/
├── pyproject.toml
├── uv.lock
├── .python-version
├── README.md
├── AGENTS.md
├── src/
│   └── my_cli_tool/
│       ├── __init__.py
│       ├── __main__.py       # enables `python3 -m my_cli_tool`
│       ├── cli.py            # click/argparse entry point(s)
│       ├── core.py           # business logic (no I/O dependencies)
│       └── utils.py          # shared utilities
└── tests/
    ├── __init__.py
    ├── unit/
    │   ├── __init__.py
    │   ├── test_core.py
    │   └── test_utils.py
    └── integration/
        ├── __init__.py
        └── test_cli.py
```

---

## Entry Point Configuration (`pyproject.toml`)

```toml
[project.scripts]
my-tool = "my_cli_tool.cli:main"
```

After `uv pip install -e .`, users can run `my-tool` directly.

---

## Argparse Pattern

```python
"""CLI entry point for my-tool."""

import argparse
import logging
import sys
from pathlib import Path

from my_cli_tool.core import process

logger = logging.getLogger(__name__)


def build_parser() -> argparse.ArgumentParser:
    """Build and return the argument parser."""
    parser = argparse.ArgumentParser(
        prog="my-tool",
        description="One-line description of what this tool does.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  my-tool input.csv --output results/
  my-tool input.csv --verbose --dry-run
        """,
    )
    parser.add_argument("input", type=Path, help="Path to input file")
    parser.add_argument(
        "--output", "-o", type=Path, default=Path("."), help="Output directory"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Enable verbose logging"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Preview changes without writing"
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    """Main entry point. Returns exit code."""
    parser = build_parser()
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    try:
        process(args.input, args.output, dry_run=args.dry_run)
        return 0
    except FileNotFoundError as exc:
        logger.error("Input file not found: %s", exc)
        return 1
    except Exception as exc:  # noqa: BLE001
        logger.error("Unexpected error: %s", exc)
        return 2


if __name__ == "__main__":
    sys.exit(main())
```

---

## Click Pattern

```python
"""CLI entry point using click."""

import logging
from pathlib import Path

import click

from my_cli_tool.core import process

logger = logging.getLogger(__name__)


@click.group()
@click.option("--verbose", "-v", is_flag=True, help="Enable verbose logging")
@click.pass_context
def cli(ctx: click.Context, verbose: bool) -> None:
    """My CLI tool — one-line description."""
    ctx.ensure_object(dict)
    ctx.obj["verbose"] = verbose
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )


@cli.command()
@click.argument("input_file", type=click.Path(exists=True, path_type=Path))
@click.option("--output", "-o", type=click.Path(path_type=Path), default=Path("."))
@click.option("--dry-run", is_flag=True, help="Preview without writing")
@click.pass_context
def run(ctx: click.Context, input_file: Path, output: Path, dry_run: bool) -> None:
    """Process INPUT_FILE and write results to OUTPUT."""
    process(input_file, output, dry_run=dry_run)


def main() -> None:
    """Package entry point."""
    cli(obj={})
```

---

## Testing CLI Commands

```python
"""Integration tests for CLI entry point."""

import pytest
from click.testing import CliRunner
from pathlib import Path

from my_cli_tool.cli import cli


@pytest.fixture
def runner() -> CliRunner:
    """Provide a Click test runner."""
    return CliRunner()


@pytest.fixture
def sample_input(tmp_path: Path) -> Path:
    """Create a temporary input file."""
    f = tmp_path / "input.csv"
    f.write_text("id,value\n1,100\n2,200\n")
    return f


def test_cli_help(runner: CliRunner) -> None:
    """--help should exit 0 and print usage."""
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "Usage:" in result.output


def test_run_command_success(runner: CliRunner, sample_input: Path, tmp_path: Path) -> None:
    """run command should succeed with valid input."""
    result = runner.invoke(cli, ["run", str(sample_input), "--output", str(tmp_path)])
    assert result.exit_code == 0


def test_run_command_dry_run(runner: CliRunner, sample_input: Path, tmp_path: Path) -> None:
    """--dry-run should not write output files."""
    result = runner.invoke(
        cli, ["run", str(sample_input), "--output", str(tmp_path), "--dry-run"]
    )
    assert result.exit_code == 0
    # Verify no files were written
    assert list(tmp_path.iterdir()) == []
```

---

## Standard I/O and Pipes

```python
import sys


def read_stdin_or_file(path: Path | None) -> str:
    """Read from file if given, else from stdin."""
    if path is not None:
        return path.read_text(encoding="utf-8")
    if not sys.stdin.isatty():
        return sys.stdin.read()
    raise ValueError("No input provided: specify a file or pipe data via stdin")
```

---

## Rich Output Patterns

```python
from rich.console import Console
from rich.table import Table
from rich.progress import track

console = Console()


def print_results_table(rows: list[dict]) -> None:
    """Render results as a formatted table."""
    table = Table(title="Results", show_header=True, header_style="bold cyan")
    table.add_column("ID", style="dim")
    table.add_column("Value", justify="right")
    for row in rows:
        table.add_row(str(row["id"]), f"{row['value']:.2f}")
    console.print(table)


def process_with_progress(items: list) -> list:
    """Process items with a progress bar."""
    results = []
    for item in track(items, description="Processing..."):
        results.append(transform(item))
    return results
```

---

## Error Handling and Exit Codes

| Exit Code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | User error (bad arguments, missing file) |
| `2` | Application error (processing failed) |
| `3` | External dependency error (API down, DB unreachable) |

---

## See Also

- [`skills/cli-development.md`](../skills/cli-development.md) — detailed CLI patterns
- [`skills/python-testing.md`](../skills/python-testing.md) — testing cookbook
- [`templates/pyproject.toml`](../templates/pyproject.toml) — starter config
