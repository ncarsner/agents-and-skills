---
name: test
description: Run the Python test suite with 100% coverage enforcement. Use when the user asks to run tests, check coverage, or verify the test suite passes.
disable-model-invocation: true
argument-hint: [path-or-pytest-flags]
allowed-tools: Bash(uv run pytest *)
---

Run the full test suite with coverage enforcement.
Additional arguments or paths: $ARGUMENTS

```bash
uv run pytest --cov=src --cov-fail-under=100 --cov-report=term-missing $ARGUMENTS
```

Report: tests passed/failed, coverage percentage, any uncovered lines.
If tests fail, show the failure output and identify the likely cause.
Stop on the first failure (add `-x` if not already in $ARGUMENTS) when debugging.

For pytest patterns, fixtures, and mocking recipes, see [skills/python-testing.md](../../../../skills/python-testing.md).
