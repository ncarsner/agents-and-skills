# Authorized Third-Party Libraries

Last updated: YYYY-MM-DD
Approved by: <name or team>

This file is this project's **approval record**: when each third-party library
was approved, by whom, and the earliest date it may be committed. It is not the
authority on what is permitted.

What may be used is decided by `skills/approved-packages.md` (RULES.md §5). A
library must appear there first; this file then records its approval date and
the `Earliest commit date` that enforces the §5 cooling period. A library listed
here but absent from `skills/approved-packages.md` is not authorized, and that
row is a defect to be resolved, not a grant.

The standard library needs no row here.

---

## Runtime Dependencies

| Library | Version constraint | Purpose | Approved by | Approved date | Earliest commit date |
|---------|--------------------|---------|-------------|----------------|----------------------|
| | | | | | |

---

## Development Dependencies

| Library | Version constraint | Purpose | Approved by | Approved date | Earliest commit date |
|---------|--------------------|---------|-------------|----------------|----------------------|
| pytest | >=8.0 | Test runner | <name> | YYYY-MM-DD | YYYY-MM-DD |
| pytest-cov | >=5.0 | Coverage reporting | <name> | YYYY-MM-DD | YYYY-MM-DD |
| pytest-mock | >=3.14 | Mocking fixtures | <name> | YYYY-MM-DD | YYYY-MM-DD |
| ruff | >=0.4 | Linter and formatter | <name> | YYYY-MM-DD | YYYY-MM-DD |
| mypy | >=1.10 | Static type checker | <name> | YYYY-MM-DD | YYYY-MM-DD |
| pre-commit | >=3.0 | Pre-commit hook runner | <name> | YYYY-MM-DD | YYYY-MM-DD |
| detect-secrets | >=1.4 | Secret pattern scanning | <name> | YYYY-MM-DD | YYYY-MM-DD |

---

## Proposal Process

See RULES.md §5 for the full authorization process. Summary:

1. Check `skills/approved-packages.md` first: that decides whether the library
   is permitted at all. Then check this file. If it is listed in both and the
   cooling period (see below) has elapsed, proceed with `uv add <library>`.
2. If it is listed in `skills/approved-packages.md` but not here, this project
   has not adopted it yet: record it per step 4 and serve the cooling period.
3. If it is absent from `skills/approved-packages.md`, open a PR with:
   - Library name and PyPI link
   - Proposed version constraint
   - Purpose and justification
   - Output of `python3 -m pip_audit` showing no HIGH or CRITICAL vulnerabilities
4. Do not add to `pyproject.toml`, or to `skills/approved-packages.md`, until a
   human approver has explicitly signed off. Amending the authoritative list is
   a human decision.
5. Once approved, add to this file with approver name and `Approved date`, then
   set `Earliest commit date` to `Approved date + 72h` (the mandatory cooling
   period, RULES.md §5). Do not run `uv add <library>` or commit the dependency
   until that date. Immediately before committing, re-run `pip_audit` to catch
   any vulnerability disclosed during the cooling window.
