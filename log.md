# log.md — Append-Only Execution Record

Single source of truth for `ralph.sh` loop execution state. One line per
iteration, appended only, never edit or reorder past entries. Replaces the
retired `plans/*-progress.txt` pattern (Karpathy wiki lens, see
`.12-FACTOR-AGENTS.md`).

## Schema

```
[timestamp] [task_id] [status] [err_count] [summary]
```

- `timestamp` — UTC ISO 8601, `date -u +%Y-%m-%dT%H:%M:%SZ`
- `task_id` — the PRD task id (`--prd` mode) or a kebab-case slug of the task
  description (general mode)
- `status` — `done` (task completed this iteration), `blocked` (iteration
  failed, will retry), `failed` (max iterations reached without success)
- `err_count` — number of failed attempts at this `task_id` prior to this
  entry (`0` on first-try success)
- `summary` — one-line description of what changed

## Entries

<!-- Migrated from plans/epilogue-refinements-prd-progress.txt on 2026-07-29.
     plans/test-coverage-progress.txt was empty at migration time. -->
[2026-05-14T00:00:00Z] [epilogue-changelog-step] [done] [0] iter=1: inserted Step 4.5 (conditional CHANGELOG update) between Step 4 and old Step 5; renumbered Steps 5-8 to 6-9 in templates/epilogue.md
[2026-05-14T00:00:00Z] [epilogue-step1-local-only] [done] [0] iter=2: updated filename format to yyyy-mm-dd-<descriptor>-session.md, added local-only/do-not-stage note citing .gitignore, updated naming examples table in templates/epilogue.md
[2026-05-14T00:00:00Z] [epilogue-checklist-audit] [done] [0] iter=3: removed 'Git repository exists locally' and 'origin remote exists and is reachable' items; added CHANGELOG.md and .gitignore *-session.md checklist items; reworded commit-message item to reference Conventional Commits (RULES.md §6); reworded summary item to local-only language
[2026-05-14T00:00:00Z] [epilogue-final-report] [done] [0] iter=4: replaced Summary field with CHANGELOG field, reordered Final Report fields to: Session closed -> Branch -> Commit -> Remote -> CHANGELOG -> Skills -> Context files -> Status -> Next steps in templates/epilogue.md
[2026-05-14T00:00:00Z] [gitignore-session-pattern] [done] [0] iter=5: added *-session.md to Project-specific section of .gitignore
[2026-05-14T00:00:00Z] [remove-dated-root-files] [done] [0] iter=6: removed 6 tracked dated analysis files (2026-05-10/11 *.md) from repo root via git rm
