---
name: pr
description: Commit the current session's work, push the branch, and open a pull request. Enforces RULES.md 6 (Conventional Commits, feature branch, issue reference) and RULES.md 18 (no agent attribution). Invoke explicitly with /pr.
disable-model-invocation: true
allowed-tools: Bash Read
---

Ship the current session's work as a pull request. Work through the steps in
order. Each step has a stop condition; do not proceed past a failed check by
guessing.

This skill covers commit through PR only. Session capture, CHANGELOG entries,
skill registration, and context-file updates belong to `/epilogue`
([.claude/commands/epilogue.md](../../commands/epilogue.md)). If both run in one
session, `/epilogue` runs first and may already have committed. Step 1 handles
that case.

## Step 0: Preconditions

```bash
gh auth status >/dev/null 2>&1 || { echo "gh not authenticated: run gh auth login"; exit 1; }
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
BRANCH=$(git branch --show-current)
DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
echo "repo=$REPO branch=$BRANCH default=$DEFAULT"
```

**Stop if `BRANCH` equals `DEFAULT`.** RULES.md §6 prohibits committing directly
to `main`. Create a feature branch first and move the work onto it:

```bash
git checkout -b <type>/<short-description>
```

Pass `--repo "$REPO"` to every `gh` command below. Per
[skills/github-issue-creation.md](../../../skills/github-issue-creation.md) §5,
this prevents writing to the wrong repository when multiple remotes or nested
checkouts are in play.

## Step 1: Determine what still needs committing

Do not assume the work is uncommitted. `/epilogue` may have committed already,
in which case `git diff --cached` is empty and scanning it proves nothing.

```bash
git status --short
git log --oneline "$DEFAULT"..HEAD
```

Three cases:

| State | Action |
|-------|--------|
| Uncommitted changes present | Stage and commit them (Steps 2 and 3) |
| Nothing uncommitted, commits ahead of default | Skip to Step 4; scan the existing commits in Step 2 |
| Nothing uncommitted, no commits ahead | Stop. There is nothing to open a PR for. |

## Step 2: Attribution scan

RULES.md §18 prohibits all agent attribution in commits, PR bodies, file
content, comments, and any version control artifact. RULES.md §6 adds that the
git author identity must be the human who owns the work.

Scan the right target for the state found in Step 1:

```bash
# Uncommitted work:
git diff --cached > /tmp/pr-scan.txt
# Already-committed work:
git diff "$DEFAULT"...HEAD > /tmp/pr-scan.txt
git log "$DEFAULT"..HEAD --format=full >> /tmp/pr-scan.txt
```

**Hard fail.** These are attribution markers with no legitimate use. Any hit
must be removed before proceeding:

```bash
grep -inE "co-authored-by|generated with|ai-generated|written by (claude|chatgpt|copilot)|🤖" /tmp/pr-scan.txt
```

The emoji above is a detection pattern for a known footer format, not
decoration. It is the one deliberate exception to the no-emoji rule in
`CLAUDE.md`.

**Review, do not auto-remove.** A bare search for vendor names produces
constant false positives in this repository, where `CLAUDE.md` is a tracked
filename, `.claude/` is a tracked directory, and several skills quote
attribution patterns in order to detect them:

```bash
grep -inE "claude|anthropic|copilot|chatgpt" /tmp/pr-scan.txt | head -20
```

Read each hit and judge it. A filename, a path, a documented rule, or a
detection pattern is legitimate. A signature, byline, trailer, or "assisted by"
note is not. **Never delete a `CLAUDE.md` reference to satisfy this grep.**

Clean up when done: `rm -f /tmp/pr-scan.txt`

## Step 3: Commit

RULES.md §6 requires Conventional Commits. Allowed types: `feat`, `fix`,
`docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`, `revert`.

```bash
git add -A
git status --short          # confirm nothing unintended is staged
git commit -m "$(cat <<'EOF'
<type>(<scope>): <short imperative description>

<optional body explaining why, not what>

Closes #<N>
Closes #<N>
EOF
)"
```

**Session-close commits are the documented exception.** This repository's
history uses `yyyy-mm-dd: close session - <outcome>` for `/epilogue` commits.
Match the surrounding history rather than forcing a Conventional Commit prefix
onto a session close.

**One closing keyword per line.** GitHub's parser has been observed to auto-close
only the first issue in a comma-separated list on merge.

**Never write `Closes #N` for an issue this work does not resolve.** RULES.md §6
requires a PR to reference an issue, which a mention satisfies. Use `Refs #N`
for issues that are related, discovered, or filed by this work but not fixed by
it. A session that opens four issues and closes none should carry four `Refs`
lines and zero `Closes` lines; otherwise the merge silently closes open work.

Add no attribution trailer of any kind, including when the tool offers one by
default (RULES.md §18).

## Step 4: Push and open the PR

```bash
git push -u origin "$BRANCH"
gh pr create --repo "$REPO" --title "<type>(<scope>): <description>" --body "$(cat <<'EOF'
Closes #<N>
Refs #<N>

- `<file>` - <one-line summary>
- `<file>` - <one-line summary>

### Context

<why this change exists, if not obvious from the file list>

### Verified

- <what was actually run or tested, with results>
EOF
)"
```

Use hyphens, not em dashes, in the body. `CLAUDE.md`'s Writing Style section
prohibits em dashes in agent-generated text, and a PR body is agent-generated
text that outlives the session.

Append no "Generated with" footer.

If `gh pr create` reports a PR already exists for the branch, update it instead:

```bash
gh pr edit <number> --repo "$REPO" --body "$(cat <<'EOF'
<updated body>
EOF
)"
```

## Step 5: Verify

```bash
git log "$DEFAULT"..HEAD --format=full | grep -inE "co-authored-by|generated with|ai-generated" || echo "commits clean"
gh pr view <number> --repo "$REPO" --json title,author,body -q '.author.login'
gh pr view <number> --repo "$REPO" --json body -q .body | grep -inE "generated with|co-authored" || echo "body clean"
git status --short
```

Expect: no hard-fail matches, `author.login` is the human user rather than a
bot, and a clean working tree.

## Step 6: Post-merge issue check

Run only after the PR merges, and only if it carried closing keywords. Auto-close
is unreliable across multiple issues.

```bash
for n in <N> <N> <N>; do
  gh issue view "$n" --repo "$REPO" --json number,state -q '"#\(.number) \(.state)"'
done
```

Close any that did not auto-close:

```bash
gh issue close <N> --repo "$REPO" --comment "Closed via #<PR-number> (merged)."
```

Per [skills/github-issue-creation.md](../../../skills/github-issue-creation.md),
closing an issue is a mutation: do it only when the merged work actually
resolved that issue. If a referenced issue is still open because the work did
not finish it, leave it open and say so.

## Conformance notes

This skill was adapted from a downstream copy. Four provisions come from this
repository's rules rather than the original:

| Provision | Source |
|-----------|--------|
| Conventional Commits, with the session-close exception | RULES.md §6 |
| Refuse to commit on the default branch | RULES.md §6 |
| Reference an issue, distinguishing `Closes` from `Refs` | RULES.md §6 |
| Two-tier attribution scan instead of a single grep | RULES.md §18 plus the false-positive rate in this tree |
