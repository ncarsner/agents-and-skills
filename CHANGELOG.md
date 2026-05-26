# Changelog

All notable changes to this repository are recorded here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## 2026-05-26

### Added
- `skills/wikimedia-svg-sourcing.md` — patterns for downloading public-domain SVGs from Wikimedia Commons: MD5-based URL computation, rate-limit-safe batch downloading (3s delay, ~20-file batches, 15-min cooldown after HTTP 429), HTML error page detection, and ICS signal flag naming conventions. Sourced from `will-it-python` naval flags session (2026-05-23).
- `.claude/commands/rebuild.md` — `/rebuild`: reloads working context after `/clear`; reads uncommitted diff, last 5 commits, modified-file TODOs, and branch-vs-main delta, then summarizes current state.
- `.claude/commands/preflight.md` — `/preflight`: pre-commit scan of staged diff for debug artifacts, hardcoded secrets, commented-out code, test-only flags, and dev-only imports.
- `.claude/commands/dissect.md` — `/dissect <file>`: deep structural review across error handling, edge cases, concurrency, dependencies, and naming; findings rated Critical / Warning / Note.
- `.claude/commands/refactor-safe.md` — `/refactor-safe <file>`: refactors internals (extract helpers, simplify conditionals, remove dead code) without touching exported signatures or public API.
- `.claude/commands/ship.md` — `/ship`: validates tests, assesses diff size, and generates a PR description (Summary, Changes, How to test, Risk assessment, Related issues) ready to paste into GitHub.
- `.claude/commands/migrate-draft.md` — `/migrate-draft <description>`: detects the migration system in use, generates a migration file with UP and DOWN logic matching project conventions, and outputs a safety checklist.
- `.claude/commands/debt-scan.md` — `/debt-scan`: scans for technical debt across code complexity, dependency health, test coverage gaps, code smells, and architectural smells; findings grouped High / Medium / Low.
- `.claude/commands/skills-sync.md` — `/skills-sync`: scans all `~/Code/*/AGENTS/skills/` directories, merges new skill files and missing sections into `skills/`, updates `skills/skills.md` index, and appends a CHANGELOG entry.

### Changed
- `skills/legal-fiscal-analysis.md` — added "Pattern: State-Machine Parsing of PDF-Extracted Legal Code" section: two-region PDF structure (TOC block → body block), four design rules (case-sensitive patterns, explicit state machine, emitted-key dedup, skip on context mismatch), `LegalCodeParser` skeleton. Validated against 69 TCA files, ~37k entries. Sourced from `frc-tools` TCA TSV converter session (2026-05-25).
- `skills/skills.md` — registered `wikimedia-svg-sourcing.md` in reference table; registered `skills-sync` in invokable commands table.

---

## 2026-05-17

### Added
- `profiles/python.md` — language profile extracted from `RULES.md`; contains §1 (uv), §2 (python3), §3 (code quality), §7 (testing), §9 (error handling), §10 (logging), §14 (performance standards).
- `.12-FACTOR-AGENTS.md` — worktree vs branch analysis appendix: conceptual distinction, template-copy model relationship, quantitative comparison with feature branch PR pattern.

### Changed
- `RULES.md` — structural refactor: scope markers (`[CORE]`, `[LANG:PYTHON]`, `[PROFILE:WEB-UI]`, `[PROFILE:SERVICE]`, `[CONFIGURABLE]`) added to all 18 section headers; Python-specific sections replaced with stubs pointing to `profiles/python.md`; Active Profile declaration added before ToC; §12 rewritten to clarify master-source exemption; §6/§13 authorship rule deduplicated (§6 authoritative); `[CONFIGURABLE]` override notes with example syntax added to §7, §16, §18; CI/CD check commands in §17/§18 generalized to language-profile references.
- `templates/epilogue.md` — fixed step numbering gap: §4.5 renamed §5, steps now run 1–9 sequentially.
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — updated `profiles/` resource row to reflect language profile addition.
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
