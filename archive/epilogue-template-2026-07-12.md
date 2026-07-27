> **Archived 2026-07-12.** This is the last version of the epilogue protocol
> in template form, before conversion to `.claude/commands/epilogue.md`
> (invoked as `/epilogue`). Kept for reference only — not tracked by
> `.file_list` and not shipped to downstream copies. See `CHANGELOG.md`
> under 2026-07-12 for the conversion rationale.

---

# Epilogue — Session Shutdown Protocol

Use this protocol when the user asks to close a session, run the epilogue, or
prepare the repository for handoff. Work through the steps in order. The goal is
simple: preserve what changed, make the next entry point obvious, and leave git in
a state that does not require archaeology.

Do not skip checks. Do not perform destructive git operations. If a command would
overwrite, discard, or rewrite work, stop and ask the user.

---

## 1. Capture the Session

Write a dated Markdown summary before touching the final commit. Prefer the
project root; use `docs/` only when that directory already exists and is where
the project keeps session notes.

Filename format:

```text
yyyy-mm-dd-<descriptor>-session.md
```

Rules:
- Use ISO 8601 dates, such as `2026-04-27`.
- Use a short kebab-case descriptor, such as `api-cleanup`,
  `test-hardening`, or `schema-migration`.
- Default to `yyyy-mm-dd-summary-session.md` unless a more specific descriptor
  makes the file easier to find later.

**Write locally — do not stage this file.** Session files match the
`*-session.md` pattern in `.gitignore` and must never be committed. Write the
file, then continue to the next step.

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

Keep the summary factual. Include paths, command names, branch names, and test
results when they matter.

---

## 2. Update Skills (if applicable)

If new reusable patterns, integrations, or recipes were developed or solidified
during this session, record them so future sessions can reuse them without
rediscovery.

**When to create a new skill file:**
- A new library, API client, or integration pattern was built from scratch.
- A non-obvious technique was discovered that applies beyond this session.
- A pattern was validated and is likely to recur in other projects.

**When to update an existing skill file:**
- An existing pattern was extended, corrected, or made more complete.
- A new variant or edge case should be added alongside the existing content.

**How to create a new skill file:**

Place the file in `skills/` using kebab-case:

```text
skills/<topic>.md
```

Minimum structure:

```markdown
# Skill: <Topic Name>

One-sentence description of what this skill covers.

---

## Quick Reference

\`\`\`bash
# install commands or key one-liners
\`\`\`

---

## Pattern: <Pattern Name>

Explanation and example code.
```

**After creating or updating a skill file, register or update it in `skills/skills.md`.**
Add a row to the skill registry table with the skill name, file path, and a
one-line description. If a skill was updated, verify the description still
matches the expanded content.

If no new patterns emerged this session, skip this step entirely — do not create
placeholder or empty skill files.

---

## 3. Refresh the Context File

`CLAUDE.md` is the only root context file this project produces — there is no
`GEMINI.md` or `AGENTS.md`. It serves as the agent's persistent memory across
sessions. Update it in place rather than creating new lowercase copies.

### Locating the canonical content when operating inside AGENTS/

When the agent materials have been copied into an `AGENTS/` subdirectory of a
downstream project (per RULES.md §12), the project root holds only a short
`CLAUDE.md` **stub** (see `templates/context-file-stub.md`). The full,
canonical content lives at `AGENTS/CLAUDE.md`. Edit that file — never the
root stub.

Run this discovery command from the project root or from within `AGENTS/` to
confirm which layout is in play:

```bash
# From the project root
find . -maxdepth 1 -name "CLAUDE.md" | sort
find . -maxdepth 2 -path "./AGENTS/CLAUDE.md" | sort

# From inside AGENTS/
find . -maxdepth 1 -name "CLAUDE.md" | sort
```

If `AGENTS/CLAUDE.md` exists, edit that file and leave the root stub
untouched (it should never contain more than the template). If no `AGENTS/`
directory exists, this is the master-source repository or a project without
the local-only bundle — edit the root `CLAUDE.md` directly. If neither exists
yet, create the root `CLAUDE.md` from `templates/context-file-stub.md` if an
`AGENTS/` bundle is present, or from scratch at the project root otherwise.

**Never create or modify context files inside the `AGENTS/` directory unless
that is the canonical copy per the layout check above.** The directory is
gitignored and untracked; anything else placed there will not persist in the
downstream repository.

### Updating the context file

The canonical `CLAUDE.md` (root, or `AGENTS/CLAUDE.md` in the local-only
layout) should reflect the repository as it stands after this session:
- Current phase and status.
- Important files added or changed today, with their purpose.
- Decisions made today, dated.
- Known blockers or risks.
- Next steps, replacing any stale items.

**Do not create new lowercase files** (`claude.md`) or reintroduce
`GEMINI.md`/`AGENTS.md` as separate root files. There is exactly one
canonical copy per project — the root `CLAUDE.md` in the master-source
layout, or `AGENTS/CLAUDE.md` behind a root stub in the local-only layout.

---

## 4. Confirm Git and Remote

Make sure the project is a git repository and has a reachable `origin` remote.

```bash
set -euo pipefail

# 1. Prerequisite: verify GitHub CLI authentication
if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
fi

# 2. Initialize git if needed
if [ ! -d .git ]; then
  git init
  echo "Initialized local git repository."
fi

git status --short

# 3. Create remote only if origin is missing
if ! git remote get-url origin >/dev/null 2>&1; then
  REPO_NAME=$(basename "$PWD")
  gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
  echo "Created private GitHub repository and configured origin: $REPO_NAME"
else
  git remote get-url origin
fi
```

Use `gh repo create` only when `origin` is missing. If `origin` already exists,
do not replace it.

---

## 5. Update CHANGELOG (if applicable)

If the session produced anything a future reader would consider notable — a new
feature, a bug fix, a breaking change, or a significant refactor — add an entry
to `CHANGELOG.md` now, before the commit step.

**When to skip:** If nothing this session would appear under Added, Changed, or
Fixed in a public changelog, skip this step and document the reason in the
Closure Checklist (e.g., "skipped — internal refactor only, nothing user-facing").

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

Rules:
- Draw 3–8 bullets from session context. Do not invent or embellish.
- Omit sections that have no entries rather than leaving them empty.
- Place the new entry under `## [Unreleased]` if that section exists; otherwise
  add it above the most recent dated release heading.
- Use present-tense imperative phrasing: "Add …", "Fix …", "Remove …".

---

## 6. Review, Stage, Commit, and Push

Inspect the worktree before staging:

```bash
git status
git diff --stat
git diff
```

Before `git add`, check for secrets and accidental local-only files:
- `.env`, `.env.*`, credential files, API keys, tokens, private keys.
- Local caches, generated junk, editor files, or machine-specific config.
- Large artifacts that do not belong in git.

Stage the intended changes:

```bash
git add -A
git status
```

Commit with a dated, meaningful message:

```bash
git commit -m "yyyy-mm-dd: close session - <brief outcome>"
```

Push the current branch:

```bash
BRANCH=$(git branch --show-current)
git push origin "$BRANCH"
```

If the upstream branch does not exist yet:

```bash
git push --set-upstream origin "$BRANCH"
```

If there is nothing to commit, do not manufacture a commit. Record that the
worktree had no staged changes and continue to the verification step.

---

## 7. Verify Clean State

Run the final checks:

```bash
git status
git log --oneline -5
git remote -v
```

Expected `git status` result:

```text
nothing to commit, working tree clean
```

If the worktree is not clean, identify why. Commit intentional leftovers or
report why they must remain uncommitted. Do not hide unresolved state.

---

## 8. Closure Checklist

Report each item as done, skipped with reason, or blocked:

- [ ] Session summary written locally (not staged — gitignored), with completed
      work, decisions, current state, blockers, and next steps.
- [ ] New or updated skill files written to `skills/` and registered in
      `skills/skills.md` (or skipped — no new patterns this session).
- [ ] CHANGELOG.md updated with session entry, or skipped — nothing notable.
- [ ] `.gitignore` includes `*-session.md` pattern.
- [ ] `CLAUDE.md` located via the discovery command (root stub vs.
      `AGENTS/CLAUDE.md` canonical copy) and updated in the correct location;
      no files created inside `AGENTS/` beyond the canonical copy; no new
      lowercase copies or `GEMINI.md`/`AGENTS.md` files created.
- [ ] Secrets and local-only files were checked before staging.
- [ ] Intended changes were committed using Conventional Commits format
      (RULES.md §6), or there was nothing to commit.
- [ ] Current branch was pushed, or the push blocker is documented.
- [ ] `git status` confirms clean working tree after push.
- [ ] Final next steps are visible in the summary and final report.

---

## 9. Final Report

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

If any step could not be completed, make that visible in `Status` and list the
specific command or condition that blocked it. A clean shutdown is ideal; an
honest handoff is mandatory.

---

## Naming Examples

| Purpose              | Filename                                      |
|----------------------|-----------------------------------------------|
| Session summary      | `2026-04-27-summary-session.md`               |
| API cleanup session  | `2026-04-27-api-cleanup-session.md`           |
| Bug investigation    | `2026-04-27-login-timeout-session.md`         |
| Test work            | `2026-04-27-coverage-hardening-session.md`    |
| Migration planning   | `2026-04-27-schema-migration-session.md`      |
| New skill file       | `skills/redis-caching.md`                     |

Use lowercase kebab-case after the date. Avoid spaces, underscores, and vague
names like `notes.md`.
