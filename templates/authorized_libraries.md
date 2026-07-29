# Authorized Third-Party Libraries

Last updated: YYYY-MM-DD
Approved by: <name or team>

This file is the authoritative list of third-party libraries approved for use
in this project. Before adding any library with `uv add`, verify it appears here.
If it does not, follow the proposal process in RULES.md §5.

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

1. Check this file — if the library is listed and its cooling period (see
   below) has elapsed, proceed with `uv add <library>`.
2. If not listed, open a PR with:
   - Library name and PyPI link
   - Proposed version constraint
   - Purpose and justification
   - Output of `python3 -m pip_audit` showing no HIGH or CRITICAL vulnerabilities
3. Do not add to `pyproject.toml` until a human approver has explicitly signed off.
4. Once approved, add to this file with approver name and `Approved date`, then
   set `Earliest commit date` to `Approved date + 72h` (the mandatory cooling
   period, RULES.md §5). Do not run `uv add <library>` or commit the dependency
   until that date. Immediately before committing, re-run `pip_audit` to catch
   any vulnerability disclosed during the cooling window.
