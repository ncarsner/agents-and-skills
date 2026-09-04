# RULES.md: Agent Compliance Rules

This file defines mandatory rules that **all agents** operating in this
repository (or any project that copies these templates) MUST follow. Rules are
non-negotiable unless explicitly overridden in writing by a human reviewer.

---

## Active Profile

| Declaration | Value |
|-------------|-------|
| Language | [profiles/python.md](profiles/python.md) |
| Framework | none (set to a file in [profiles/](profiles/) when one applies) |
| Domain | none (set to a file in [profiles/](profiles/) when one applies) |

Sections tagged `[LANG:PYTHON]` delegate their full content to the active
language profile. When adapting this template to a different language, replace
the profile file and update this declaration.

Framework profiles are additive. They do not replace any section here; they add
framework-specific constraints on top of the language profile, and name the
sections they extend. Available framework profiles:

| Framework | Profile |
|-----------|---------|
| Django | [profiles/django.md](profiles/django.md) |
| Flask | [profiles/flask.md](profiles/flask.md) |
| FastAPI | [profiles/fastapi.md](profiles/fastapi.md) |

Set `Framework:` to at most one profile. A repository serving two frameworks
should be split, not dual-profiled. A framework profile is warranted only where
a third-party framework imposes constraints the language profile does not
cover; stdlib usage belongs in [profiles/python.md](profiles/python.md) or in
the relevant `skills/` reference, not in a profile of its own.

Domain profiles cover a concern that is orthogonal to the framework, most often
a second language present in the codebase. Available domain profiles:

| Domain | Profile |
|--------|---------|
| SQL dialect: PostgreSQL | [profiles/postgres.md](profiles/postgres.md) |
| SQL dialect: T-SQL (SQL Server) | [profiles/tsql.md](profiles/tsql.md) |
| SQL dialect: PL/SQL (Oracle) | [profiles/plsql.md](profiles/plsql.md) |

`Domain:` accepts a list, but at most one profile per concern; a repository
does not have two primary SQL dialects. Domain profiles are additive in the
same way framework profiles are, and stack with them: a Django service on
PostgreSQL declares both.

---

## Table of Contents

1. [Package Management](#1-package-management-langpython)
2. [Python Executable](#2-python-executable-langpython)
3. [Code Quality: Docstrings, Type Hints, and Comments](#3-code-quality-docstrings-type-hints-and-comments-langpython)
4. [Documentation: Keeping README Current](#4-documentation-keeping-readme-current-core)
5. [Third-Party Library Authorization](#5-third-party-library-authorization-core)
6. [Version Control and Commits](#6-version-control-and-commits-core)
7. [Testing and Coverage](#7-testing-and-coverage-langpython-configurable)
8. [Security and Secrets](#8-security-and-secrets-core)
9. [Error Handling](#9-error-handling-langpython)
10. [Logging and Observability](#10-logging-and-observability-langpython)
11. [Architecture Boundaries](#11-architecture-boundaries-core)
12. [Local-Only Agent Directory](#12-local-only-agent-directory-core)
13. [AI Agent Compliance](#13-ai-agent-compliance-core)
14. [Performance Standards](#14-performance-standards-langpython-configurable)
15. [Accessibility and Internationalization](#15-accessibility-and-internationalization-profileweb-ui)
16. [Data Privacy and Compliance](#16-data-privacy-and-compliance-core-configurable)
17. [Deployment and Environment Parity](#17-deployment-and-environment-parity-profileservice)
18. [Authorship and Attribution](#18-authorship-and-attribution-core)
19. [Code Review and Approval Workflow](#19-code-review-and-approval-workflow-core-configurable)

---

## 1. Package Management `[LANG:PYTHON]`

See [profiles/python.md](profiles/python.md): Package Management section.

---

## 2. Python Executable `[LANG:PYTHON]`

See [profiles/python.md](profiles/python.md): Python Executable section.

---

## 3. Code Quality: Docstrings, Type Hints, and Comments `[LANG:PYTHON]`

See [profiles/python.md](profiles/python.md): Code Quality section.

---

## 4. Documentation: Keeping README Current `[CORE]`

**Rule:** Whenever a code change affects public-facing behavior, adds or removes
a feature, changes a configuration option, or modifies the project's setup
steps, the `README.md` MUST be updated in the same commit or PR.

### What always requires a README update

- Adding or removing a CLI command, API endpoint, or major feature
- Changing setup, installation, or configuration instructions
- Modifying required environment variables or secrets
- Adding or removing a supported Python version
- Changing the project's public interface (imports, function signatures)

### What does NOT require a README update

- Pure refactors with no behavioral change
- Internal test additions or updates
- Dependency version bumps with no user-visible impact
- Fixing a bug whose behavior was never documented

### Process

1. Make your code change.
2. Ask: *"Does this change affect anything a user or operator of this project
   needs to know?"*
3. If yes, update the relevant section(s) of `README.md` before opening a PR.
4. If a new feature deserves its own section, add it under a descriptive heading.

---

## 5. Third-Party Library Authorization `[CORE]`

**Rule:** Before adding any third-party library to a project, verify it is
listed in [skills/approved-packages.md](skills/approved-packages.md). If it is
not listed there, **stop and request human approval** before proceeding.

### The two files, and what each decides

| File | Decides | Scope |
|------|---------|-------|
| [skills/approved-packages.md](skills/approved-packages.md) | **What** may be used. Authoritative | Repository-wide, ships with the bundle |
| `<project-root>/authorized_libraries.md` | **When** a library was approved, by whom, and the earliest date it may be committed | Per project |

`skills/approved-packages.md` is the authority on whether a library is
permitted. A library absent from it is unauthorized, whatever any other file
says. Being listed there does not by itself permit a commit: the cooling period
below still applies, and it is tracked per project.

`authorized_libraries.md` is the per-project record, not a second authority. It
exists so that a project can show when each dependency was approved and when the
cooling period elapsed. Create it from
[templates/authorized_libraries.md](templates/authorized_libraries.md), which
holds the current column set; do not hand-roll the table.

### Process for adding a new library

1. Check [skills/approved-packages.md](skills/approved-packages.md). If the
   library is listed, it is approved for use. Note the `★` entry in its
   category and prefer it over the alternatives listed alongside.
2. Record it in the project's `authorized_libraries.md` with the approver's
   name, `Approved date`, and `Earliest commit date` (approval + 72h), then
   wait out the cooling period below before running `uv add <library>`.
3. If the library is **not** listed in `skills/approved-packages.md`, stop.
   Open a proposal in the PR or issue that includes:
   - Library name and link to PyPI
   - Proposed version constraint
   - Purpose and justification, including why a listed alternative will not do
   - Any known security advisories (check via `pip-audit` or GitHub Advisory DB)
4. **Do not add the library to `pyproject.toml`, and do not add it to
   `skills/approved-packages.md`, until a human approver has explicitly
   approved the proposal.** Amending the authoritative list is a human
   decision, not an agent one.

### Stdlib

The standard library needs no authorization and no entry in either file. A rule
elsewhere in this repository that mandates a stdlib module imposes no §5
obligation.

### Security check (mandatory for new libraries)

Before requesting approval, run a vulnerability scan:

```bash
uv add --dev pip-audit
uv export --all-groups --no-emit-project \
  --format requirements-txt > audit-requirements.txt
uv run pip-audit --requirement audit-requirements.txt --no-deps --disable-pip
```

Any HIGH or CRITICAL vulnerabilities must be resolved or explicitly accepted
before the library may be added.

> **Why not `uv pip compile pyproject.toml`:** that command resolves
> `[project] dependencies` only. Development dependencies live in
> `[dependency-groups]` (PEP 735) and would be silently excluded from the scan.
> `uv export --all-groups` reads `uv.lock`, so it audits exactly what is
> installed, dev tooling included. Delete `audit-requirements.txt` afterwards or
> add it to `.gitignore`; it is a scan artifact, not a lock file.
>
> **Why `--no-deps`:** the export is already a complete, hash-pinned resolution
> from `uv.lock`. Letting pip-audit re-resolve would be redundant and could
> reach the network for versions the lock does not use.
>
> **Why `--disable-pip`:** pip-audit builds a throwaway virtual environment
> containing pip in order to resolve dependencies. It creates that environment
> with `venv.EnvBuilder(with_pip=True)`, whose default is to **copy** the
> interpreter binary rather than symlink it. The interpreters uv installs by
> default are python-build-standalone builds, which are not relocatable that
> way, so the copied interpreter aborts as soon as it runs `ensurepip`:
>
> ```
> subprocess.CalledProcessError: Command '[..., '-m', 'ensurepip', '--upgrade',
> '--default-pip']' died with <Signals.SIGABRT: 6>.
> ```
>
> This is not a local misconfiguration. It is the default path for any project
> following §2, and it makes a mandatory security gate fail closed in a way
> that is easy to mistake for unrelated tooling noise. `--disable-pip` skips
> building that environment.
>
> Nothing is traded away. `--no-deps` already said there is no resolution to
> perform, so the environment is built and then unused. Measured against three
> deliberately vulnerable pins (`jinja2==2.11.3`, `pyyaml==5.3.1`,
> `urllib3==1.26.4`), both forms reported the same 18 advisories, byte for
> byte, in 260 ms with the flag versus 3373 ms without. The speed matters
> because the cooling period below requires re-running this scan immediately
> before every commit.
>
> **Expected output noise:** pip-audit prints `--no-deps is supported, but
> users are encouraged to fully hash their pinned dependencies` on every run.
> That warning fires on the flag alone and never inspects the file, which does
> carry hashes. Ignore it.

### Dependency cooling period (mandatory for new libraries)

Supply-chain attacks often target the gap between approval and deployment.
Once a library is listed in `skills/approved-packages.md` and recorded in the
project's `authorized_libraries.md`, a minimum **72-hour cooling period** must
elapse before the dependency may be committed to production code. The period is
tracked per project, so a library long-listed in `approved-packages.md` still
serves its 72 hours the first time a given project adopts it.

During the cooling period:

- Monitor the library's release history and PyPI page for anomalous activity
  (unexpected new releases, maintainer changes, yanked versions).
- Re-run `pip-audit` immediately before committing, not only at approval time:
  ```bash
  uv export --all-groups --no-emit-project \
    --format requirements-txt > audit-requirements.txt
  uv run pip-audit --requirement audit-requirements.txt --no-deps --disable-pip
  ```
- If a new vulnerability or supply-chain event is detected during the window,
  halt and escalate to the human approver before proceeding.

Record the approval date in `authorized_libraries.md`'s `Approved date` column;
the dependency may not appear in a commit until `Approved date + 72h` has
passed. Hotfixes for an active incident may bypass the cooling period only
with explicit human approval documented in the PR.

---

## 6. Version Control and Commits `[CORE]`

**Rule:** Every commit must be atomic, descriptive, and traceable to a task or
issue.

### Commit message format

Use the [Conventional Commits](https://www.conventionalcommits.org/) standard:

```
<type>(<scope>): <short imperative description>

[optional body]

[optional footer: BREAKING CHANGE, Closes #123, etc.]
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`,
`perf`, `ci`, `build`, `revert`.

### Rules

- Never bundle unrelated changes in a single commit.
- Never commit directly to `main` or `master`: always use a feature branch.
- Every PR must reference an issue (e.g., `Closes #42`).
- Merge commits are preferred over squash when the history is meaningful.

### Authorship

The git author identity must always reflect the human who owns the work. Agents
must never set a git identity or add any attribution to commits or version
control artifacts. See §18, Authorship and Attribution for the full rule.

---

## 7. Testing and Coverage `[LANG:PYTHON]` `[CONFIGURABLE]`

See [profiles/python.md](profiles/python.md): Testing and Coverage section.

> **Override:** The coverage threshold (default 100%) may be adjusted in the
> downstream project's `AGENTS.md` (or `AGENTS/AGENTS.md` per §12) with a
> written rationale.
> Example: `§7 coverage override: 80%, rationale: legacy codebase with untestable I/O layer.`

---

## 8. Security and Secrets `[CORE]`

**Rule:** No secret, credential, API key, token, or password may ever appear in
source code or be committed to the repository.

### Mandatory practices

- Load all secrets via environment variables using `python-dotenv` or
  `os.environ`.
- Add `.env` to `.gitignore` immediately when creating a new project.
- Add `.env-template` that mimics `.env` with expected keys but includes no values.
- Use `parameterized queries` for all database interactions: never use string
  concatenation to build SQL.
- Validate and sanitize **all** external input before it reaches business logic.
- Install `pre-commit` with `detect-secrets` on every new project before the first
  commit. Copy `templates/.pre-commit-config.yaml` to the project root and follow
  the setup steps in `skills/secret-scanning.md`. This is mandatory, not optional.

### If a secret is accidentally committed

This is a security incident. Follow the full remediation playbook in
`skills/secret-scanning.md`. Summary:

1. Immediately rotate/revoke the exposed credential: assume it is compromised.
2. Scrub the history using BFG Repo Cleaner (preferred over `git filter-branch`).
3. Force-push the cleaned history with human approval (see §6).
4. Notify all parties with a clone of the repository.
5. Audit access logs for use of the exposed credential.
6. Document the incident in the project's incident log or PR.

---

## 9. Error Handling `[LANG:PYTHON]`

See [profiles/python.md](profiles/python.md): Error Handling section.

---

## 10. Logging and Observability `[LANG:PYTHON]`

See [profiles/python.md](profiles/python.md): Logging and Observability section.

---

## 11. Architecture Boundaries `[CORE]`

**Rule:** All code in this repository must respect the following layer boundaries.
Never skip a layer or bypass a boundary.

```
External Input (user, file, API) -> Validation -> Logic -> I/O -> Output
```

1. Business logic must not import from the I/O layer directly.
2. I/O layer functions must not contain business logic.
3. Validation must happen before business logic runs.
4. Secrets must never appear in source code: load from environment.

---

## 12. Local-Only Agent Directory `[CORE]`

**Rule:** When copying this repository's agentic materials into a downstream
project, place the full bundle (`AGENTS.md`, `RULES.md`, `skills/`,
`subagents/`, etc.) in an `AGENTS/` directory and immediately add `AGENTS/` to
that project's `.gitignore`. The `AGENTS/` directory must remain untracked and
must never be committed to the downstream repository.

### Root-level stub

`AGENTS.md` is the canonical instruction file and the cross-agent filename
convention. Claude Code auto-loads `CLAUDE.md` and no other name, so a
`CLAUDE.md` stub at the project root is what preserves auto-load. It is the
only stub needed; there is no `GEMINI.md`.

To avoid a second, drifting copy of the full content, the root `CLAUDE.md`
MUST be a short stub only, never the full instructions. Copy
[templates/context-file-stub.md](templates/context-file-stub.md) to
`<project-root>/CLAUDE.md` verbatim:

```markdown
# CLAUDE.md

Stub. Full agent instructions live in `AGENTS/AGENTS.md`. This file exists
only so Claude Code auto-loads something from the project root. Do not add
content here; edit `AGENTS/AGENTS.md` instead.
```

All substantive content, identity, rules, pipeline discipline, and the
resource table, lives exactly once, in `AGENTS/AGENTS.md`. Never duplicate it
at the project root, and never edit the root stub beyond the template above.
Tools that read neither filename (Codex, Gemini CLI, etc.) should be pointed
at `AGENTS/AGENTS.md` explicitly rather than given their own root file.

### File versus directory

`AGENTS.md` the file and `AGENTS/` the directory are different things and are
never in the same place. Downstream, only the directory exists at the root and
the file sits inside it as `AGENTS/AGENTS.md`. In this repository, which has
no `AGENTS/` directory, only the file exists. A root listing therefore shows
one or the other, never both.

### Path references inside bundle documents

A path written inside a bundle document must resolve under both layouts: this
repository, where the materials sit at the root, and a downstream project,
where they sit in `AGENTS/`. Two classes, handled differently:

| Class | Examples | How to write it |
|-------|----------|-----------------|
| Project state, created or updated by an agent | `index.md`, `log.md`, `plans/`, `sessions/*.md` pages, `ralph.sh`, `.claude/` | Bare and root-relative. These live at the project root in both layouts, so a bare path already resolves. |
| Bundle-owned documents | `AGENTS.md`, `RULES.md`, `skills/`, `subagents/`, `sessions/README.md` | A Markdown link resolves correctly on its own, because it resolves relative to the citing document. In prose, name the prefix explicitly: "`sessions/README.md` in the bundle, `AGENTS/sessions/README.md` downstream." |

The failure mode is a bundle-owned document cited as a bare root-relative path
in prose. Downstream that path points at the project root, where the file does
not exist, while the file itself sits one directory down.

Session wiki pages are project state, not bundle content: they are git-tracked
per `sessions/README.md`, and `AGENTS/` must never be committed, so pages
written under `AGENTS/sessions/` would be untracked and lost. Pages belong at
`<project-root>/sessions/`. Only the format spec, `sessions/README.md`, ships
with the bundle.

This rule applies to **downstream copies only**. This repository is the master
source and is exempt: its agent materials (`AGENTS.md`, `RULES.md`, `skills/`,
`subagents/`, etc.) are intentionally tracked at the root level with no
`AGENTS/` directory.

---

## 13. AI Agent Compliance `[CORE]`

**Rule:** All AI agents operating in this repository must observe the following
directives in addition to every other rule in this file.

### Identity and attribution

Never set a git identity or add attribution to commits, PRs, or any version control artifact. See §18, Authorship and Attribution.

### Scope and escalation

- Validate task scope before acting; reject out-of-scope requests with a clear
  explanation.
- Escalate to a human for any ambiguous, potentially destructive, or irreversible
  action. Do not guess or proceed unilaterally.
- Take the least-privilege action necessary: never modify files outside declared
  scope without explicit human approval.

### Session startup

- Re-read `RULES.md` at the start of every session before acting.
- Run `/orient [task]` to load full context; do not skip this step.

### Decision-making and output

- Every non-trivial decision must include a brief rationale in the response.
- Never fabricate context, file paths, or behavior: request clarification instead.
- If a skill invocation fails, log the error and halt unless a fallback is defined.

---

## 14. Performance Standards `[LANG:PYTHON]` `[CONFIGURABLE]`

See [profiles/python.md](profiles/python.md): Performance Standards section.

> **Override:** Performance targets may be adjusted in the downstream project's
> `AGENTS.md` (or `AGENTS/AGENTS.md` per §12) with a written rationale.
> Exceeding a target by >2× requires escalation before shipping.
> Example: `§14 latency override: CLI p95 < 2s, rationale: cold-start includes model load.`

---

## 15. Accessibility and Internationalization `[PROFILE:WEB-UI]`

**Rule:** Any web UI, CLI output, or document produced by an agent must meet
the accessibility and internationalization standards below. These apply when the
project serves end users, not to internal tooling or agent-only pipelines.

### Web UI: WCAG 2.1 AA Compliance

All agent-generated web interfaces must satisfy WCAG 2.1 Level AA:

| Criterion | Requirement |
|-----------|------------|
| Color contrast | Text/background ratio ≥ 4.5:1 (normal text), ≥ 3:1 (large text) |
| Keyboard navigation | All interactive elements reachable and operable via keyboard alone |
| Focus indicators | Visible focus ring on all focusable elements |
| Alt text | Every non-decorative image has a descriptive `alt` attribute |
| Form labels | Every input has an associated `<label>` or `aria-label` |
| Error messages | Errors identified in text, never by color alone |
| Heading structure | Headings used semantically (`h1`→`h2`→`h3`), not for styling |

Required accessibility testing before any web UI ships:

```bash
# axe-core CLI (install once)
npm install -g @axe-core/cli

# Run against a running local server
axe http://localhost:8000 --exit
```

Zero WCAG 2.1 AA violations allowed. Critical and serious violations block the
PR; moderate violations must be documented as known issues with a remediation
timeline.

### CLI: Color and Terminal Output

- Never use color as the sole means of conveying information (e.g., red = error,
  green = success must also include a text label).
- Test with `NO_COLOR=1`: all output must be fully readable in plain text.
- Minimum contrast for terminal color pairs: verify with the ANSI color contrast
  table in `skills/cli-development.md`.

### Internationalization (i18n)

**Locale and timezone:**

```python
from zoneinfo import ZoneInfo

# Always use explicit timezone: never datetime.now() without tz
from datetime import datetime
now = datetime.now(tz=ZoneInfo("UTC"))

# Format for display using babel (locale-aware)
from babel.dates import format_datetime
display = format_datetime(now, locale="en_US")
```

Approved i18n libraries:

| Library | Install | Use for |
|---------|---------|--------|
| `zoneinfo` | stdlib (3.9+) | Timezone-aware datetimes |
| `babel` | `uv add babel` | Locale-aware date, number, currency formatting |
| `gettext` | stdlib | String externalization for translated UIs |

**String externalization rules:**

- All user-visible strings in web UIs must be wrapped in `gettext` calls (`_("...")`).
- Source strings are English; translations live in `locale/<lang>/LC_MESSAGES/`.
- Do not concatenate translated strings: use format strings with named placeholders:
  ```python
  # Correct
  _("Found {count} records").format(count=n)
  # Wrong, breaks in languages with different word order
  _("Found") + f" {n} " + _("records")
  ```
- Dates, numbers, and currency must use `babel` formatters, never f-strings, when
  locale-aware output is required.

### Scope Exceptions

These rules apply only when the project:
- Serves end users via a web browser or terminal interface, **and**
- Targets a locale other than the deployment default (for i18n string rules).

Pure data pipelines, internal CLI tools, and agent-only scripts are exempt from
the WCAG and i18n string externalization requirements, but must still follow
the color/`NO_COLOR` rule for any terminal output.

---

## 16. Data Privacy and Compliance `[CORE]` `[CONFIGURABLE]`

**Rule:** All agents must handle personal and sensitive data according to the
classification level, applicable regulatory frameworks, and the practices defined
in this section. Non-compliance is a blocking defect.

### Data Classification Levels

| Level | Definition | Examples |
|-------|-----------|---------|
| **Public** | Intended for open publication | Documentation, marketing copy |
| **Internal** | Not for external disclosure; no special controls | Internal metrics, system logs |
| **Confidential** | Restricted access; limited retention | Business contracts, employee data |
| **Restricted** | Highest sensitivity; strict controls + audit trail | PII, PHI, credentials, payment data |

Agents must determine the classification level before writing any data handling
code. When in doubt, treat as **Restricted**.

### PII Detection and Handling

Use `subagents/data-collection-agent.md` `PII_PATTERNS` as the baseline field
name detection list. Additional detection rules:

- Scan all inbound column names and JSON keys against the PII pattern list before
  processing.
- Never log Restricted or Confidential data. Redact before logging:
  ```python
  log.info("Processing record", user_id="[REDACTED]")
  ```
- Mask PII in error messages, stack traces, and exception payloads.
- Do not write raw PII to intermediate files, temp dirs, or caches (§14).
- Schema objects (columns, fields) containing PII must carry a `confidential`
  or `restricted` comment/annotation label.

### Anonymization Requirements

Before storing or transmitting Confidential/Restricted data downstream:

| Technique | When to apply |
|-----------|--------------|
| Pseudonymization (hash + salt) | User IDs in analytics pipelines |
| Tokenization | Payment card data |
| Aggregation / generalization | Statistical reporting |
| Suppression | Fields with <5 unique values in aggregate output |

Hashing must use SHA-256 with a per-project salt stored in an environment
variable (never hardcoded). See `tools/hashing-encoding.md`.

### Retention and Deletion

| Classification | Maximum retention | Deletion method |
|---------------|------------------|----------------|
| Public | Indefinite | N/A |
| Internal | 2 years | Standard delete |
| Confidential | 1 year | Secure delete + audit log |
| Restricted | 90 days (or legal minimum) | Secure delete + audit log + confirmation |

> **Override:** Retention windows may be adjusted in the downstream project's
> `AGENTS.md` (or `AGENTS/AGENTS.md` per §12) with written rationale and legal review.
> Example: `§16 retention override: Restricted 1 year, rationale: HIPAA minimum retention requirement.`

Agents must not retain Restricted data beyond the defined window. Implement a
deletion job; do not rely on manual cleanup.

### Audit Trail Requirements

Any operation that reads, transforms, exports, or deletes Restricted data must
emit a structured audit log entry containing:

```python
{
    "event": "data_access",          # or data_export | data_delete | data_transform
    "classification": "restricted",
    "actor": "<agent_id or user_id>",
    "timestamp": "<ISO-8601 UTC>",
    "record_count": <int>,
    "legal_basis": "<purpose>",      # e.g. "consent" | "contract" | "legal_obligation"
    "destination": "<system or path>"
}
```

Audit logs are **Internal** classification and must be retained for 2 years.

### Regulatory Frameworks

| Framework | Scope | Key agent obligations |
|-----------|-------|----------------------|
| **GDPR** | EU residents' personal data | Lawful basis required; data subject rights (access, deletion, portability); 72-hour breach notification |
| **CCPA** | California residents' personal data | Right to know, opt-out of sale, deletion on request |
| **HIPAA** | US protected health information (PHI) | PHI must be encrypted at rest and in transit; minimum necessary access; BAA required with third parties |

When a project processes data under any of these frameworks:

1. Document the applicable framework in the project's `AGENTS.md` (or `AGENTS/AGENTS.md` per §12).
2. Implement the audit trail (above) for all Restricted data operations.
3. Encrypt Restricted data at rest (AES-256) and in transit (TLS 1.2+).
4. Never pass Restricted data to an external LLM API without explicit written
   authorization from the data owner and legal review.

---

## 17. Deployment and Environment Parity `[PROFILE:SERVICE]`

**Rule:** All deployed services must maintain parity between local development,
staging, and production. Differences must be limited to environment variable
values, never to code paths, installed packages, or dependency versions.

### Required Environment Variables per Tier

| Variable | Local | Staging | Production |
|----------|-------|---------|-----------|
| `APP_ENV` | `development` | `staging` | `production` |
| `LOG_LEVEL` | `DEBUG` | `INFO` | `WARNING` |
| `DATABASE_URL` | local connection string | staging DB URL | prod DB URL |
| `SECRET_KEY` | any local value | rotated secret | rotated secret |

All required variables must be defined in `.env-template`. Actual values are
never committed (RULES.md §8).

### Local Development Setup

Use Docker Compose for local multi-service development. See
`skills/containerization.md` for the canonical `docker-compose.yml` pattern.

```bash
docker compose up --build   # start all services
docker compose down         # tear down
```

Container images must pin the base image by digest, never a floating tag:

```dockerfile
# Good
FROM python:3.12-slim@sha256:<digest>

# Bad: floating tag can change under you
FROM python:3.12-slim
```

### Mandatory CI/CD Gates

All of the following must pass before any deployment proceeds:

1. `pre-commit run --all-files`: secret scanning (§8)
2. Language-profile lint and type checks (see active profile)
3. Language-profile test suite at required coverage (see active profile)
4. `trivy image --exit-code 1 --severity HIGH,CRITICAL <image>:<tag>`: no critical CVEs

No deployment may proceed if any gate fails.

### Blue/Green Deployment Conventions

1. Build and push the new image tagged with the git SHA: `<image>:<sha>`.
2. Deploy to the green (inactive) environment.
3. Run smoke tests against green before switching traffic.
4. Switch the load balancer to green only when all smoke tests pass.
5. Keep blue (previous version) running for one hour as a rollback target.
6. Rollback trigger: 5xx error rate >1% sustained for 5 minutes → restore blue.

Agents must not trigger a cutover without human approval (RULES.md §19).

---

## 18. Authorship and Attribution `[CORE]`

**Rule:** Agents are workers, not authors. Humans are unilaterally responsible for all code, documentation, and version control artifacts. No agent may claim, mark, or imply authorship in any form.

### Prohibited attribution forms

The following are prohibited in all files, commits, and version control artifacts, without exception:

- File headers identifying an agent as creator (e.g., `# Generated by Claude`, `# Auto-generated`)
- Inline code comments attributing content to an agent (e.g., `# AI suggestion`, `# Added by Claude`)
- Documentation headings or sections crediting an agent (e.g., `## AI-generated section`)
- Git commit author identity set to an agent name or email
- `Co-Authored-By:` trailers or any commit trailer attributing authorship to an agent
- PR descriptions, issue comments, release notes, git tag annotations, or any other version control artifact authored by or attributed to an agent

### Blanket rule

Agents must not author any text that appears in a version control artifact. Every commit message, PR description, issue comment, release note, and tag annotation must be written by a human.

### Enforcement

Human review does not catch this. The trailer is appended by tooling at commit
time, so it is not part of the change a reviewer is reading. Eight commits in
this repository's own history carried one before any check existed.

Install the `commit-msg` hook from
[templates/.pre-commit-config.yaml](templates/.pre-commit-config.yaml):

```bash
uv add --dev pre-commit
pre-commit install --hook-type pre-commit --hook-type commit-msg
```

A bare `pre-commit install` wires only the `pre-commit` stage, which never sees
the commit message. Without `--hook-type commit-msg` the check silently does
not run.

The hook matches a trailer or footer **line**, anchored, naming an agent
vendor. It does not match the phrase appearing in prose, so a commit may still
describe this rule, and it does not match a `Co-Authored-By:` trailer naming a
human, which stays legitimate.

**A local hook cannot cover every path.** Commits created in the GitHub web UI,
including accepting a Copilot Autofix suggestion, are built server side and
never run local hooks. Five of the eight historical violations arrived that
way. Reviewers must still reject those on the pull request, and a CI check on
the PR's commit range is the only mechanical backstop.

Alongside the hook:

- Human review must confirm no attribution markers are present before merging. See §19 review checklist.
- When an AI tool adds a `Co-Authored-By:` trailer by default (as many do), the human must remove it before committing.
- The git author identity must always reflect the human who owns the work.

### What agents may do

Agents may write, edit, and generate file content as workers executing human-directed tasks. The act of writing does not confer authorship. Humans own all output an agent produces because they review, approve, and commit it.

---

## 19. Code Review and Approval Workflow `[CORE]` `[CONFIGURABLE]`

**Rule:** All code changes must pass automated checks and receive human approval
before merging. Required approvals and the review checklist vary by PR type.

### PR Types and Minimum Approvals

| PR type | Definition | Required approvals |
|---------|-----------|-------------------|
| Hotfix | Critical bug fix; no new features | 1 human |
| Feature | New capability, skill file, or agent definition | 1 human |
| Architectural | Changes to RULES.md, AGENTS.md, subagents.md, or any file that governs agent behavior | 2 humans |
| Breaking | Removes or renames a public interface, agent, or skill | 2 humans |

> **Override:** Minimum approval counts may be adjusted in the downstream
> project's `AGENTS.md` (or `AGENTS/AGENTS.md` per §12) with a written rationale.
> Example: `§19 approval override: Hotfix 0 humans, rationale: solo maintainer project.`

### Automated Checks (must all pass before requesting review)

1. `pre-commit run --all-files`: secret scanning and hook suite (§8)
2. Language-profile lint and type checks (see active profile)
3. Language-profile test suite at required coverage (see active profile)

No review may be requested while any automated check is failing.

### Review Checklist

Reviewers must verify each item before approving:

- [ ] **Security**: No secrets or credentials in source. Pre-commit hooks are installed and passing.
- [ ] **Coverage**: Test coverage did not decrease. All new code has tests.
- [ ] **Type safety**: No new `# type: ignore` without a documented reason on the same line.
- [ ] **RULES.md compliance**: Change does not violate any enforced section (§§1–18).
- [ ] **Authorship**: No file headers, inline comments, commit trailers, or VC artifact text attributes content to an agent (§18).
- [ ] **Scope**: PR is atomic; unrelated changes are absent.
- [ ] **Documentation**: README updated if public-facing behavior changed (§4).
- [ ] **Dependencies**: Any new library is listed in `skills/approved-packages.md`, the authoritative §5 list; its approval is recorded in the project's `authorized_libraries.md`; the §5 cooling period has elapsed and `pip-audit` was re-run immediately before commit.

### Handling Disagreements

1. The reviewer documents the objection as a PR comment citing a specific rule or rationale.
2. The author must respond to every blocking objection before re-requesting review.
3. If unresolved within one working day, escalate to the architectural review path.
4. The project owner's decision is final. Do not merge over an unresolved blocking objection.

### Escalation Path for Architectural Decisions

A decision is architectural if it:

- Changes the agent invocation protocol (`subagents/subagents.md` §§2–8)
- Adds, removes, or renames a registered agent or skill
- Modifies RULES.md §§1–18 (enforced sections)
- Changes the directory structure of `skills/`, `subagents/`, or `templates/`

Architectural decisions require:

1. An open GitHub issue documenting the proposed change and rationale.
2. At least two human approvals on the PR.
3. The project owner as one of the approvers.
4. A RULES.md changelog entry in the same commit.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-08-01 | §5 authority resolved: `skills/approved-packages.md` is authoritative for what may be used; `<project-root>/authorized_libraries.md` is the per-project record of when a library was approved and when its cooling period elapses. Previously §5 named only the latter, whose template runtime table is empty, so read strictly it authorized nothing. The inline table template was replaced with a pointer to `templates/authorized_libraries.md` rather than maintaining a third copy. Added a stdlib clause: stdlib needs no authorization and no entry in either file. §19 dependency checklist updated to check both files for their respective facts. |
| 2026-07-31 | Active Profile block gained a `Domain:` declaration and a domain profile table, for concerns orthogonal to the framework (most often a second language in the codebase). Added SQL dialect profiles `profiles/postgres.md`, `profiles/tsql.md`, and `profiles/plsql.md`. Domain and framework profiles stack; `Domain:` accepts a list but at most one profile per concern. |
| 2026-07-31 | Active Profile block extended with a `Framework:` declaration and a table of available framework profiles. Framework profiles are additive on top of the language profile and name the sections they extend; no section content moved out of this file. Added `profiles/django.md`, `profiles/flask.md`, and `profiles/fastapi.md`. A profile is warranted only where a third-party framework imposes constraints the language profile does not cover: stdlib usage such as `argparse` belongs in `profiles/python.md` or a `skills/` reference, not in a profile. |
| 2026-07-28 | §5 added: dependency cooling period. A 72-hour minimum wait now applies between adding an approved library to `authorized_libraries.md` and committing it to production code; `pip-audit` must be re-run immediately before commit. `authorized_libraries.md` template gained `Approved date` and `Earliest commit date` columns. §19 review checklist updated to verify the cooling period elapsed and the re-audit passed. Resolves #69. |
| 2026-07-12 | `RULES-DRAFTS.md` resolved and deleted, four of its five placeholder sections were already fully covered by §14-§19 and `profiles/python.md`; the three remaining orphaned provisional defaults were promoted: batch-job runtime budget declaration (`profiles/python.md` Performance Standards), PII schema labeling (§16), and container base-image digest pinning (§17). Footer reference to `RULES-DRAFTS.md` removed. |
| 2026-06-18 | §18 added: Authorship and Attribution, blanket prohibition on all agent attribution in file content, comments, documentation, and version control artifacts; prohibited forms enumerated; enforcement note added (human removes Co-Authored-By trailers, no hook); old §18 renumbered to §19; §6 authorship subsection trimmed to reference §18; §13 cross-reference updated; §19 review checklist and escalation path scope updated to include §18; subagents.md §7 version-stamp rule removed. |
| 2026-05-17 | Structural refactor: added scope markers (`[CORE]`, `[LANG:PYTHON]`, `[PROFILE:WEB-UI]`, `[PROFILE:SERVICE]`, `[CONFIGURABLE]`) to all section headers; extracted §1, §2, §3, §7, §9, §10, §14 to `profiles/python.md`; added Active Profile declaration before ToC; rewrote §12 to clarify master-source exemption for downstream copies; deduplicated §6/§13 authorship rule (§6 authoritative, §13 references); added `[CONFIGURABLE]` override notes with example syntax to §7, §16, §18; generalized language-specific CI/CD check commands in §17 and §18. |
| 2026-05-15 | §15: Accessibility and Internationalization filled, WCAG 2.1 AA criteria, axe-core testing, CLI NO_COLOR rule, babel/zoneinfo/gettext i18n standards, scope exceptions. |
| 2026-05-15 | §14: Performance Standards filled, latency targets, memory limits, approved profiling tools, caching libraries, regression escalation criteria. |
| 2026-05-15 | §16: Data Privacy and Compliance filled, classification levels, PII handling, anonymization, retention/deletion policy, audit trail schema, GDPR/CCPA/HIPAA obligations. |
| 2026-05-14 | §8: pre-commit hook requirement made mandatory; reference to `skills/secret-scanning.md` and `templates/.pre-commit-config.yaml` added. Remediation steps expanded. |
| 2026-05-14 | Initial version. Placeholder sections §14–§16 remain unfilled (see open GitHub issues). §17 and §18 filled. |

---

*Last updated: 2026-06-18. Maintained by the repository owner. All agents must
re-read this file at the start of every session.*
