---
name: pr
description: Commit the current session's work, push the branch, and open a pull request. Enforces RULES.md 6 (Conventional Commits, feature branch, issue reference) and RULES.md 18 (no agent attribution). Invoke explicitly with /pr.
disable-model-invocation: true
allowed-tools: Bash Read
---

Commit through PR only. Session capture, CHANGELOG, and context-file updates
belong to `/epilogue`, which runs first when both run and may have committed
already. Each step has a stop condition; do not guess past a failed check.

## Step 0: Preconditions

```bash
gh auth status >/dev/null 2>&1 || { echo "run gh auth login"; exit 1; }
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
BRANCH=$(git branch --show-current)
DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
```

**Stop if `BRANCH` equals `DEFAULT`** (RULES.md §6 prohibits committing to
`main`). Run `git checkout -b <type>/<short-description>` and move the work
there.

Pass `--repo "$REPO"` to every `gh` call
([github-issue-creation.md](../../../skills/github-issue-creation.md) §5).

## Step 1: Find what needs committing

```bash
git status --short
git log --oneline "$DEFAULT"..HEAD
```

| State | Action |
|-------|--------|
| Uncommitted changes | Commit them (Steps 2 and 3) |
| Clean, commits ahead | Scan existing commits in Step 2, then Step 4 |
| Clean, no commits ahead | Stop. Nothing to open a PR for. |

## Step 2: Attribution scan

RULES.md §18 prohibits agent attribution in commits, PR bodies, file content,
comments, and any version control artifact. Scan whichever target Step 1
selected:

```bash
git diff --cached > /tmp/pr-scan.txt              # uncommitted
git diff "$DEFAULT"...HEAD > /tmp/pr-scan.txt     # already committed
git log "$DEFAULT"..HEAD --format=full >> /tmp/pr-scan.txt
```

**Hard fail.** Remove any hit before proceeding:

```bash
grep -inE "co-authored-by|generated with|ai-generated|written by (claude|chatgpt|copilot)|🤖" /tmp/pr-scan.txt
```

The emoji is a detection pattern for a known footer format, the one deliberate
exception to `AGENTS.md`'s no-emoji rule.

**Review, do not auto-remove.** Bare vendor names hit constantly in this tree,
where `CLAUDE.md` is a tracked filename, `.claude/` a tracked directory, and
several skills quote attribution patterns in order to detect them:

```bash
grep -inE "claude|anthropic|copilot|chatgpt" /tmp/pr-scan.txt | head -20
```

Filenames, paths, documented rules, and detection patterns are legitimate.
Signatures, bylines, trailers, and "assisted by" notes are not. **Never delete
a `CLAUDE.md` or `AGENTS.md` reference to satisfy this grep.** Then `rm -f /tmp/pr-scan.txt`.

## Step 3: Commit

Conventional Commits (RULES.md §6): `feat`, `fix`, `docs`, `style`, `refactor`,
`test`, `chore`, `perf`, `ci`, `build`, `revert`. Session closes are the
documented exception: match this repo's `yyyy-mm-dd: close session - <outcome>`
history rather than forcing a prefix onto it.

```bash
git add -A
git status --short          # confirm nothing unintended is staged
git commit -m "$(cat <<'EOF'
<type>(<scope>): <short imperative description>

<body: why, not what>

Refs #<N>
EOF
)"
```

- **One closing keyword per line.** GitHub has been observed to auto-close only
  the first issue in a comma-separated list.
- **`Closes` only for issues this work resolves.** RULES.md §6 requires a PR to
  reference an issue, which `Refs` satisfies. A session that files four issues
  and fixes none carries four `Refs` and zero `Closes`; otherwise the merge
  silently closes open work.
- Add no attribution trailer, including one the tool offers by default.

## Step 4: Push and open the PR

```bash
git push -u origin "$BRANCH"
gh pr create --repo "$REPO" --title "<type>(<scope>): <description>" --body "$(cat <<'EOF'
Refs #<N>

- `<file>` - <one-line summary>

### Context
<why this change exists, if not obvious from the file list>

### Verified
- <what was actually run, with results>
EOF
)"
```

Hyphens, not em dashes: a PR body is agent-generated text that outlives the
session (`AGENTS.md` Writing Style). Append no "Generated with" footer. If a PR
already exists for the branch, use `gh pr edit <number> --repo "$REPO" --body`.

## Step 5: Verify

```bash
git log "$DEFAULT"..HEAD --format=full | grep -inE "co-authored-by|generated with|ai-generated" || echo "commits clean"
gh pr view <number> --repo "$REPO" --json body -q .body | grep -inE "generated with|co-authored" || echo "body clean"
gh pr view <number> --repo "$REPO" --json author -q .author.login
git status --short
```

Expect no hard-fail hits, a human `author.login` rather than a bot, and a clean
working tree.

## Step 6: Post-merge issue check

Run only after merge, and only if the PR carried closing keywords. Auto-close is
unreliable across multiple issues.

```bash
for n in <N> <N>; do gh issue view "$n" --repo "$REPO" --json number,state -q '"#\(.number) \(.state)"'; done
gh issue close <N> --repo "$REPO" --comment "Closed via #<PR-number> (merged)."
```

Closing an issue is a mutation
([github-issue-creation.md](../../../skills/github-issue-creation.md)): do it
only when the merged work actually resolved that issue. If a referenced issue is
still open because the work did not finish it, leave it open and say so.
