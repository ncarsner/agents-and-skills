# sessions/ — Session Wiki Pages

Append-only, git-tracked session records for `STRATEGY.md`'s multi-phase
(morning/afternoon/evening) closing ritual (Strategy 1). Replaces that
ritual's old `yyyy-mm-dd-<phase>-summary.md` file with a page indexed in
`index.md`, so a future session can find it by keyword instead of reading
raw history.

This directory does not change the routine, single-session `/epilogue`
protocol (`.claude/commands/epilogue.md`), which still writes a local-only,
gitignored `*-session.md` summary. That convention is intentionally separate
and unaffected.

## Filename

`sessions/yyyy-mm-dd-<phase>.md` — e.g. `sessions/2026-07-29-morning.md`.

## Required sections

```markdown
# Session — yyyy-mm-dd <phase>

## Outcomes
- What shipped, landed, or was verified this session.

## Decisions
- Decisions made, with enough reasoning that a future session or agent does
  not have to rediscover it.

## Cross-References
- Files in `skills/`, `subagents/`, or elsewhere that were touched, or that
  should be read alongside this page.

## Subagent Plan — Next Session
1. <subagent-name>: <one subtask, one sentence>
2. <subagent-name>: <one subtask, one sentence>
```

After writing a page, add a row to `index.md`'s Session Wiki Pages table
with the date, phase, a few keywords, and a link to the page.
