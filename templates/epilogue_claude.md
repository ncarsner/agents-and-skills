# Epilogue Claude — End-of-Day Session Closure

This document is a standing instruction for AI agents. When invoked at the end of a
work session, execute every section in order. Do not skip steps. Do not ask for
confirmation unless a destructive action is explicitly flagged below.

---

## Purpose

Close the day with a clean repo, updated context, and a dated summary so the next
session can resume immediately without overhead.

---

## 1. Generate a Dated Session Summary

Create a summary file using the naming convention:

```
yyyy-mm-dd-<content>.md
```

- `yyyy-mm-dd` — ISO 8601 date (e.g., `2026-04-27`)
- `<content>` — kebab-case descriptor of what was worked on (e.g., `session-summary`,
  `auth-refactor`, `pipeline-design`, `project-kickoff`)
- Examples: `2026-04-27-session-summary.md`, `2026-04-27-database-schema-decisions.md`

Write the file to the project root (or `docs/` if that directory exists).

**Minimum content for a session summary:**

```markdown
# Session Summary — yyyy-mm-dd

## What Was Accomplished
- Bullet list of completed work

## Decisions Made
- Decision and the reasoning behind it (this is the part that rots fastest — be explicit)

## Current State
- Where the project stands right now

## Blockers / Open Questions
- Anything unresolved

## Next Steps
- Ordered list of what to do first in the next session
```

---

## 2. Update Context Files

Update all context files that exist in the project root so they reflect the current
state. Keep them concise — reference other files rather than duplicating content.

| Tool       | Context file  |
|------------|---------------|
| Claude     | `claude.md`   |
| Gemini CLI | `gemini.md`   |
| Codex      | `agents.md`   |

**What to update:**
- Current phase / status
- Key files and their purpose (add any new ones created today)
- Decisions made (append with today's date)
- Next steps (replace stale items with current ones)

**Sync rule:** If more than one context file exists, make all of them identical in
content after updating. Use this command pattern to verify:

```bash
diff claude.md gemini.md
diff claude.md agents.md
```

No output means they are in sync.

---

## 3. Initialize a Remote GitHub Repository (if not already initialized)

Run this check-and-initialize sequence. Each step is conditional.

```bash
# Step 1 — Confirm this is a git repo; initialize if not
if [ ! -d .git ]; then
  git init
  echo "Git repository initialized."
fi

# Step 2 — Check for a remote named 'origin'
if ! git remote get-url origin &>/dev/null; then
  # Derive a repo name from the current directory
  REPO_NAME=$(basename "$PWD")

  # Create a private GitHub repo and add it as origin
  gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
  echo "Remote repository created: $REPO_NAME"
else
  echo "Remote 'origin' already configured: $(git remote get-url origin)"
fi
```

> **Prerequisite:** `gh` (GitHub CLI) must be authenticated. Run `gh auth status`
> to verify. If not authenticated, run `gh auth login` before this step.

---

## 4. Stage, Commit, and Push

```bash
# Show current status before staging
git status

# Stage all tracked modifications and new files
# Review the list — do NOT stage secrets, .env files, or credentials
git add -A

# Commit with a dated message
git commit -m "$(date +%Y-%m-%d): end-of-day session commit"

# Push to origin
git push origin "$(git branch --show-current)"
```

If the push fails because the remote branch does not exist yet:

```bash
git push --set-upstream origin "$(git branch --show-current)"
```

---

## 5. Verify Clean State

```bash
git status
git log --oneline -5
```

Expected output from `git status`: `nothing to commit, working tree clean`

If there are still uncommitted changes, stage and commit them before proceeding.

---

## 6. End-of-Day Checklist

Work through this list and report the result of each item:

- [ ] Dated session summary written (`yyyy-mm-dd-<content>.md`)
- [ ] Context files updated (`claude.md` / `gemini.md` / `agents.md`)
- [ ] Context files in sync (diff shows no differences)
- [ ] Remote repository exists and is reachable
- [ ] All changes committed with a meaningful message
- [ ] Branch pushed to remote
- [ ] `git status` shows clean working tree
- [ ] No secrets or credentials staged or committed
- [ ] Next steps recorded in session summary

---

## 7. Final Report to User

After completing all steps, output a brief report in this format:

```
Session closed: yyyy-mm-dd
Summary written: <filename>
Commit: <short SHA> — <commit message>
Remote: <repo URL>
Next steps:
  1. <first item from Next Steps in summary>
  2. <second item>
  ...
```

---

## Reference: Naming Convention Quick Guide

| Use case               | Format                          | Example                                |
|------------------------|---------------------------------|----------------------------------------|
| Session summary        | `yyyy-mm-dd-session-summary.md` | `2026-04-27-session-summary.md`        |
| Decision record        | `yyyy-mm-dd-<topic>-decisions.md` | `2026-04-27-auth-decisions.md`       |
| Research output        | `yyyy-mm-dd-<topic>-research.md` | `2026-04-27-database-options.md`     |
| Design / architecture  | `yyyy-mm-dd-<topic>-design.md`  | `2026-04-27-api-design.md`             |
| Retrospective          | `yyyy-mm-dd-retro.md`           | `2026-04-27-retro.md`                  |

All dates use **ISO 8601** (`yyyy-mm-dd`). All `<content>` slugs use **kebab-case**
(lowercase, hyphens, no spaces or underscores).
