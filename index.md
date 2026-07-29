# index.md — Content Catalog

Queryable catalog of session wiki pages and key repo reference docs. Grep
this file for task-domain keywords:

- at session open (see `STRATEGY.md §1`, `.claude/skills/orient/SKILL.md`)
- before invoking a subagent (see `subagents/subagents.md §2.1`)

then load only the matching pages instead of re-synthesizing context from
scratch. Closes 12-Factor Agents F13 (pre-fetch context) — see
`.12-FACTOR-AGENTS.md`.

## Session Wiki Pages

Pages follow the `sessions/yyyy-mm-dd-<phase>.md` format defined in
`sessions/README.md`. Add one row here when writing a page at session close.

| Date | Phase | Keywords | Page |
|------|-------|----------|------|
| | | | |

## Repo Reference Docs

Existing dated docs, indexed for keyword lookup until migrated into the
`sessions/` wiki format.

| Date | Keywords | Doc |
|------|----------|-----|
| 2026-05-14 | ralph loop, PRD mode, epilogue changelog steps | `_SOLUTIONS/2026-05-14-ralph-loop.log` |
| 2026-05-17 | worktrees, karpathy wiki, background agent isolation, branch naming | `_SOLUTIONS/2026-05-17-karpathy-wiki.md` |
| 2026-05-17 | rules refactor, profile extraction, scope markers | `_SOLUTIONS/2026-05-17-rules-refactor-session.md` |
| 2026-05-17 | 12-factor agents, F5, F13, karpathy wiki lens, pre-fetch | `.12-FACTOR-AGENTS.md` |
| 2026-06-01 | token economization, session efficiency, RULES-BRIEF.md | `2026-06-01-token-economization-session.md` |
| 2026-06-10 | pipeline discipline, gates, ideate, grill-me, prd, ralph | `2026-06-10-pipeline-gates-session.md` |
| 2026-06-18 | authorship, attribution, RULES.md §18, co-authored-by | `2026-06-18-authorship-hardening-session.md` |
| 2026-07-12 | rules-drafts cleanup, registry drift, AGENTS.md consolidation, epilogue command | `2026-07-12-agents-cleanup-session.md` |
