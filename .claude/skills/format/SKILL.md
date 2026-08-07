---
name: format
description: Format and lint the Python project with ruff (format + check --fix). Use when the user asks to format, clean up, or lint Python files.
disable-model-invocation: true
allowed-tools: Bash(ruff *) Bash(git diff *)
---

## Modified Python files
!`git diff --name-only HEAD -- '*.py' 2>/dev/null || echo "(all files — no git context)"`

Run the full format + lint cycle on the project:

```bash
uv run ruff format .
uv run ruff check --fix .
```

Report which files changed and any lint errors that could not be auto-fixed.
If the user passes a path as $ARGUMENTS, scope both commands to that path instead of `.`.

For full ruff configuration reference, see [skills/python-formatting.md](../../../../skills/python-formatting.md) and [skills/python-linting.md](../../../../skills/python-linting.md).
