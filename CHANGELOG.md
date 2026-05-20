# Changelog

All notable changes to this repository are recorded here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## 2026-05-17

### Added
- `.12-FACTOR-AGENTS.md` — analysis of 12-factor agents spec against current repo orchestration, extended with Karpathy wiki lens section mapping `index.md`/`log.md`/wiki-page primitives to existing artifacts and revised recommendations for F3, F5, F12, F13.
- `_SOLUTIONS/2026-05-17-karpathy-wiki.md` — reference document on git worktree mechanics in this repo: filesystem vs. object-level duplication, benefits/tradeoffs, and five refactoring opportunities (tracked as issues #57–#61).

---

## 2026-05-15 (batch 4)

### Added
- `skills/infrastructure-operations.md` — feature flags (env-var, flagsmith, launchdarkly patterns; lifecycle rules), canary/blue-green smoke tests and success metrics table, rollback procedure with `gh issue create` step.
- `skills/cloud-cost-management.md` — required resource tagging table, automated budget alert thresholds, right-sizing recommendations by workload type, cost-review PR checklist.

### Changed
- `skills/api-integration.md` — added Rate Limiting and 429/503 Handling section: `_is_retryable` / `_get_retry_after` helpers, `@retry` decorator with `Retry-After` honor, per-status rules table.
- `skills/web-development.md` — added Health Check Convention section: `/health` (liveness) and `/ready` (readiness) FastAPI pattern, probe rules table, Docker Compose `healthcheck` stanza.
- `skills/secret-scanning.md` — added Credential Rotation Scheduling section: rotation schedule by credential type, `.credential-manifest.json` pattern, `check_credential_expiry()` helper, 6-step rotation procedure.
- `skills/skills.md` — registered `infrastructure-operations.md` and `cloud-cost-management.md`; updated `secret-scanning.md` description.
- Replaced `semver` with "semantic versioning" across `CHANGELOG.md`, `subagents/registry.json`, `subagents/subagents.md`, `subagents/project-review-interoperability.md`.

---

## 2026-05-15 (batch 3)

### Added
- `subagents/release-agent.md` — end-to-end PyPI release workflow: semantic versioning policy, CHANGELOG format, CI gates, `uv publish` / `twine` steps, PyPI token security, GitHub Release creation.

### Changed
- `RULES.md §15` — filled "Accessibility and Internationalization" placeholder: WCAG 2.1 AA criteria table, `axe-core` CLI testing requirement, CLI `NO_COLOR` rule, `babel`/`zoneinfo`/`gettext` i18n standards, scope exceptions for internal tools.
- `subagents/subagents.md §9` — registered `release-agent`.
- `subagents/registry.json` — added `release-agent` entry.

---

## 2026-05-15 (batch 2)

### Changed
- `RULES.md §14` — filled "Performance Standards" placeholder: latency targets by workload type, memory limits (soft/hard), approved profiling tools (`cProfile`, `memray`), approved caching libraries, regression escalation criteria.
- `RULES.md §16` — filled "Data Privacy and Compliance" placeholder: 4-level data classification, PII detection and redaction rules, anonymization techniques, retention/deletion policy by level, structured audit log schema, GDPR/CCPA/HIPAA obligation mapping.

---

## 2026-05-15 (batch 1)

### Added
- `skills/secret-scanning.md` — pre-commit + detect-secrets playbook with full incident remediation.
- `templates/.pre-commit-config.yaml` — canonical pre-commit hook configuration (detect-secrets, detect-private-key, large-files, merge-conflict).
- `skills/multi-agent.md` — handoff payload schema, `MAX_CHAIN_DEPTH=10` loop detection, structured logging.
- `skills/prompt-engineering.md` — prompt structure standards, injection defense, prohibited patterns, token efficiency.
- `templates/authorized_libraries.md` — per-project approved library template with runtime and dev tables.
- `templates/onboarding-checklist.md` — 6-step new agent onboarding checklist.
- `subagents/registry.json` — machine-readable agent and skill catalog (22 agents, 21 skills).
- `skills/cost-management.md` — LLM token logging, provider pricing table, session budget guards, pre-flight cost estimation.
- `subagents/data-collection-agent.md` — provenance tracking, PII detection, data quality validation, regulatory compliance.
- `skills/containerization.md` — Docker multi-stage builds, non-root user, trivy severity policy, blue/green deployment.
- `templates/Dockerfile` — multi-stage Dockerfile template with `<PROJECT_MODULE>` placeholder.
- `templates/.dockerignore` — canonical .dockerignore with 20+ entries.

### Changed
- `RULES.md §8` — made pre-commit + detect-secrets mandatory (previously advisory); expanded remediation to 6 steps.
- `RULES.md §12` — added PR review protocol: approval minimums by PR type, 4 automated pre-merge gates, 7-item reviewer checklist, architectural escalation path.
- `RULES.md §17` — filled "Deployment and Environment Parity" placeholder: env var requirements, 5-gate CI/CD pipeline, blue/green rollback trigger.
- `skills/python-testing.md` — added integration/E2E test section (mock-vs-live boundary table, `@pytest.mark.integration`, `pytest-httpx`/`responses` examples), property-based testing (Hypothesis), mutation testing (mutmut).
- `skills/dashboarding-reporting.md` — added structured output standards: required fields, approved libraries by format, manifest sidecar `write_manifest()` pattern.
- `subagents/subagents.md` — added §4.1 Cross-Agent Skill Reuse and §8.1 Versioning and Lifecycle (semantic versioning, 30-day deprecation policy).
- `subagents/subagents.md §9` — registered `data-collection-agent`.
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` — added containerization and onboarding-checklist to on-demand resource tables.

---

## 2026-05-14

### Added
- `RULES.md §13 AI Agent Compliance` — consolidated agent identity, scope/escalation,
  session startup, and output rules into a dedicated section.
- `CHANGELOG.md` — this file.
- `templates/epilogue.md` — session shutdown protocol; linked from all root context files.

### Changed
- `RULES.md` — fixed duplicate TOC numbering (§12/§13); renumbered placeholders 14–18;
  updated last-modified date.
- `RULES-DRAFTS.md` — replaced five TODO-only placeholder blocks with compact stubs
  containing provisional enforceable defaults agents can apply immediately.
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` — added "Session shutdown protocol" to on-demand resources.
- `README.md` — added RULES-DRAFTS.md and CHANGELOG.md to structure listing; added
  "Closing a session" workflow section; updated epilogue.md description.

---

## 2026-05-11 – 2026-05-12

### Added
- `ralph.sh` agent loop with `--prd`, `--goal`, and `--max` flags; `/ralph` slash command.
- Guard clause in `/prd` sibling skill to prevent sibling-mode from calling `/prd`
  recursively.

### Changed
- `README.md` — updated structure and workflow documentation.
- Path and reference patches across skills and agent files (broken relative links).
- Multi-agent refinement pass incorporating feedback from composite agent review.

---

## 2026-05-10

### Added
- Cache analysis markdown files documenting cache optimization strategies for Claude
  and Gemini context windows.
- Headless agent enablement protocols in `subagents/subagents.md` and `GEMINI.md`.

---

## 2026-05-07 – 2026-05-08

### Added
- Authorship rules in `RULES.md §6` and all root context files — agents must never
  set git identity or add attribution trailers.

### Changed
- Full refactor of skills, agent files, and rules for consistency and completeness.

---

## 2026-05-05 – 2026-05-06

### Added
- Nine `project-review-*.md` subagents: accessibility, change-manager, CTO, enterprise
  architect, interoperability, observability, PM, scrum-master, VP.
- `skills/github-issue-creation.md` with explicit user-request safeguards.

### Changed
- Subagent registry renamed and aligned; all agent files updated.

---

## 2026-05-04

### Added
- `skills/approved-packages.md` extended with additional authorized libraries.
- `tools/` directory — deterministic stdlib recipes across 8 domains.

### Changed
- Epilogue scripts cleaned up and updated.

---

## 2026-05-01

### Fixed
- Context file case references (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`) corrected
  across all epilogue templates.
- Removed byte-size parity checks; replaced with `diff` / checksum checks.
- `gh auth` status check added to epilogue git block for clearer failure messages.
- README hierarchy corrected.
- CLAUDE.md and GEMINI.md "you are here" markers corrected.

---

## 2026-04-29

### Added
- `STRATEGY.md` — multi-agent phased-day project execution strategy.
- Initial PRD plan in `plans/`.

### Changed
- Replaced `pdfplumber` with `pypdf` across all subagent files.
- File cleanup and directory organization.

---

## 2026-04-21

### Added
- `subagents/containerization-agent.md` — Docker and deployment standards.
- `subagents/project-review-accessibility.md` — accessibility deficiency review.
- `subagents/accounting-agent.md` — token usage and cost monitoring.
- `subagents/security-agent.md` and three additional review agents.
- Security assumptions log and no-markdown style rule in subagent protocol.

### Fixed
- Accounting-agent example code from code review feedback.
- Font-size guidance and placeholder name normalization.

---

## 2026-04-16

### Added
- `skills/approved-packages.md` — 26-category authorized library list.

---

## 2026-04-15

### Added
- `RULES.md` — initial mandatory compliance rules (12 sections).
- `_SCRIPTS/create_issues.sh` — bulk GitHub issue creation script.
- WAT framework `profiles/` CLAUDE.md with frontend website rules.

---

## 2026-04-14

### Added
- Initial commit: agent and skill boilerplate templates.
- Comprehensive `subagents/` and `skills/` markdown reference library.
- `templates/` — pyproject.toml, ruff.toml, pytest.ini, .python-version.
- Root context files: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`.
