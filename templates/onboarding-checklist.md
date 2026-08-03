# New Agent Onboarding Checklist

Run this checklist the first time an agent (human or AI) encounters any project
derived from these templates. Complete all items before acting on any task.

---

## Step 1 — Read Core Rules (required, no exceptions)

- [ ] Read `RULES.md` in full. Note which placeholder sections (§14–§18) remain unfilled.
- [ ] Read `CLAUDE.md` — the sole root context file. If agent materials were
      copied into `AGENTS/` (per RULES.md §12), the root `CLAUDE.md` is a
      stub; read `AGENTS/CLAUDE.md` for the full content. Internalize the
      identity, stack, and post-edit checklist.
- [ ] Confirm the Python executable rule: always `python3`, never bare `python`.
- [ ] Confirm the package manager rule: always `uv`, never `pip` or `conda`.

## Step 2 — Load Delegation Context

- [ ] Read `subagents/subagents.md` — identify which registered agents handle which
      domains and what the cross-agent invocation rules are.
- [ ] Read `skills/skills.md` — identify which reference files and slash commands
      are available.

## Step 3 — Survey the Repository

- [ ] Run the following to understand the layout:
      `find . -maxdepth 3 -not -path './.git/*' -not -path './.venv/*' | sort`
- [ ] Read `skills/approved-packages.md`, the authoritative list of what may be used
      (RULES.md §5). Anything absent from it needs human approval before use.
- [ ] Confirm `authorized_libraries.md` exists in the project root. If not, copy from
      `templates/authorized_libraries.md`. It records when each dependency was
      approved and when its 72h cooling period elapses; request human sign-off
      before adding any dependencies.
- [ ] Confirm `.pre-commit-config.yaml` exists. If not, copy from
      `templates/.pre-commit-config.yaml`, then run:
      `uv add --dev pre-commit detect-secrets && pre-commit install`
- [ ] Confirm `.secrets.baseline` exists. If not, run:
      `detect-secrets scan > .secrets.baseline` and commit it.

## Step 4 — Confirm Toolchain

- [ ] Run `uv sync` to install all dependencies.
- [ ] Run `python3 -m pytest -x` to confirm the test suite passes.
- [ ] Run `ruff check .` to confirm no lint errors.
- [ ] Run `mypy src/` to confirm type correctness (if `src/` exists).

## Step 5 — Understand Current State

- [ ] Run `git log --oneline -10` to review recent commits.
- [ ] Run `git status` to confirm a clean working tree.
- [ ] Run `gh issue list --state open` to review open work items.
- [ ] Identify the active branch and its relationship to `main`.

## Step 6 — Declare Scope Before Acting

- [ ] State the task objective in one sentence.
- [ ] Identify which RULES.md sections apply to this task.
- [ ] Identify which registered subagent(s) are relevant.
- [ ] Confirm the task is within scope; escalate to a human if ambiguous.

---

## Quick Reference — Prohibited Actions

| Never do this | Rule |
|---------------|------|
| `pip install` or `conda install` | RULES.md §1 |
| `python script.py` (bare `python`) | RULES.md §2 |
| Commit a secret, API key, or credential | RULES.md §8 |
| Add an unlisted third-party library | RULES.md §5 |
| Commit directly to `main` | RULES.md §6 |
| Set `git config user.name` to an agent identity | RULES.md §6, §13 |
| Use bare `except:` | RULES.md §9 |
| Use `print()` in library or service code | RULES.md §10 |
