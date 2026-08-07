# Skill: CLI Development

Patterns and recipes for building robust terminal-based (CLI) applications in
Python.

---

## Choosing an Argument Parser

| Use Case | Library |
|----------|---------|
| Simple scripts with a few flags | `argparse` (stdlib) |
| Multi-command tools with groups | `argparse` subparsers |
| Quick prototypes | `argparse` |
| Pre-existing Click codebase | `click` (see Click Patterns below) |

`argparse` is the default for new CLI tools here: it is stdlib, so it adds no
dependency to authorize under RULES.md §5. The Click section is retained for
codebases that already use it.

The binding rules that apply to CLI work live in `RULES.md`: §9 error handling,
§10 logging, §14 CLI latency and memory budgets, and §15 the `NO_COLOR`
requirement. Everything in this file is a recipe for meeting them, not a rule in
its own right.

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

## Validating Arguments at the Boundary

`argparse` accepts any string it is not told to reject. Push validation into
`type=` and `choices=` so bad input fails as a usage message, not as a
traceback from deep in the logic layer.

```python
import argparse
from enum import Enum
from pathlib import Path


def existing_file(raw: str) -> Path:
    """Parse a CLI argument into a path that is known to exist."""
    path = Path(raw)
    if not path.is_file():
        raise argparse.ArgumentTypeError(f"not a file: {raw}")
    return path


def writable_dir(raw: str) -> Path:
    """Parse a CLI argument into a directory that can be written to."""
    path = Path(raw)
    if not path.is_dir() or not os.access(path, os.W_OK):
        raise argparse.ArgumentTypeError(f"not a writable directory: {raw}")
    return path


class Format(Enum):
    """Supported output formats."""

    csv = "csv"
    json = "json"

    def __str__(self) -> str:            # controls how choices render in --help
        return self.value


parser.add_argument("input", type=existing_file, help="Path to the input file")
parser.add_argument("--output", "-o", type=writable_dir, default=Path("."))
parser.add_argument(
    "--format",
    type=Format,
    choices=list(Format),
    default=Format.csv,
    help="Output format (default: %(default)s)",
)
```

`ArgumentTypeError` is rendered by `argparse` as `error: argument input: not a
file: ...` followed by usage, and exits `2`. See `## Environment Variable
Defaults` for the env layer of option resolution.

### Exit code collision

`parser.error()`, an unknown option, and a failed `type=` callable all exit
`2`, which is `EXIT_APP_ERROR` in `## Exit Code Standards`. Either reserve `2`
for usage errors and move application failures to another code, or override
`ArgumentParser.error` to exit `1`. Do not ship both meanings undocumented.

---

## Color That Honors NO_COLOR

RULES.md §15 requires output to stay readable with color disabled. Hand-rolled
ANSI ignores both `NO_COLOR` and non-terminal output; `rich.console.Console`
honors both and strips styling while keeping the text.

```python
from rich.console import Console

stdout_console = Console()               # results
stderr_console = Console(stderr=True)    # diagnostics


def fail(message: str) -> None:
    """Print an error that stays readable under NO_COLOR=1."""
    stderr_console.print(f"[red]Error:[/red] {message}")   # "Error:" carries the meaning
```

```python
print(f"\033[31m{msg}\033[0m")           # NEVER: raw ANSI, ignores NO_COLOR
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

### Argparse: call main() directly

With `main(argv: list[str] | None = None) -> int`, the whole interface is an
ordinary function. No runner, no subprocess, no `SystemExit`, and every line
stays inside the coverage measurement. Use `capsys` to assert the stream split.

```python
"""Argparse CLI tests: interface."""

import pytest

from my_tool.cli import main
from my_tool.exit_codes import EXIT_EXT_ERROR


def test_help_exits_zero(capsys) -> None:
    """--help should exit 0 and list the options."""
    with pytest.raises(SystemExit) as exc:     # argparse exits on --help
        main(["--help"])
    assert exc.value.code == 0
    assert "--output" in capsys.readouterr().out


def test_upstream_failure_uses_external_exit_code(capsys, monkeypatch) -> None:
    """An unreachable upstream should return 3, not 1 or 2."""
    monkeypatch.setattr("my_tool.core.report.fetch", _raise_upstream)
    assert main(["report", "--since", "2026-01-01"]) == EXIT_EXT_ERROR
    captured = capsys.readouterr()
    assert "Error:" in captured.err            # diagnostics on stderr,
    assert captured.out == ""                  # nothing on stdout


def test_rejects_missing_input_file(capsys) -> None:
    """A bad path should be a usage error, not a traceback."""
    with pytest.raises(SystemExit) as exc:
        main(["process", "/nope/missing.csv"])
    assert exc.value.code == 2
    assert "not a file" in capsys.readouterr().err
```

`--help` and usage errors raise `SystemExit` from inside `argparse` itself, so
those two cases need `pytest.raises`; everything else returns a code normally.

Reserve `subprocess` (the recipe above) for asserting that the installed entry
point and `uv run python -m my_tool` actually work. Business-rule tests should not use
it: a subprocess runs in a separate interpreter, so its lines miss the parent's
coverage data and `monkeypatch` in the test process has no effect on it.

### Asserting NO_COLOR compliance

Color detection only engages on a terminal, so a plain `subprocess.run` proves
nothing: its pipes are not a tty and every library emits plain text. Attach a
pty (stdlib `pty`) to get an honest answer.

```python
import os
import pty
import subprocess
import sys


def run_on_tty(*args: str, **env_extra: str) -> str:
    """Run the tool with stderr on a pty and return what a terminal would see."""
    primary, secondary = pty.openpty()
    proc = subprocess.Popen(
        [sys.executable, "-m", "my_tool", *args],
        stdout=subprocess.DEVNULL,
        stderr=secondary,
        env={**os.environ, **env_extra},
    )
    os.close(secondary)
    chunks = []
    while True:
        try:
            data = os.read(primary, 4096)
        except OSError:
            break
        if not data:
            break
        chunks.append(data)
    os.close(primary)
    proc.wait()
    return b"".join(chunks).decode()


def test_output_is_plain_under_no_color() -> None:
    """RULES.md §15: output must stay readable with color disabled."""
    assert "\x1b[" in run_on_tty("report", "build")            # colors on a tty
    assert "\x1b[" not in run_on_tty("report", "build", NO_COLOR="1")
```

Both assertions matter. The first proves the test can detect color at all; the
second is the §15 requirement. Output routed through `rich.console.Console`
passes both; hand-rolled ANSI passes the first and fails the second, which is
the difference the test exists to catch. Do not substitute `FORCE_COLOR=1` for
the pty: rich gives `FORCE_COLOR` precedence over `NO_COLOR`, so the compliant
path fails too.

The pty helper is POSIX-only. Skip it on Windows with
`@pytest.mark.skipif(os.name == "nt", ...)`.

---

## See Also

- [`agents/cli-agent.md`](../agents/cli-agent.md)
- [`skills/python-testing.md`](python-testing.md)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
