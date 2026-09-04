# index.md: Content Catalog

Queryable catalog of session wiki pages and key repo reference docs. Grep
this file for task-domain keywords:

- at session open (see `STRATEGY.md §1`, `.claude/skills/orient/SKILL.md`)
- before invoking a subagent (see `subagents/subagents.md §2.1`)

then load only the matching pages instead of re-synthesizing context from
scratch. Closes 12-Factor Agents F13 (pre-fetch context), see
`.12-FACTOR-AGENTS.md`.

## Division of Labor

`CHANGELOG.md` records **what changed and when**. `index.md` records **where
to look for depth on topic X**. Do not restate changelog entries here; point
at them. A row's `Doc` target must be tracked in git so it resolves in a fresh
clone, a CI checkout, or a worktree. Session summaries matching `*-session.md`
are gitignored and must never be cited as a row target; cite the corresponding
`CHANGELOG.md` date heading instead.

`/epilogue` (Step 5a) updates this file at every session close.

## Session Wiki Pages

Pages live at the project root as `sessions/yyyy-mm-dd-<phase>.md`. The
format spec is `sessions/README.md` in the bundle, which is
`AGENTS/sessions/README.md` downstream and `sessions/README.md` here
(RULES.md §12). Add one row here when writing a page at session close.

Empty by design: no tracked session wiki page exists yet. The first page
written under `sessions/` gets the first row.

| Date | Phase | Keywords | Page |
|------|-------|----------|------|

## Repo Reference Docs

Existing dated docs, indexed for keyword lookup until migrated into the
`sessions/` wiki format.

| Date | Keywords | Doc |
|------|----------|-----|
| 2026-05-14 | ralph loop, PRD mode, epilogue changelog steps | `CHANGELOG.md` [2026-05-14](CHANGELOG.md#2026-05-14) |
| 2026-05-17 | worktrees, karpathy wiki, background agent isolation, branch naming | `_SOLUTIONS/2026-05-17-karpathy-wiki.md` |
| 2026-05-17 | rules refactor, profile extraction, scope markers | `CHANGELOG.md` [2026-05-17](CHANGELOG.md#2026-05-17) |
| 2026-05-17 | 12-factor agents, F5, F13, karpathy wiki lens, pre-fetch | `.12-FACTOR-AGENTS.md` |
| 2026-06-01 | token economization, session efficiency, RULES-BRIEF.md | `CHANGELOG.md` [2026-06-01](CHANGELOG.md#2026-06-01) |
| 2026-06-10 | pipeline discipline, gates, ideate, grill-me, prd, ralph | `CHANGELOG.md` [2026-06-10](CHANGELOG.md#2026-06-10) |
| 2026-06-18 | authorship, attribution, RULES.md §18, co-authored-by | `CHANGELOG.md` [2026-06-18](CHANGELOG.md#2026-06-18) |
| 2026-07-12 | rules-drafts cleanup, registry drift, AGENTS.md consolidation, epilogue command | `CHANGELOG.md` [2026-07-12](CHANGELOG.md#2026-07-12) |
| 2026-07-29 | issue triage, content catalog, index.md, sessions wiki format | `CHANGELOG.md` [2026-07-29](CHANGELOG.md#2026-07-29) |
| 2026-09-04 | AGENTS.md rename, em dash scrub, markdown anchors, attribution hook, pip-audit flags | `CHANGELOG.md` [2026-09-04](CHANGELOG.md#2026-09-04) |
