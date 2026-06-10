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

## 3. Refresh Context Files

Update every root-level context file that exists in the destination project.
These files serve as the agent's persistent memory across sessions — update them
in place rather than creating new lowercase copies.

| Agent      | Context file |
|------------|--------------|
| Claude     | `CLAUDE.md`  |
| Gemini CLI | `GEMINI.md`  |
| Codex      | `AGENTS.md`  |
| Perplexity | `AGENTS.md`  |

### Locating context files when operating inside AGENTS/

When the agent materials have been copied into an `AGENTS/` subdirectory of a
downstream project (per RULES.md §12), the context files live at the project
root — one level above `AGENTS/`. The agent must locate them before editing.

Run this discovery command from the project root or from within `AGENTS/`:

```bash
# From the project root
find . -maxdepth 1 -name "CLAUDE.md" -o -name "GEMINI.md" -o -name "AGENTS.md" | sort

# From inside AGENTS/
find .. -maxdepth 1 -name "CLAUDE.md" -o -name "GEMINI.md" -o -name "AGENTS.md" | sort
```

Use the paths returned by the discovery command. If the command returns no
results, the context files have not been created yet — create them at the
project root (not inside `AGENTS/`).

**Never create or modify context files inside the `AGENTS/` directory.** That
directory is gitignored and untracked; files placed there will not persist in
the downstream repository.

### Updating context files

Each context file should reflect the repository as it stands after this session:
- Current phase and status.
- Important files added or changed today, with their purpose.
- Decisions made today, dated.
- Known blockers or risks.
- Next steps, replacing any stale items.

**Do not create new lowercase files** (`claude.md`, `gemini.md`, `agents.md`).
Update the existing uppercase files at the project root. If a context file does
not exist yet, create it at the project root using its correct uppercase name.

If more than one context file exists, keep the shared project-state content in
sync. Verify parity with all files that are present (run from the project root):

```bash
diff CLAUDE.md GEMINI.md
diff CLAUDE.md AGENTS.md
diff GEMINI.md AGENTS.md
```

No output means the compared files match. If a file is absent, skip only that
specific comparison and note that it was not present.

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
- [ ] Root context files (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`) located via
      discovery command and updated at the project root; no files created inside
      `AGENTS/`; no new lowercase copies created.
- [ ] Context files compared and synchronized where more than one exists.
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
Context files: <updated files, or "none present">
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
