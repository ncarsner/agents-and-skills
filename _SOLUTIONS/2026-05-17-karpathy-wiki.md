# Worktrees in This Repo — Benefits, Tradeoffs, and Refactoring Opportunities

Date: 2026-05-17  
Context: Background agent isolation via Claude Code harness; Karpathy wiki lens applied to 12-factor analysis

---

## What a Git Worktree Is

A git worktree is a linked working directory that shares a single `.git` object store with a parent repository. Every tracked file is checked out into the worktree's directory, but git objects (commits, blobs, trees) are not duplicated — they live once in the parent's object store. Each worktree must be on a unique branch; the same branch cannot be active in two worktrees simultaneously.

The worktree's root contains a `.git` file (not a directory) that points back to the parent repo's gitdir, plus a full copy of every tracked file on its branch.

---

## How the Claude Code Harness Uses Worktrees

The harness creates worktrees under `.claude/worktrees/<name>/` inside the main repo directory. When a background session starts, the harness calls `EnterWorktree`, which runs `git worktree add` and switches the session's working directory to the new path. The purpose is isolation: changes made by a background agent land on a separate branch and do not pollute the user's main working copy.

This session's worktree lives at:

```
/Users/carsner/Code/agents-and-skills/.claude/worktrees/12-factor-karpathy-extension/
```

Branch: `feat-20260517-karpathy-wiki` (renamed from the auto-generated `worktree-12-factor-karpathy-extension`).

---

## Is This Duplication?

**At the git object level: no.** Blobs, trees, and commits are shared. The parent repo's object store is the single source of truth. Creating a worktree does not copy git history.

**At the filesystem level: yes.** Every tracked file on the checked-out branch is copied into the worktree directory. For this repo that means a full copy of `skills/`, `subagents/`, `templates/`, `tools/`, `plans/`, and all root markdown files — the same byte-for-byte content as the main checkout, on the branch the worktree was created from.

**Practical size for this repo:** The repo is docs-first (markdown + shell). No compiled artifacts, no `node_modules`, no `.venv`. A worktree adds roughly the same disk footprint as the main checkout — small (order of magnitude: single-digit MB). Disk duplication is not a problem here.

**The more significant duplication is conceptual.** `skills/`, `subagents/`, and `templates/` are reference libraries. They are read-only from the perspective of most background tasks. Duplicating them into every worktree means:

1. A background agent that improves a `skills/` doc writes the improvement to the worktree copy, which must then be merged back to main before the improvement is visible to future sessions.
2. If two worktrees both modify the same skills doc, merge conflicts arise even though neither task was logically related to that file.

---

## Benefits of Worktrees for This Repo

**Background agent isolation.** The primary use case. A background agent (e.g., this session) works on a branch without disturbing the user's main working copy. The user can continue editing on `main` while the agent works in the worktree.

**No stash/checkout dance.** Switching context does not require stashing uncommitted work. Main and worktree coexist with independent working directories.

**Parallel branch work.** Multiple worktrees can be active simultaneously on different branches. For a docs repo with several open GitHub issues being worked in parallel, each gets its own isolated directory.

**Lightweight for docs.** No build artifacts to duplicate. Worktree creation is fast and low-cost.

**Harness-native safety.** Claude Code's isolation guard prevents background edits from landing in the user's live checkout without an explicit merge step.

---

## Tradeoffs

| Tradeoff | Detail |
|----------|--------|
| Untracked files do not transfer | Files not yet committed to git are invisible to the worktree. This session had to manually copy `.12-FACTOR-AGENTS.md` into the worktree because it was untracked in main. Workflow friction when a task builds on in-progress work. |
| Nested worktree path | `.claude/worktrees/` is inside the main repo directory. Most git workflows place worktrees as siblings (`../repo-worktree/`), not children. The nested path is non-standard and can confuse tools that walk parent directories looking for `.git`. |
| `.claude/worktrees/` not in `.gitignore` | Git correctly recognizes worktree directories and does not treat their files as untracked content in the main checkout. However, the absence of a `.gitignore` entry signals intent ambiguously. Third-party tools (editors, search indexers) may descend into the worktree directory unexpectedly. |
| Branch uniqueness constraint | A branch checked out in a worktree cannot be checked out in the main repo simultaneously. If the user tries to switch `main` to a branch already active in a worktree, git rejects the checkout. |
| Merge discipline required | Work done in a worktree must be explicitly merged or cherry-picked back to `main`. The worktree branch is not automatically integrated. For a docs repo, this is the correct behavior — but it means improvements discovered during a background task must survive a PR step to be useful. |
| Auto-generated branch names | The harness generates names like `worktree-12-factor-karpathy-extension`. These are verbose and do not follow the repo's `feat-YYYYMMDD-description` convention. |

---

## Refactoring Opportunities

### 1. Add `.claude/worktrees/` to `.gitignore`

Git does not need this entry to behave correctly, but it documents intent and prevents editors and search tools from indexing worktree content alongside main.

```
# Add to .gitignore
.claude/worktrees/
```

Low effort. No behavior change. Recommended.

### 2. Commit untracked draft files before starting a worktree session

The friction caused by `.12-FACTOR-AGENTS.md` not appearing in the worktree is avoidable. Establish a convention: **stage and commit any in-progress draft files to a scratch branch before delegating to a background agent**. The agent checks out that branch as its worktree base, giving it access to the in-progress content. This is consistent with `STRATEGY.md §1` (never rely on conversational memory; always write it down).

Add to `STRATEGY.md` anti-patterns: "Do not delegate to a background agent while work-in-progress files are untracked. Commit to a scratch branch first."

### 3. Standardize worktree branch naming

Current harness auto-generates `worktree-<task-slug>`. The repo convention is `feat-YYYYMMDD-<slug>` or `chore-YYYYMMDD-<slug>`. Either configure the harness to use the convention, or rename the branch immediately after worktree creation (as done in this session with `git checkout -b feat-20260517-karpathy-wiki`).

### 4. Treat `skills/`, `subagents/`, `templates/` as read-only in worktrees

Background agents working on task-scoped deliverables (analysis docs, session summaries, draft recommendations) should not modify shared reference libraries in the worktree. If an agent discovers a pattern worth adding to `skills/`, it should note it in its output document and leave the `skills/` update for a dedicated PR — not modify the worktree copy, which would require a merge back before the improvement is visible.

Add to `subagents/subagents.md`: "Background agents operating in a worktree must not modify files in `skills/`, `subagents/`, or `templates/` unless the task is explicitly scoped to those files. Improvements to reference libraries belong in a dedicated feature branch, not a background task worktree."

### 5. Karpathy `log.md` and `index.md` must live in a worktree-accessible location

The Karpathy wiki pattern requires `log.md` (append-only execution record) and `index.md` (content catalog) to be readable across sessions. If these files are tracked by git and live in the main checkout, background agents in worktrees can read the current version at worktree-creation time but cannot update the shared log without a merge step.

Two viable approaches:

**Option A — Commit-based (fits current workflow):** `log.md` and `index.md` are tracked files. Each session commits its log entries and index updates to its branch. The merge into `main` is what makes the log durable. Simpler; no new infrastructure; log updates are auditable in git history. Tradeoff: the log is not visible to concurrent sessions until merged.

**Option B — Untracked shared file (outside git):** `log.md` and `index.md` live in an untracked location accessible to all worktrees — e.g., `plans/log.md` (already excluded from git by `plans/*progress.txt` pattern in `.gitignore`... though `log.md` would need explicit exclusion). All worktrees share the same file via the filesystem. Tradeoff: concurrent writes risk corruption; no git history on the log.

**Recommendation:** Option A for this docs-first repo. The log's value is in its git-auditable history. Concurrency conflicts are low-risk when sessions are sequential (one background agent at a time).

---

## Summary Table

| Question | Answer |
|----------|--------|
| Is the worktree a full repo copy? | Yes at filesystem level; no at git object level |
| Disk cost for this repo? | Negligible — docs-first, no build artifacts |
| Biggest actual friction? | Untracked files invisible to worktrees; branch naming inconsistency |
| `.gitignore` gap? | `.claude/worktrees/` should be listed to signal intent |
| Highest-value refactor? | Convention: commit draft files before delegating; treat `skills/` as read-only in worktrees |
| Karpathy wiki + worktrees? | Option A: commit-based log/index updates per branch; merge to main to persist |
