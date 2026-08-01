---
description: Session shutdown protocol — capture the session, refresh CLAUDE.md, update CHANGELOG, commit, push, and produce a closure report
allowed-tools: Bash(git *), Bash(gh *), Bash(find *), Read, Edit, Write, Glob
---

Run this protocol when the user asks to close a session, run the epilogue, or
prepare the repository for handoff. Work through the steps in order. The goal
is simple: preserve what changed, make the next entry point obvious, and
leave git in a state that does not require archaeology.

Do not skip checks. Do not perform destructive git operations. If a command
would overwrite, discard, or rewrite work, stop and ask the user.

## Step 1: Capture the Session

Write a dated Markdown summary before touching the final commit. Prefer the
project root; use `docs/` only when that directory already exists and is
where the project keeps session notes.

Filename format: `yyyy-mm-dd-<descriptor>-session.md` (ISO 8601 date, short
kebab-case descriptor — e.g. `api-cleanup`, `test-hardening`,
`schema-migration`; default to `yyyy-mm-dd-summary-session.md` if nothing
more specific fits).

**Write locally — do not stage this file.** Session files match the
`*-session.md` pattern in `.gitignore` and must never be committed.

Required content:

```markdown
# Session Summary - yyyy-mm-dd

## Completed
- What changed, landed, or was verified.

## Decisions
- Decision made, with enough reasoning that the next agent will not have to
  rediscover it.

## Current State
- What works now, what is partial, and what commands were run.

## Blockers
- Missing information, failing checks, environment issues, or external
  dependencies.

## Next Steps
1. The first concrete thing to do next.
2. The second concrete thing to do next.
```

Keep the summary factual. Include paths, command names, branch names, and
test results when they matter.

## Step 2: Update Skills (if applicable)

If new reusable patterns, integrations, or recipes were developed or
solidified this session, record them so future sessions can reuse them
without rediscovery.

Create a new skill file when a new library/API-client/integration pattern
was built from scratch, a non-obvious technique was discovered that applies
beyond this session, or a pattern was validated and is likely to recur.
Update an existing skill file when a pattern was extended, corrected, or a
new variant/edge case should be added alongside existing content.

Place new files in `skills/` using kebab-case (`skills/<topic>.md`), minimum
structure: one-sentence description, a `## Quick Reference` code block, and
one or more `## Pattern: <name>` sections.

**After creating or updating a skill file, register or update it in
`skills/skills.md`.** Add a row to the reference table with the skill name,
file path, and a one-line description.

If no new patterns emerged this session, skip this step entirely — do not
create placeholder or empty skill files.

## Step 3: Refresh the Context File

`CLAUDE.md` is the only root context file this project produces — there is
no `GEMINI.md` or `AGENTS.md`. It serves as the agent's persistent memory
across sessions. Update it in place rather than creating new lowercase
copies.

**Locating the canonical content when operating inside AGENTS/:** when the
agent materials have been copied into an `AGENTS/` subdirectory of a
downstream project (per `RULES.md` §12), the project root holds only a short
`CLAUDE.md` stub (see `templates/context-file-stub.md`). The full, canonical
content lives at `AGENTS/CLAUDE.md`. Edit that file — never the root stub.

Run this discovery command from the project root to confirm which layout is
in play:

```bash
find . -maxdepth 1 -name "CLAUDE.md" | sort
find . -maxdepth 2 -path "./AGENTS/CLAUDE.md" | sort
```

If `AGENTS/CLAUDE.md` exists, edit that file and leave the root stub
untouched. If no `AGENTS/` directory exists, this is the master-source
repository or a project without the local-only bundle — edit the root
`CLAUDE.md` directly. If neither exists yet, create the root `CLAUDE.md`
from `templates/context-file-stub.md` if an `AGENTS/` bundle is present, or
from scratch at the project root otherwise.

**Never create or modify context files inside `AGENTS/` unless that is the
canonical copy per the check above.** That directory is gitignored and
untracked. **Do not create new lowercase files** (`claude.md`) or
reintroduce `GEMINI.md`/`AGENTS.md` as separate root files.

`CLAUDE.md` holds instructions, not history. Update it only where this
session changed what a future agent must *do*: identity, the on-demand
resource table, writing style, pipeline discipline, delegation rules, or a
resource path that moved. If nothing about the standing instructions changed,
leave the file alone and record that in the checklist.

**Do not add a changelog table, a dated entry, or a session recap to
`CLAUDE.md`.** `CHANGELOG.md` is the single record for what changed and when
(Step 5), and the session summary (Step 1) holds decisions, blockers, and next
steps. `CLAUDE.md` carried a duplicate changelog from 2026-07-12 until
2026-08-01, inherited from the deleted `AGENTS.md`; every row of it was already
in `CHANGELOG.md`. Do not recreate it.

## Step 4: Confirm Git and Remote

Make sure the project is a git repository and has a reachable `origin`
remote:

```bash
set -euo pipefail

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
fi

if [ ! -d .git ]; then
  git init
  echo "Initialized local git repository."
fi

git status --short

if ! git remote get-url origin >/dev/null 2>&1; then
  REPO_NAME=$(basename "$PWD")
  gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
  echo "Created private GitHub repository and configured origin: $REPO_NAME"
else
  git remote get-url origin
fi
```

Use `gh repo create` only when `origin` is missing. If `origin` already
exists, do not replace it.

## Step 5: Update CHANGELOG (if applicable)

If the session produced anything a future reader would consider notable — a
new feature, a bug fix, a breaking change, or a significant refactor — add
an entry to `CHANGELOG.md` now, before the commit step.

**When to skip:** if nothing this session would appear under Added, Changed,
or Fixed in a public changelog, skip this step and document the reason in
the Closure Checklist.

**Format (match existing `CHANGELOG.md`):**

```markdown
## [Unreleased]

### Added
- Brief description of new capability or file.

### Changed
- Brief description of a behavior, interface, or default that changed.

### Fixed
- Brief description of a bug that was resolved.
```

Draw 3-8 bullets from session context, do not invent or embellish, omit
sections with no entries, place the new entry under `## [Unreleased]` if it
exists (otherwise above the most recent dated heading), and use
present-tense imperative phrasing ("Add …", "Fix …", "Remove …").

## Step 6: Review, Stage, Commit, and Push

Inspect the worktree before staging:

```bash
git status
git diff --stat
git diff
```

Before `git add`, check for secrets and accidental local-only files: `.env`,
`.env.*`, credential files, API keys, tokens, private keys, local caches,
generated junk, editor files, machine-specific config, or large artifacts
that do not belong in git.

Stage the intended changes, then commit with a dated, meaningful message and
push:

```bash
git add -A
git status
git commit -m "yyyy-mm-dd: close session - <brief outcome>"
BRANCH=$(git branch --show-current)
git push origin "$BRANCH" || git push --set-upstream origin "$BRANCH"
```

If there is nothing to commit, do not manufacture a commit. Record that the
worktree had no staged changes and continue to the verification step.

## Step 7: Verify Clean State

```bash
git status
git log --oneline -5
git remote -v
```

Expected `git status` result: `nothing to commit, working tree clean`. If
the worktree is not clean, identify why — commit intentional leftovers or
report why they must remain uncommitted. Do not hide unresolved state.

## Step 8: Closure Checklist

Report each item as done, skipped with reason, or blocked:

- [ ] Session summary written locally (not staged — gitignored), with
      completed work, decisions, current state, blockers, and next steps.
- [ ] New or updated skill files written to `skills/` and registered in
      `skills/skills.md` (or skipped — no new patterns this session).
- [ ] CHANGELOG.md updated with session entry, or skipped — nothing notable.
- [ ] `.gitignore` includes `*-session.md` pattern.
- [ ] `CLAUDE.md` located via the discovery command (root stub vs.
      `AGENTS/CLAUDE.md` canonical copy) and updated in the correct
      location, or left unchanged because the standing instructions did not
      change; no changelog table, dated entry, or session recap added to it;
      no files created inside `AGENTS/` beyond the canonical copy; no new
      lowercase copies or `GEMINI.md`/`AGENTS.md` files created.
- [ ] Secrets and local-only files were checked before staging.
- [ ] Intended changes were committed using Conventional Commits format
      (RULES.md §6), or there was nothing to commit.
- [ ] Current branch was pushed, or the push blocker is documented.
- [ ] `git status` confirms clean working tree after push.
- [ ] Final next steps are visible in the summary and final report.

## Step 9: Final Report

End with a compact report the user can scan quickly:

```text
Session closed: yyyy-mm-dd
Branch: <branch-name>
Commit: <short-sha> — <commit message, or "no commit needed">
Remote: <origin-url, or blocker>
CHANGELOG: <updated | skipped — reason>
Skills: <files created or updated, or "none — no new patterns this session">
Context file: <CLAUDE.md updated, or "none present">
Status: <clean / not clean with reason>

Next steps:
1. <first next step>
2. <second next step>
```

If any step could not be completed, make that visible in `Status` and list
the specific command or condition that blocked it. A clean shutdown is
ideal; an honest handoff is mandatory.

## Naming Reference

| Purpose              | Filename                                      |
|-----------------------|-----------------------------------------------|
| Session summary        | `2026-04-27-summary-session.md`               |
| API cleanup session    | `2026-04-27-api-cleanup-session.md`           |
| Bug investigation      | `2026-04-27-login-timeout-session.md`         |
| Test work               | `2026-04-27-coverage-hardening-session.md`    |
| Migration planning      | `2026-04-27-schema-migration-session.md`      |
| New skill file          | `skills/redis-caching.md`                     |

Use lowercase kebab-case after the date. Avoid spaces, underscores, and
vague names like `notes.md`.
