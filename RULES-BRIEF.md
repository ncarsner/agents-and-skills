# RULES-BRIEF.md — Session-Start Compliance Reference

One-line summary per section. Load [RULES.md](RULES.md) in full only when the task requires the detail.

**Active framework profile: none. Active domain profile: none.** When [RULES.md](RULES.md) Active Profile declares a `Framework:` or `Domain:` value, load every profile it names at session start alongside [profiles/python.md](profiles/python.md). Both kinds are additive: they add constraints to the sections below, they never replace them, and they stack (a Django service on PostgreSQL declares one of each).

- Framework: [profiles/django.md](profiles/django.md), [profiles/flask.md](profiles/flask.md), [profiles/fastapi.md](profiles/fastapi.md)
- Domain, SQL dialect: [profiles/postgres.md](profiles/postgres.md), [profiles/tsql.md](profiles/tsql.md), [profiles/plsql.md](profiles/plsql.md)

| § | Rule | When to load full section |
|---|------|--------------------------|
| 1 | Package mgmt: `uv` only, no pip/poetry. See [profiles/python.md](profiles/python.md). | Adding/removing deps |
| 2 | Python executable: `python3` via `uv run`. See [profiles/python.md](profiles/python.md). | Env/subprocess issues |
| 3 | Code quality: ruff + mypy + type hints + minimal docstrings. See [profiles/python.md](profiles/python.md). | Code review, new modules |
| 4 | README: update in same commit whenever public-facing behavior changes. | Any feature/CLI/config change |
| 5 | Third-party libs: check `authorized_libraries.md` before adding; stop and ask if unlisted; 72h cooling period before commit once approved. | Adding new dependency |
| 6 | Commits: Conventional Commits format, feature branch only, no agent authorship ever. | All commits/PRs |
| 7 | Testing: pytest, 100% coverage target. See [profiles/python.md](profiles/python.md). | Writing or reviewing tests |
| 8 | Secrets: env vars only, `.env` gitignored, pre-commit + detect-secrets mandatory. | Any credential/config work |
| 9 | Error handling: explicit exception types, no bare except. See [profiles/python.md](profiles/python.md). | Writing error paths |
| 10 | Logging: structured logging, no PII in logs. See [profiles/python.md](profiles/python.md). | Adding log statements |
| 11 | Architecture: External Input -> Validation -> Logic -> I/O -> Output. No layer skipping. | Structural changes |
| 12 | Downstream copies: place agent materials in `AGENTS/`, gitignore it. | Setting up new projects |
| 13 | AI agent conduct: no git identity, escalate ambiguous/destructive actions, least-privilege. | Always active |
| 14 | Performance: CLI p95 < 500ms, memory < 256MB. See [profiles/python.md](profiles/python.md). | Perf-sensitive work |
| 15 | Accessibility/i18n: WCAG 2.1 AA for web UI, NO_COLOR support for CLI. See [RULES.md §15](RULES.md#15-accessibility-and-internationalization). | Web UI or CLI output tasks |
| 16 | Data privacy: classify data first; no PII in logs; retention limits apply. See [RULES.md §16](RULES.md#16-data-privacy-and-compliance). | Any data handling task |
| 17 | Deployment parity: env vars only differ across tiers; CI gates must pass. See [RULES.md §17](RULES.md#17-deployment-and-environment-parity). | Service/deploy tasks |
| 18 | Code review: automated checks before requesting review; PR type determines approvals. See [RULES.md §18](RULES.md#18-code-review-and-approval-workflow). | Opening PRs |

**Always-active non-negotiables (memorize, never skip):**
- No secrets in source (§8)
- No agent git authorship (§6, §13)
- No bare `except` (§9)
- No layer skipping (§11)
- No unlisted third-party libs (§5)
