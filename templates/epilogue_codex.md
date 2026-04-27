# Epilogue Codex - Session Shutdown Protocol

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
yyyy-mm-dd-<content>.md
```

Rules:
- Use ISO 8601 dates, such as `2026-04-27`.
- Use a short kebab-case descriptor, such as `session-summary`,
  `api-cleanup`, or `test-hardening`.
- Default to `yyyy-mm-dd-session-summary.md` unless a more specific descriptor
  makes the file easier to find later.

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

## 2. Refresh Agent Context

Update every root-level context file that exists:

| Agent | Context file |
|-------|--------------|
| Codex | `agents.md` |
| Claude | `claude.md` |
| Gemini | `gemini.md` |

Each context file should reflect the repository as it stands after this session:
- Current phase and status.
- Important files added or changed.
- Decisions made today, dated.
- Known blockers or risks.
- Next steps, replacing stale items.

If more than one context file exists, keep the shared project-state content in
sync. Verify parity with the files that are present:

```bash
diff claude.md gemini.md
diff claude.md agents.md
diff gemini.md agents.md
```

No output means the compared files match. If a file is absent, skip only that
specific comparison and report that it was not present.

---

## 3. Confirm Git and Remote

Make sure the project is a git repository and has a reachable `origin` remote.

```bash
if [ ! -d .git ]; then
  git init
  echo "Initialized local git repository."
fi

git status --short

if ! git remote get-url origin >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is not authenticated. Run: gh auth login"
    exit 1
  fi

  REPO_NAME=$(basename "$PWD")
  gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
  echo "Created private GitHub repository and configured origin: $REPO_NAME"
else
  git remote get-url origin
fi
```

Use `gh repo create` only when `origin` is missing. If `origin` already exists,
do not replace it during epilogue work.

---

## 4. Review, Stage, Commit, and Push

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

## 5. Verify Clean State

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

## 6. Closure Checklist

Report each item as done, skipped with reason, or blocked:

- [ ] Dated summary file created with completed work, decisions, current state,
      blockers, and next steps.
- [ ] Root context files updated where present.
- [ ] Context files compared and synchronized where more than one exists.
- [ ] Git repository exists locally.
- [ ] `origin` remote exists and is reachable, or the blocker is documented.
- [ ] Secrets and local-only files were checked before staging.
- [ ] Intended changes were committed with a dated message, or there was nothing
      to commit.
- [ ] Current branch was pushed, or the push blocker is documented.
- [ ] `git status` was checked after the push.
- [ ] Final next steps are visible in the summary and final report.

---

## 7. Final Report

End with a compact report the user can scan quickly:

```text
Session closed: yyyy-mm-dd
Summary: <path-to-summary>
Context files: <updated files, or "none present">
Commit: <short-sha> - <commit message, or "no commit needed">
Branch: <branch-name>
Remote: <origin-url, or blocker>
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

| Purpose | Filename |
|---------|----------|
| Session summary | `2026-04-27-session-summary.md` |
| Architecture note | `2026-04-27-api-boundary-design.md` |
| Bug investigation | `2026-04-27-login-timeout-debugging.md` |
| Test work | `2026-04-27-coverage-hardening.md` |
| Migration planning | `2026-04-27-schema-migration-plan.md` |

Use lowercase kebab-case after the date. Avoid spaces, underscores, and vague
names like `notes.md`.
