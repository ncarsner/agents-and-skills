# Epilogue Gemini — Session Closure Protocol

This document serves as the mandatory protocol for finalizing a work session. When you are instructed to "close the session" or "run the epilogue," you must execute these steps in order to preserve context and ensure a seamless handoff to the next session.

---

## 1. PURPOSE
The goal of this protocol is to capture the "volatile memory" of the current session and commit it to the repository's "long-term memory." By following these steps, you ensure that the next agent (or the human developer) can resume work with zero overhead, fully aware of the current state, recent decisions, and the immediate path forward.

---

## 2. NAMING CONVENTION
All dated output files generated during or at the end of a session MUST follow the ISO 8601 date prefix combined with a kebab-case descriptor.

**Format:** `yyyy-mm-dd-<content>.md`

### Example Reference Table
| Content Type | Filename Example |
| :--- | :--- |
| **Session Summary** | `2026-04-27-session-summary.md` |
| **Architectural Decision** | `2026-04-27-db-migration-plan.md` |
| **Bug Investigation** | `2026-04-27-reproduction-notes.md` |
| **Meeting / Discussion** | `2026-04-27-stakeholder-sync.md` |
| **Technical Research** | `2026-04-27-package-comparison.md` |

---

## 3. SESSION SUMMARY
Generate a summary of the day's work in a new file named `yyyy-mm-dd-session-summary.md`. This file should be placed in the project root.

**Required Sections:**
- **Accomplished:** A high-level list of completed tasks, features implemented, or bugs fixed.
- **Decisions Made:** Critical architectural or logical choices. Explain *why* a path was taken to prevent future "why did we do this?" loops.
- **Current State:** A snapshot of the codebase's health (e.g., "Tests passing," "Feature X is 50% complete but doesn't compile").
- **Blockers:** Any external dependencies, missing information, or technical hurdles preventing progress.
- **Next Steps:** A concrete, prioritized list of tasks for the next session.

---

## 4. CONTEXT FILE UPDATES
Context files are the foundation of the agent's understanding. You must update the following files to reflect the session's outcomes:
- `gemini.md`
- `claude.md`
- `agents.md`

**Synchronization Requirement:**
Update the primary context file (`gemini.md`) first, then synchronize the others. They should remain identical in their core "state" sections and identical in file size.

**Verification Step:**
Run the following to ensure parity:
```bash
diff gemini.md claude.md && diff gemini.md agents.md
```
*If there is any output, the files are out of sync. Resolve the differences immediately.*

---

## 5. GITHUB INITIALIZATION
If the project is not already connected to a remote GitHub repository, you must initialize it now.

**Bash Script for Initialization:**
```bash
# 1. Prerequisite: Check GitHub CLI authentication
if ! gh auth status &>/dev/null; then
  echo "Error: GitHub CLI (gh) is not authenticated. Please run 'gh auth login'."
  exit 1
fi

# 2. Check if this is a git repo
if [ ! -d .git ]; then
  git init
  echo "Initialized local git repository."
fi

# 3. Check for remote 'origin'
if ! git remote get-url origin &>/dev/null; then
  REPO_NAME=$(basename "$PWD")
  echo "No remote found. Creating private GitHub repository: $REPO_NAME..."
  gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
else
  echo "Remote 'origin' already exists."
fi
```

---

## 6. COMMIT AND PUSH
Capture all changes in a final session commit.

**Warning:** Before staging, scan for sensitive information. Never commit `.env` files, API keys, or hardcoded credentials.

**Execution:**
1. **Stage Changes:** `git add .`
2. **Commit:** `git commit -m "yyyy-mm-dd: session closure - <brief summary of main achievement>"`
3. **Push:** `git push origin $(git branch --show-current)`

---

## 7. CLEAN STATE VERIFICATION
Verify that the workspace is in a known, stable state.

**Check:**
```bash
git status
```
*Requirement:* The output must confirm "nothing to commit, working tree clean". If files remain unstaged, investigate why they were omitted and resolve before exiting.

---

## 8. FINAL CHECKLIST
Ensure all steps are complete before reporting back to the user:

- [ ] Dated session summary file created (`yyyy-mm-dd-session-summary.md`).
- [ ] `gemini.md`, `claude.md`, and `agents.md` updated and synchronized.
- [ ] `diff` check confirms context file parity.
- [ ] Git remote initialized and connected via `gh`.
- [ ] Workspace scanned for secrets/credentials.
- [ ] All changes committed with a dated message and pushed to remote.
- [ ] `git status` confirms a clean working tree.

---

## 9. FINAL REPORT FORMAT
Upon completion, provide a concise final report to the user:

```text
### Session Closure Complete
**Date:** yyyy-mm-dd
**Summary File:** yyyy-mm-dd-session-summary.md
**Commit SHA:** [short-sha]
**Branch:** [branch-name]
**Status:** Workspace clean, remote updated.

**Immediate Next Steps:**
1. [First item from session summary]
2. [Second item from session summary]
```
