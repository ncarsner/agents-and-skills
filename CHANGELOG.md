# Changelog

All notable changes to this repository are recorded here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## 2026-08-30

### Changed
- Renamed the canonical instruction file from `CLAUDE.md` to `AGENTS.md`, reversing the 2026-07-12 consolidation's choice of filename. That consolidation was right to collapse three drifting root files into one and wrong about which name to keep: `AGENTS.md` is the cross-agent convention multiple tools read, while `CLAUDE.md` is vendor-specific. The single-file structure is unchanged; only the name moved. Do not re-litigate this in the opposite direction without reading both entries.
- The root `CLAUDE.md` is now a stub pointing at `AGENTS.md`, matching what downstream projects already do. Auto-load-by-filename is the one capability the rename gives up, and Claude Code reads `CLAUDE.md` and no other name, so the stub is what preserves it.
- Resolved the file-versus-directory objection that motivated deleting `AGENTS.md` in the first place: `AGENTS.md` the file and `AGENTS/` the directory are never in the same place. Downstream only the directory sits at the root, with the file inside it as `AGENTS/AGENTS.md`; here, with no `AGENTS/` directory, only the file exists. `RULES.md` §12 gained a "File versus directory" subsection stating this.
- `RULES.md` §12 stub pattern, `templates/context-file-stub.md`, `/epilogue` Step 3 and its discovery command, `README.md`, `templates/onboarding-checklist.md`, `skills/bundle-distribution.md`, and 22 `subagents/*.md` files updated to the new name. Historical `CHANGELOG.md` entries and `archive/` were deliberately left alone: they record what was true on their date.
- `sessions/` paths in `STRATEGY.md` and `/orient` now resolve under both layouts. Pages are project-root state, since they are git-tracked and `AGENTS/` is never committed; only the format spec ships with the bundle. `RULES.md` §12 gained a "Path references inside bundle documents" subsection recording the general constraint.
- `index.md`'s Repo Reference Docs rows point at `CHANGELOG.md` date headings instead of gitignored `*-session.md` files, and `/epilogue` gained Step 5a so a routine session close keeps the catalog current.

### Fixed
- `AGENTS.md`'s opening paragraph asserted it was "the only root context file" and that Claude Code auto-loads it by convention. Both were false in a downstream copy, where the file ships to `AGENTS/AGENTS.md` and the root holds the stub. Rewritten to hold in both layouts, pointing at `RULES.md` §12 rather than restating it.
- Six of eight `index.md` Repo Reference Docs rows pointed at gitignored paths, so a keyword grep reported a hit and then routed the agent to a file absent from any fresh clone, CI checkout, or worktree.
- `STRATEGY.md` and `/orient` cited `sessions/README.md` as a bare root-relative path. Downstream that pointed at the project root while the spec sat at `AGENTS/sessions/README.md`.

### Note
- The copy mechanism that seeds downstream projects lives outside this repository and still names the old file. It has to be updated to ship `AGENTS.md`, install the root `CLAUDE.md` stub, and match the new stub body; its stub-detection check keyed on the literal string `See AGENTS/CLAUDE.md`, which no longer appears anywhere.

---

## 2026-08-07

### Fixed
- `templates/pyproject.toml` and `templates/ruff.toml` set `magic-trailing-comma = true`, which is not a valid `[tool.ruff.format]` field (the real one is `skip-magic-trailing-comma`, inverted). `ruff check` errored outright on the shipped template, so every project scaffolded from it had a broken lint gate. Found by materializing the template and running it, not by reading it. Corrected to `skip-magic-trailing-comma = false`, which preserves the intended behavior.
- `RULES.md` §5 ran its mandatory vulnerability scan as `pip_audit --requirement <(uv pip compile pyproject.toml)`. That command resolves `[project] dependencies` only. With dev dependencies moved to `[dependency-groups]` it would have silently stopped covering them: measured on a probe project, `uv pip compile` resolved 5 packages where `uv export --all-groups` resolved 19. Both occurrences now export from `uv.lock` with hashes. `--no-deps` is justified on the merits (the export is already a complete pinned resolution); `--disable-pip` is documented as a fallback for machines where pip-audit cannot bootstrap its resolution environment, not as part of the canonical command.
- `templates/pyproject.toml` and `templates/ruff.toml` ignored `D100`/`D104`/`D203`/`D213` without ever selecting `D`, so the profile's docstring rule had no tooling behind it. `D` is now selected with `convention = "google"`. Verified that `D101`, `D102`, and `D103` fire and that `D107` (missing `__init__` docstring) is ignored, since the class docstring documents construction.
- Both templates ignored `ANN101` and `ANN102`, removed from ruff in 0.8.0. Dropped, along with the same pair in `skills/python-linting.md`.

### Changed
- `profiles/python.md` Package Management: dev dependencies are declared in `[dependency-groups]` (PEP 735), never in `[project.optional-dependencies]` and never in the pre-standard `[tool.uv] dev-dependencies` table. The `uv pip install -e ".[dev]"` row was a pip shim inside a profile whose own rule is "never use pip"; it is now prohibited. `uv sync` installs the project editable on its own, verified by importing the package from outside its directory and confirming the path resolves into `src/`. `templates/pyproject.toml` and `skills/python-uv-workflow.md` carried the same deprecated table plus a duplicate `dev` extra; both now declare one `[dependency-groups] dev`.
- `profiles/python.md` Python Executable: every invocation goes through `uv run`. Bare `python3` is prohibited alongside `python` and `py`, because it resolves against `$PATH` and can pick up a system interpreter, which PEP 668 marks as externally managed for that reason. This contradiction had been sitting between the profile and `RULES-BRIEF.md` §2, which already said "`python3` via `uv run`". The sweep touched 20 files, including `CLAUDE.md`'s "After every Python edit" block, the profile's own Enforcement block, `.claude/skills/{test,format}`, `subagents/testing-agent.md`, and `skills/python-{testing,linting,formatting}.md`.
- `profiles/python.md` Type hints: the Python baseline is stated once as 3.12 and the compatibility hedges are gone. Built-in generics (PEP 585) and `X | None` (PEP 604) are unconditional; `typing.List`, `Dict`, `Tuple`, `Set`, `Optional`, and `Union` are prohibited. `requires-python`, `[tool.mypy] python_version`, `skills/python-formatting.md`, and `skills/python-linting.md` moved from 3.11 to match `.python-version` and ruff's `target-version`, which were already 3.12.
- `profiles/python.md` no longer mandates `from __future__ import annotations`. A blanket mandate breaks anything reading annotations at runtime (Pydantic, FastAPI route signatures, `dataclasses`, `get_type_hints`), which conflicts with this repo's own FastAPI and Django profiles. PEP 563 is Superseded and PEP 649/749 make deferred evaluation the default in 3.14 without it. Quoted forward references are the replacement, with the `if TYPE_CHECKING:` `NameError` trap called out explicitly, since the coverage config blesses that idiom. `skills/python-formatting.md` and `skills/process-modernization.md` had the import as a routine example and now agree.
- `templates/pyproject.toml` and `skills/python-uv-workflow.md`: `license = { text = "MIT" }` replaced with an SPDX string plus `license-files` (PEP 639). Confirmed the `LICENSE` file lands in the wheel's `dist-info/licenses/`.
- The dev-group mypy floor moved from `>=1.10` to `>=1.12`, the release that enables PEP 695 type-parameter syntax by default rather than behind `--enable-incomplete-feature=NewGenericSyntax`.
- The CI example in `skills/python-uv-workflow.md` installed with `uv sync --all-extras`, which resolves to nothing once dev deps are a group. Changed to plain `uv sync`, which includes the dev group, rather than `--all-groups`, which would newly install every group a project defines.

### Added
- `profiles/python.md` Error Handling: `raise ... from exc` (PEP 3134) is now a rule with an example, including `from None` for deliberate suppression. The section previously said "re-raise with context" while omitting the one syntax that preserves it. `exc.add_note()` (PEP 678) and `ExceptionGroup`/`except*` for concurrent fan-out (PEP 654) added as rules.
- `profiles/python.md` Code Quality: a `py.typed` subsection (PEP 561). Verified that hatchling's `packages = ["src/<name>"]` ships the marker with no extra build configuration, so the profile documents that rather than adding a no-op include line.
- `profiles/python.md` and `skills/python-uv-workflow.md`: PEP 723 inline script metadata as the pattern for one-off scripts, replacing `python3 src/<entry>.py`.
- `profiles/python.md`: PEP 695 type parameters, PEP 692 `Unpack[TypedDict]`, and PEP 698 `@override` documented as available at 3.12 and explicitly not mandatory, since runtime introspection of `type` aliases is still uneven.
- `skills/python-uv-workflow.md`: a lock-export section covering the audit requirements export and PEP 751 `pylock.toml`. `uv.lock` remains the source of truth.

---

## 2026-08-01

### Changed
- `RULES.md` §5: `skills/approved-packages.md` is now the authoritative list of what may be used. A library absent from it is unauthorized, and amending that list is a human decision, not an agent one. `<project-root>/authorized_libraries.md` keeps a distinct role as the per-project record of when a library was approved and when its 72h cooling period elapses. Previously §5 named only the latter, whose template runtime table is empty, so read strictly it authorized nothing, including `psycopg2`. `RULES-BRIEF.md` §5 row, the §19 dependency checklist, `skills/approved-packages.md`, `templates/authorized_libraries.md`, and `templates/onboarding-checklist.md` all updated to state the split.
- `RULES.md` §5 gained a stdlib clause: the standard library needs no authorization and no entry in either file. The inline table template was replaced with a pointer to `templates/authorized_libraries.md`, which already carried the current six-column set, rather than maintaining a third copy that had already drifted to five.
- `profiles/postgres.md`, `profiles/tsql.md`, `profiles/plsql.md`: driver-authorization notes now cite the single authority. Gating is unchanged and still correct, since `pyodbc` and `python-oracledb` remain absent from `skills/approved-packages.md`; only the citation changed. PostgreSQL's `psycopg2-binary` and `asyncpg` are listed, so that profile no longer carries a caveat about an empty table.
- `.claude/commands/epilogue.md` Step 3: `CLAUDE.md` is updated only where a session changed the standing instructions, and explicitly must not receive a changelog table, dated entry, or session recap. Step 8's checklist item matches. This was the mechanism that regenerated the duplicate every session.

### Removed
- `CLAUDE.md`'s `## Changelog` section. It was inherited from `AGENTS.md` on 2026-07-12 ("carries forward `AGENTS.md`'s changelog section as `CLAUDE.md`'s own") and was never reconciled against this file, which had existed since 2026-05-14. It then drifted from a per-file edit log into full session recaps. Every date it recorded (2026-07-29, 2026-07-12, 2026-06-10, 2026-06-01, 2026-05-17, 2026-05-14) already has a section here, so nothing was lost. `CHANGELOG.md` is the single record for what changed and when; `CLAUDE.md` holds instructions only, and now links here from its resource table.
- The prohibition on `click.testing.CliRunner` recorded on 2026-07-31 is withdrawn. It rested on the runner being absent from `templates/authorized_libraries.md`, which is no longer the authority; `click` is listed in `skills/approved-packages.md` and is therefore authorized. The stdlib testing approach in `skills/cli-development.md` (direct calls, `subprocess`, `pty`) stands on its own merits for coverage and mocking, not as a §5 requirement. The Click `CliRunner` recipes in `skills/cli-development.md`, `subagents/cli-agent.md`, and `subagents/testing-agent.md` are valid as written.

---

## 2026-07-31

### Added
- `profiles/django.md`, `profiles/flask.md`, `profiles/fastapi.md`: normative framework profiles (Rule / Prohibited / Rationale, matching `profiles/python.md`), additive on top of the language profile. They link to `skills/web-development.md` for implementation rather than restating it.
- `profiles/postgres.md`, `profiles/tsql.md`, `profiles/plsql.md`: normative SQL dialect profiles covering the surface SQLAlchemy does not abstract, namely raw SQL, DDL, DSNs, and error handling. Each names its dialect's divergences (identifier folding, `NULL` sort order, transactional versus implicitly committing DDL, upsert idiom) rather than restating shared SQL.
- `RULES.md` Active Profile block: `Framework:` and `Domain:` declarations plus profile tables. Both axes are additive and stack, so a Django service on PostgreSQL declares one of each. `RULES-BRIEF.md` gained the matching session-start discovery line, since the brief is the documented session-start path.
- `skills/cli-development.md`: argparse boundary-validation recipes (`type=` callables raising `ArgumentTypeError`, `choices=` with an `Enum`), the `parser.error()`-exits-2 collision with the `EXIT_APP_ERROR` convention, `main(argv)` tests using `capsys`, and a stdlib `pty` helper for the RULES.md §15 `NO_COLOR` assertion.
- `skills/bundle-distribution.md`: rsync include-list rules (first-match-wins ordering, parent-directory inclusion), clean-slate pruning, subtree merging without nesting, idempotent `.gitignore` appending, source-repo refusal guard, and the alias-shadows-function trap. Registered in `skills/skills.md`.

### Changed
- `skills/approved-packages.md` §13 and the `skills/skills.md` registry row: argparse is the default for new CLI tools, being stdlib and so carrying no §5 dependency. Click sections are retained for codebases already using it.
- Rules that would have mandated an unauthorized dependency now defer to the §5 authorization process instead: `pytest-django`, `flask-wtf`, `pyodbc`, `python-oracledb`. Only PostgreSQL has an authorized driver, so `profiles/tsql.md` and `profiles/plsql.md` gate connectivity behind §5.
- `CLAUDE.md` changelog: same-day entries consolidated into a single dated row.

### Fixed
- `skills/database-access.md` "Raw Query Pattern" used `LIMIT :top_n` while presenting itself as generic. `LIMIT` is a syntax error on both SQL Server and Oracle; replaced with `FETCH FIRST ... ROWS ONLY` plus a note on the SQL Server `OFFSET 0 ROWS` prefix. Added an Oracle DSN row and a note that neither the SQL Server nor the Oracle connection string implies driver authorization.
- Corrected an inaccurate claim recorded in issue #76 during this session: bare `index.md` greps do resolve in downstream copies, since the copy wrapper seeds `index.md` at the project root (grep returns exit 1, no match, rather than exit 2, no such file). The genuine path defect is `sessions/`, tracked separately as #77.

Filed #76 (`index.md` catalog integrity and `/epilogue` wiring), #77 (`sessions/`
resolving to two directories downstream), #78 (`CLAUDE.md` opening paragraph
claiming to be the root context file), and #79 (rename `CLAUDE.md` to
`AGENTS.md`, blocked on the other three). Added a `blocked` label.

---

## 2026-07-29

### Added
- Root `log.md`: Karpathy-wiki append-only execution record (bracket schema documented in the file itself), replacing the fragmented `plans/*-progress.txt` convention.
- Root `index.md`: content catalog with a Session Wiki Pages table and a Repo Reference Docs table indexing existing dated docs/`_SOLUTIONS` notes by keyword.
- `sessions/`: session wiki page format (`sessions/README.md`: Outcomes, Decisions, Cross-References, Subagent Plan), used by `STRATEGY.md`'s multi-phase (morning/afternoon/evening) closing ritual.
- `skills/github-issue-creation.md`: Issue Triage and Closure section: verify an issue's factual claims against current repo state before acting on or closing it, plus a closure-comment command pattern.
- `RULES.md` §5: dependency cooling period (72h, as merged) between a library's approval and its first commit, with a mandatory `pip-audit` re-run before commit. `templates/authorized_libraries.md` gained `Approved date` / `Earliest commit date` columns; §19 checklist updated to match.

### Changed
- `ralph.sh` and `plans/test-coverage-ralph.sh`: append structured entries to `log.md` instead of per-PRD `*-progress.txt` files; general (non-PRD) `ralph.sh` mode now logs execution state too, which it previously did not at all.
- `STRATEGY.md` §1, Strategy 4/5, Daily Execution Checklist: opening ritual greps `index.md` for task-domain pages; closing ritual writes a `sessions/yyyy-mm-dd-<phase>.md` page instead of the old `yyyy-mm-dd-<phase>-summary.md` file.
- `.claude/skills/orient/SKILL.md`: new Step 3 greps `index.md` for task-domain pages before the repo survey; remaining steps renumbered (4, 5).
- `subagents/subagents.md`: new §2.1 Pre-fetch Context: grep `index.md` before invoking a subagent; §7 Constraints gained a rule that background agents in a worktree must not edit `skills/`, `subagents/`, or `templates/` unless the task is explicitly scoped to those files.
- `.gitignore`: added `.claude/worktrees/` so editors/search tools don't descend into worktree copies.
- `.12-FACTOR-AGENTS.md`: F5 (Unify Execution + Business State) upgraded ❌→⚠️, F13 (Pre-fetch Context) upgraded ⚠️→✅; added an Implementation Status note documenting what shipped and what was deliberately left out of scope.

### Removed
- `plans/epilogue-refinements-prd-progress.txt` and `plans/test-coverage-progress.txt`: migrated into `log.md`; both retired.

All 7 GitHub issues deferred from the 2026-07-12 cleanup are now resolved:
#69, #57, #58, #60, #61 merged via PRs #72/#73/#74; #59 and #10 closed as
outmoded/stale, their cited conventions/files (a never-enforced branch
naming scheme, a deleted `AGENTS.md`) no longer held.

---

## 2026-07-12

### Fixed
- `RULES-DRAFTS.md` resolved and deleted. Four of its five placeholder sections were already fully covered by `RULES.md` §14-§19; the three remaining orphaned provisional defaults were promoted before deletion: batch-job runtime budget declaration (`profiles/python.md` Performance Standards), PII schema/field labeling (`RULES.md` §16), and container base-image digest pinning (`RULES.md` §17). Footer reference and `README.md` structure-tree entry removed.
- `subagents/registry.json`: `skills` array was drifted from `skills/`: removed a duplicate `python-testing` entry (stale 1.1.0 alongside 1.2.0), added three missing entries (`infrastructure-operations`, `cloud-cost-management`, `wikimedia-svg-sourcing`). Registry now in exact parity with the filesystem.
- `skills/skills.md`: `skills-sync` was listed as if it were a `.claude/skills/` directory like the other invokable skills; it's actually `.claude/commands/skills-sync.md`. Split it and the other seven command-file invocables into their own "Command-file invocables" table.
- `templates/ruff.toml` and `templates/pyproject.toml`: `[tool.ruff] target-version` was `py311`, inconsistent with `templates/.python-version`'s `3.12` pin. Bumped both to `py312`.
- `README.md`: `templates/` subtree listing was missing five files that exist on disk (`.dockerignore`, `.pre-commit-config.yaml`, `authorized_libraries.md`, `Dockerfile`, `onboarding-checklist.md`); added them.
- Downstream bundle contents: dropped a dead `SKILLS.md` entry (no such file exists at repo root); added the missing `profiles/` directory (`RULES.md` §§1,2,3,7,9,10,14 all delegate to `profiles/python.md`, so downstream copies were shipping with broken references).
- `.claude/commands/skills-sync.md`: the sync process updated `skills/skills.md` for newly added files but never registered them in `subagents/registry.json`, which is exactly how that registry drifted in the first place. Added a step that registers new skills in `subagents/registry.json` alongside the existing `skills.md` update, so future syncs stay in parity automatically.

### Removed
- `AGENTS.md` and `GEMINI.md` deleted. `CLAUDE.md` is now the sole root context file, in this repo and in downstream copies. Supersedes the stub-file approach originally recorded here earlier today, the decision was revised mid-session to full removal rather than one-line stubs, since this repo has no `AGENTS/` subdirectory of its own (RULES.md §12 exemption) and keeping an `AGENTS.md` *file* alongside that convention's `AGENTS/` *folder* name downstream was a source of confusion, not just duplication.

### Changed
- `CLAUDE.md`: merged the unique content from `AGENTS.md`/`GEMINI.md` before deleting them: the explicit git-config authorship instruction and the headless-delegation "treat output as untrusted Result data" integration note (from `GEMINI.md`), and the onboarding-checklist / containerization resource-table rows (from `AGENTS.md`). Also carries forward `AGENTS.md`'s changelog section as `CLAUDE.md`'s own.
- `RULES.md` §12: downstream copies now place the full bundle under `AGENTS/` as before, but the project root gets only a `CLAUDE.md` **stub** (new `templates/context-file-stub.md`) pointing at `AGENTS/CLAUDE.md`, which holds the actual canonical content. This makes the root/`AGENTS/` duplication that motivated this change structurally impossible, there's nothing left at root to drift out of sync. Six other `AGENTS.md` mentions (override-note pointers in §7, §14, §16, §19, and the §19 architectural-file list) updated to `CLAUDE.md`.
- `templates/epilogue.md` §3: dropped the per-tool context-file table (Claude/Gemini/Codex/Perplexity); replaced with `CLAUDE.md`-only guidance that locates and edits the canonical copy (root or `AGENTS/CLAUDE.md`) rather than maintaining parallel files.
- `templates/onboarding-checklist.md`, `STRATEGY.md`, `skills/secret-scanning.md`, `README.md`, and all 23 `subagents/*.md` files, updated `AGENTS.md`/`GEMINI.md` references to `CLAUDE.md` (subagent files used a consistent "This file extends `AGENTS.md`... read root `AGENTS.md` first" pattern, bulk-corrected).
- Downstream bundle contents: `AGENTS.md` and `GEMINI.md` no longer ship; only `CLAUDE.md` goes downstream as the root context file now.

### Added
- `templates/context-file-stub.md`: the exact root-stub content downstream projects copy to `CLAUDE.md` when the full bundle lives under `AGENTS/`.
- `.claude/commands/epilogue.md`: the session shutdown protocol, converted from `templates/epilogue.md` to a `/epilogue` command since it's invoked frequently at end of session rather than copied once into a new project. Content carried over in full (all 9 steps, closure checklist, final report format); §3 already reflects the `CLAUDE.md`-only context-file change above. Original template archived at `archive/epilogue-template-2026-07-12.md` before conversion.

### Removed (continued)
- `templates/epilogue.md`: superseded by `.claude/commands/epilogue.md`. All references updated (`CLAUDE.md` resource table, `README.md` structure tree and prose, `STRATEGY.md`, `skills/skills.md`'s command-file table). The downstream bundle needed no change, `.claude/commands/` is already covered by the existing `.claude/` glob, and the new `archive/` directory is intentionally unlisted (repo-internal history, not shipped downstream).

Note for whoever runs `/ralph` next: `plans/prd.json`'s existing "AGENTS.md canonicalization" task is now fully superseded by the work above, `AGENTS.md` no longer exists to canonicalize around. That task should be closed or rewritten, not executed as written.

Still deferred, per the existing `plans/prd.json` backlog and pipeline discipline: `profiles/` domain expansion (`profiles/web-ui.md`, `profiles/service.md` matching RULES.md §15/§17's `[PROFILE:...]` markers) and "unused" skills/subagents triage (registries are in perfect sync with the filesystem; needs the user to name specifics).

Open GitHub issues #10, #57, #58, #59, #60, #61, #69 remain untouched, addressed after this cleanup.

---

## 2026-06-18

### Added
- `RULES.md §18 Authorship and Attribution`: new `[CORE]` section: blanket prohibition on agent attribution in file headers, inline comments, documentation, commits, PRs, release notes, tags, and all version control artifacts; enumerated prohibited forms; enforcement note (human removes Co-Authored-By trailers, no hook).

### Changed
- `RULES.md`: old §18 Code Review and Approval Workflow renumbered to §19; §6 Authorship subsection trimmed to reference §18; §13 cross-reference updated; §19 review checklist gains Authorship item; RULES.md compliance range updated to §§1-18; escalation path scope updated to §§1-18.
- `CLAUDE.md`: Git Authorship section expanded to cover file-level attribution; reference updated to §18.
- `subagents/subagents.md §7`: removed version-stamp constraint (incoherent with authorship doctrine).

---

## 2026-06-10

### Added
- `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`: Pipeline Discipline section enforcing ideate-to-ralph stage order at session start, with scope check against `plans/*.json`.

### Changed
- `.claude/skills/ideate/SKILL.md`: added PIPELINE GATE block at output end: prohibits file creation, requires human to invoke `/grill-me` next.
- `.claude/skills/grill-me/SKILL.md`: replaced soft "Ready to run /prd?" handoff with hard PIPELINE GATE stop instruction.
- `.claude/skills/prd/SKILL.md`: replaced soft "Ready to run /prd-to-issues?" handoff with hard PIPELINE GATE stop instruction.
- `subagents/subagents.md`: scope-validation step (§2) now checks pipeline stage: routes to `/ralph` if `plans/*.json` has incomplete tasks; routes to `/ideate` for new features with no plan file.
- `templates/epilogue.md`: §3 adds `find` discovery command for locating context files from inside the `AGENTS/` subdirectory; prohibits creating context files inside `AGENTS/`; checklist item updated to match.

---

## 2026-06-01

### Added
- `RULES-BRIEF.md`: 31-line session-start compliance reference table covering all 18 RULES.md sections with on-demand load guidance. Reduces per-session token cost by ~4k tokens.

### Changed
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`: compliance directive now loads `RULES-BRIEF.md` at session start; full `RULES.md` loaded on demand only.
- `CLAUDE.md`: `/orient` made conditional (delegation/cross-domain tasks only); was previously mandatory at every session start.

---

## 2026-05-26

### Added
- `skills/wikimedia-svg-sourcing.md`: patterns for downloading public-domain SVGs from Wikimedia Commons: MD5-based URL computation, rate-limit-safe batch downloading (3s delay, ~20-file batches, 15-min cooldown after HTTP 429), HTML error page detection, and ICS signal flag naming conventions. Sourced from `will-it-python` naval flags session (2026-05-23).
- `.claude/commands/rebuild.md`: `/rebuild`: reloads working context after `/clear`; reads uncommitted diff, last 5 commits, modified-file TODOs, and branch-vs-main delta, then summarizes current state.
- `.claude/commands/preflight.md`: `/preflight`: pre-commit scan of staged diff for debug artifacts, hardcoded secrets, commented-out code, test-only flags, and dev-only imports.
- `.claude/commands/dissect.md`: `/dissect <file>`: deep structural review across error handling, edge cases, concurrency, dependencies, and naming; findings rated Critical / Warning / Note.
- `.claude/commands/refactor-safe.md`: `/refactor-safe <file>`: refactors internals (extract helpers, simplify conditionals, remove dead code) without touching exported signatures or public API.
- `.claude/commands/ship.md`: `/ship`: validates tests, assesses diff size, and generates a PR description (Summary, Changes, How to test, Risk assessment, Related issues) ready to paste into GitHub.
- `.claude/commands/migrate-draft.md`: `/migrate-draft <description>`: detects the migration system in use, generates a migration file with UP and DOWN logic matching project conventions, and outputs a safety checklist.
- `.claude/commands/debt-scan.md`: `/debt-scan`: scans for technical debt across code complexity, dependency health, test coverage gaps, code smells, and architectural smells; findings grouped High / Medium / Low.
- `.claude/commands/skills-sync.md`: `/skills-sync`: scans sibling projects' `AGENTS/skills/` directories, merges new skill files and missing sections into `skills/`, updates `skills/skills.md` index, and appends a CHANGELOG entry.

### Changed
- `skills/legal-fiscal-analysis.md`: added "Pattern: State-Machine Parsing of PDF-Extracted Legal Code" section: two-region PDF structure (TOC block → body block), four design rules (case-sensitive patterns, explicit state machine, emitted-key dedup, skip on context mismatch), `LegalCodeParser` skeleton. Validated against 69 TCA files, ~37k entries. Sourced from `frc-tools` TCA TSV converter session (2026-05-25).
- `skills/skills.md`: registered `wikimedia-svg-sourcing.md` in reference table; registered `skills-sync` in invokable commands table.

---

## 2026-05-17

### Added
- `profiles/python.md`: language profile extracted from `RULES.md`; contains §1 (uv), §2 (python3), §3 (code quality), §7 (testing), §9 (error handling), §10 (logging), §14 (performance standards).
- `.12-FACTOR-AGENTS.md`: worktree vs branch analysis appendix: conceptual distinction, template-copy model relationship, quantitative comparison with feature branch PR pattern.

### Changed
- `RULES.md`: structural refactor: scope markers (`[CORE]`, `[LANG:PYTHON]`, `[PROFILE:WEB-UI]`, `[PROFILE:SERVICE]`, `[CONFIGURABLE]`) added to all 18 section headers; Python-specific sections replaced with stubs pointing to `profiles/python.md`; Active Profile declaration added before ToC; §12 rewritten to clarify master-source exemption; §6/§13 authorship rule deduplicated (§6 authoritative); `[CONFIGURABLE]` override notes with example syntax added to §7, §16, §18; CI/CD check commands in §17/§18 generalized to language-profile references.
- `templates/epilogue.md`: fixed step numbering gap: §4.5 renamed §5, steps now run 1–9 sequentially.
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`: updated `profiles/` resource row to reflect language profile addition.
- `.12-FACTOR-AGENTS.md`: analysis of 12-factor agents spec against current repo orchestration, extended with Karpathy wiki lens section mapping `index.md`/`log.md`/wiki-page primitives to existing artifacts and revised recommendations for F3, F5, F12, F13.
- `_SOLUTIONS/2026-05-17-karpathy-wiki.md`: reference document on git worktree mechanics in this repo: filesystem vs. object-level duplication, benefits/tradeoffs, and five refactoring opportunities (tracked as issues #57–#61).

---

## 2026-05-15 (batch 4)

### Added
- `skills/infrastructure-operations.md`: feature flags (env-var, flagsmith, launchdarkly patterns; lifecycle rules), canary/blue-green smoke tests and success metrics table, rollback procedure with `gh issue create` step.
- `skills/cloud-cost-management.md`: required resource tagging table, automated budget alert thresholds, right-sizing recommendations by workload type, cost-review PR checklist.

### Changed
- `skills/api-integration.md`: added Rate Limiting and 429/503 Handling section: `_is_retryable` / `_get_retry_after` helpers, `@retry` decorator with `Retry-After` honor, per-status rules table.
- `skills/web-development.md`: added Health Check Convention section: `/health` (liveness) and `/ready` (readiness) FastAPI pattern, probe rules table, Docker Compose `healthcheck` stanza.
- `skills/secret-scanning.md`: added Credential Rotation Scheduling section: rotation schedule by credential type, `.credential-manifest.json` pattern, `check_credential_expiry()` helper, 6-step rotation procedure.
- `skills/skills.md`: registered `infrastructure-operations.md` and `cloud-cost-management.md`; updated `secret-scanning.md` description.
- Replaced `semver` with "semantic versioning" across `CHANGELOG.md`, `subagents/registry.json`, `subagents/subagents.md`, `subagents/project-review-interoperability.md`.

---

## 2026-05-15 (batch 3)

### Added
- `subagents/release-agent.md`: end-to-end PyPI release workflow: semantic versioning policy, CHANGELOG format, CI gates, `uv publish` / `twine` steps, PyPI token security, GitHub Release creation.

### Changed
- `RULES.md §15`: filled "Accessibility and Internationalization" placeholder: WCAG 2.1 AA criteria table, `axe-core` CLI testing requirement, CLI `NO_COLOR` rule, `babel`/`zoneinfo`/`gettext` i18n standards, scope exceptions for internal tools.
- `subagents/subagents.md §9`: registered `release-agent`.
- `subagents/registry.json`: added `release-agent` entry.

---

## 2026-05-15 (batch 2)

### Changed
- `RULES.md §14`: filled "Performance Standards" placeholder: latency targets by workload type, memory limits (soft/hard), approved profiling tools (`cProfile`, `memray`), approved caching libraries, regression escalation criteria.
- `RULES.md §16`: filled "Data Privacy and Compliance" placeholder: 4-level data classification, PII detection and redaction rules, anonymization techniques, retention/deletion policy by level, structured audit log schema, GDPR/CCPA/HIPAA obligation mapping.

---

## 2026-05-15 (batch 1)

### Added
- `skills/secret-scanning.md`: pre-commit + detect-secrets playbook with full incident remediation.
- `templates/.pre-commit-config.yaml`: canonical pre-commit hook configuration (detect-secrets, detect-private-key, large-files, merge-conflict).
- `skills/multi-agent.md`: handoff payload schema, `MAX_CHAIN_DEPTH=10` loop detection, structured logging.
- `skills/prompt-engineering.md`: prompt structure standards, injection defense, prohibited patterns, token efficiency.
- `templates/authorized_libraries.md`: per-project approved library template with runtime and dev tables.
- `templates/onboarding-checklist.md`: 6-step new agent onboarding checklist.
- `subagents/registry.json`: machine-readable agent and skill catalog (22 agents, 21 skills).
- `skills/cost-management.md`: LLM token logging, provider pricing table, session budget guards, pre-flight cost estimation.
- `subagents/data-collection-agent.md`: provenance tracking, PII detection, data quality validation, regulatory compliance.
- `skills/containerization.md`: Docker multi-stage builds, non-root user, trivy severity policy, blue/green deployment.
- `templates/Dockerfile`: multi-stage Dockerfile template with `<PROJECT_MODULE>` placeholder.
- `templates/.dockerignore`: canonical .dockerignore with 20+ entries.

### Changed
- `RULES.md §8`: made pre-commit + detect-secrets mandatory (previously advisory); expanded remediation to 6 steps.
- `RULES.md §12`: added PR review protocol: approval minimums by PR type, 4 automated pre-merge gates, 7-item reviewer checklist, architectural escalation path.
- `RULES.md §17`: filled "Deployment and Environment Parity" placeholder: env var requirements, 5-gate CI/CD pipeline, blue/green rollback trigger.
- `skills/python-testing.md`: added integration/E2E test section (mock-vs-live boundary table, `@pytest.mark.integration`, `pytest-httpx`/`responses` examples), property-based testing (Hypothesis), mutation testing (mutmut).
- `skills/dashboarding-reporting.md`: added structured output standards: required fields, approved libraries by format, manifest sidecar `write_manifest()` pattern.
- `subagents/subagents.md`: added §4.1 Cross-Agent Skill Reuse and §8.1 Versioning and Lifecycle (semantic versioning, 30-day deprecation policy).
- `subagents/subagents.md §9`: registered `data-collection-agent`.
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`: added containerization and onboarding-checklist to on-demand resource tables.

---

## 2026-05-14

### Added
- `RULES.md §13 AI Agent Compliance`: consolidated agent identity, scope/escalation,
  session startup, and output rules into a dedicated section.
- `CHANGELOG.md`: this file.
- `templates/epilogue.md`: session shutdown protocol; linked from all root context files.

### Changed
- `RULES.md`: fixed duplicate TOC numbering (§12/§13); renumbered placeholders 14–18;
  updated last-modified date.
- `RULES-DRAFTS.md`: replaced five TODO-only placeholder blocks with compact stubs
  containing provisional enforceable defaults agents can apply immediately.
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`: added "Session shutdown protocol" to on-demand resources.
- `README.md`: added RULES-DRAFTS.md and CHANGELOG.md to structure listing; added
  "Closing a session" workflow section; updated epilogue.md description.

---

## 2026-05-11 – 2026-05-12

### Added
- `ralph.sh` agent loop with `--prd`, `--goal`, and `--max` flags; `/ralph` slash command.
- Guard clause in `/prd` sibling skill to prevent sibling-mode from calling `/prd`
  recursively.

### Changed
- `README.md`: updated structure and workflow documentation.
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
- Authorship rules in `RULES.md §6` and all root context files: agents must never
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
- `tools/` directory: deterministic stdlib recipes across 8 domains.

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
- `STRATEGY.md`: multi-agent phased-day project execution strategy.
- Initial PRD plan in `plans/`.

### Changed
- Replaced `pdfplumber` with `pypdf` across all subagent files.
- File cleanup and directory organization.

---

## 2026-04-21

### Added
- `subagents/containerization-agent.md`: Docker and deployment standards.
- `subagents/project-review-accessibility.md`: accessibility deficiency review.
- `subagents/accounting-agent.md`: token usage and cost monitoring.
- `subagents/security-agent.md` and three additional review agents.
- Security assumptions log and no-markdown style rule in subagent protocol.

### Fixed
- Accounting-agent example code from code review feedback.
- Font-size guidance and placeholder name normalization.

---

## 2026-04-16

### Added
- `skills/approved-packages.md`: 26-category authorized library list.

---

## 2026-04-15

### Added
- `RULES.md`: initial mandatory compliance rules (12 sections).
- `_SCRIPTS/create_issues.sh`: bulk GitHub issue creation script.
- WAT framework `profiles/` CLAUDE.md with frontend website rules.

---

## 2026-04-14

### Added
- Initial commit: agent and skill boilerplate templates.
- Comprehensive `subagents/` and `skills/` markdown reference library.
- `templates/`: pyproject.toml, ruff.toml, pytest.ini, .python-version.
- Root context files: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`.
