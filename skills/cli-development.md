# Skill: CLI Development

Patterns and recipes for building robust terminal-based (CLI) applications in
Python.

---

## Choosing an Argument Parser

| Use Case | Library |
|----------|---------|
| Simple scripts with a few flags | `argparse` (stdlib) |
| Multi-command tools with groups | `click` |
| Complex tools needing auto-completion | `click` + `click-completion` |
| Quick prototypes | `argparse` |

---

## Argparse Patterns

### Single-command tool
```python
"""Single-command argparse entry point."""

import argparse
import sys
from pathlib import Path


def build_parser() -> argparse.ArgumentParser:
    """Build the CLI argument parser."""
    parser = argparse.ArgumentParser(
        prog="my-tool",
        description="Transform input data and write results.",
    )
    parser.add_argument(
        "input",
        type=Path,
        help="Path to the input CSV file",
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=Path("output.csv"),
        help="Path for the output file (default: output.csv)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        metavar="N",
        help="Process at most N records",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Print progress to stderr",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    """Entry point. Returns an integer exit code."""
    args = build_parser().parse_args(argv)
    # ... your logic here ...
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

### Subcommand tool
```python
def build_parser() -> argparse.ArgumentParser:
    """Build parser with subcommands."""
    parser = argparse.ArgumentParser(prog="data-tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # `data-tool ingest`
    ingest = subparsers.add_parser("ingest", help="Ingest source data")
    ingest.add_argument("source", type=Path)
    ingest.add_argument("--format", choices=["csv", "json", "excel"], default="csv")

    # `data-tool report`
    report = subparsers.add_parser("report", help="Generate report")
    report.add_argument("--output", "-o", type=Path, default=Path("report.html"))
    report.add_argument("--since", help="Start date (YYYY-MM-DD)")

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command == "ingest":
        return cmd_ingest(args)
    elif args.command == "report":
        return cmd_report(args)
    return 1
```

---

## Click Patterns

### Simple command
```python
import click


@click.command()
@click.argument("input_file", type=click.Path(exists=True, path_type=Path))
@click.option("--output", "-o", type=click.Path(path_type=Path), default="out.csv")
@click.option("--verbose/--no-verbose", default=False)
def process(input_file: Path, output: Path, verbose: bool) -> None:
    """Process INPUT_FILE and write results to OUTPUT."""
    if verbose:
        click.echo(f"Processing {input_file}...")
    # ... logic ...
    click.echo(f"Done. Output written to {output}")
```

### Multi-command group
```python
@click.group()
@click.option("--debug", is_flag=True, envvar="APP_DEBUG")
@click.pass_context
def cli(ctx: click.Context, debug: bool) -> None:
    """My Data Tool."""
    ctx.ensure_object(dict)
    ctx.obj["debug"] = debug


@cli.command()
@click.pass_context
def status(ctx: click.Context) -> None:
    """Show system status."""
    debug = ctx.obj["debug"]
    click.echo(f"Debug mode: {debug}")
```

---

## Logging Setup

```python
"""Standard logging configuration for CLI tools."""

import logging
import sys


def configure_logging(verbose: bool = False, log_file: Path | None = None) -> None:
    """Configure root logger for CLI use.

    Args:
        verbose: If True, set level to DEBUG. Otherwise INFO.
        log_file: If provided, also write logs to this file.
    """
    level = logging.DEBUG if verbose else logging.INFO
    handlers: list[logging.Handler] = [
        logging.StreamHandler(sys.stderr),
    ]
    if log_file is not None:
        log_file.parent.mkdir(parents=True, exist_ok=True)
        handlers.append(logging.FileHandler(log_file, encoding="utf-8"))

    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=handlers,
    )
```

---

## Progress Reporting

### Rich progress bar
```python
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TimeElapsedColumn


def process_items_with_progress(items: list) -> list:
    """Process items with a visual progress bar."""
    results = []
    with Progress(
        SpinnerColumn(),
        TextColumn("[bold blue]{task.description}"),
        BarColumn(),
        TextColumn("{task.completed}/{task.total}"),
        TimeElapsedColumn(),
    ) as progress:
        task = progress.add_task("Processing...", total=len(items))
        for item in items:
            results.append(transform(item))
            progress.advance(task)
    return results
```

### Simple counter (no rich dependency)
```python
import sys


def progress_print(current: int, total: int, label: str = "Progress") -> None:
    """Print a simple progress counter to stderr."""
    pct = int(100 * current / total) if total else 0
    print(f"\r{label}: {current}/{total} ({pct}%)", end="", file=sys.stderr)
    if current >= total:
        print(file=sys.stderr)  # newline at completion
```

---

## Standard I/O Patterns

```python
"""Read from file or stdin, write to file or stdout."""

import sys
from pathlib import Path


def open_input(path: Path | None):
    """Return file handle for reading — file or stdin."""
    if path is not None:
        return path.open("r", encoding="utf-8")
    if sys.stdin.isatty():
        raise click.UsageError("No input file specified and stdin is a terminal.")
    return sys.stdin


def open_output(path: Path | None):
    """Return file handle for writing — file or stdout."""
    if path is not None:
        path.parent.mkdir(parents=True, exist_ok=True)
        return path.open("w", encoding="utf-8")
    return sys.stdout
```

---

## Environment Variable Defaults

```python
import os
from pathlib import Path

# Read config path from env, fall back to default
CONFIG_PATH = Path(os.environ.get("MY_TOOL_CONFIG", "config/settings.toml"))

# Read API key from env — fail fast if missing
API_KEY = os.environ.get("MY_TOOL_API_KEY")
if not API_KEY:
    raise EnvironmentError(
        "MY_TOOL_API_KEY environment variable is not set. "
        "Export it or add it to your .env file."
    )
```

---

## Exit Code Standards

```python
import sys

EXIT_OK = 0          # success
EXIT_USER_ERROR = 1  # bad arguments, missing file, invalid input
EXIT_APP_ERROR = 2   # unhandled exception in application logic
EXIT_EXT_ERROR = 3   # external service unavailable (API, DB, network)


def main() -> int:
    try:
        run()
        return EXIT_OK
    except (ValueError, FileNotFoundError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return EXIT_USER_ERROR
    except RuntimeError as exc:
        print(f"Application error: {exc}", file=sys.stderr)
        return EXIT_APP_ERROR
    except Exception as exc:  # noqa: BLE001
        print(f"Unexpected error: {exc}", file=sys.stderr)
        return EXIT_APP_ERROR


if __name__ == "__main__":
    sys.exit(main())
```

---

## Testing CLI Tools

```python
"""CLI integration tests using Click's CliRunner or subprocess."""

import subprocess
import sys

from click.testing import CliRunner
from my_tool.cli import cli


def test_cli_help_exits_zero() -> None:
    """--help should print usage and exit 0."""
    runner = CliRunner()
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "Usage:" in result.output


def test_cli_via_subprocess(tmp_path) -> None:
    """Tool should be runnable as a module."""
    input_file = tmp_path / "input.csv"
    input_file.write_text("a,b\n1,2\n")
    result = subprocess.run(
        [sys.executable, "-m", "my_tool", str(input_file)],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
```

---

## See Also

- [`agents/cli-agent.md`](../agents/cli-agent.md)
- [`skills/python-testing.md`](python-testing.md)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
