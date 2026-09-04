# Skill: GitHub Issue Creation

Create GitHub issues for a repository only when the user specifically asks for
issue creation. This skill covers authorization checks, repository targeting,
issue drafting, safe command execution, and reporting created issue URLs.

---

## Core Rule

Do not create, edit, close, label, assign, or otherwise mutate GitHub issues
unless the user's latest instruction explicitly asks for that action.

Allowed explicit requests include:

- "Create GitHub issues for these bugs in owner/repo."
- "Open an issue in this repo for the failing login test."
- "Use gh to create the issues we just drafted."

Not explicit enough:

- "What issues should we track?"
- "Make a plan for follow-up work."
- "This should probably be an issue."
- "Draft GitHub issues for this."

For non-explicit requests, return drafts or a proposed issue list only. Ask for
creation approval before making any GitHub write.

---

## Required Inputs

| Field | Description |
|-------|-------------|
| `repo` | Target repository in `OWNER/REPO` or `[HOST/]OWNER/REPO` format. |
| `title` | Short, specific issue title. |
| `body` | Markdown body with context, expected behavior, tasks, or acceptance criteria. |
| `labels` | Optional existing label names requested by the user or already standard in the repo. |
| `assignees` | Optional GitHub logins requested by the user. |
| `milestone` | Optional milestone requested by the user. |
| `project` | Optional project title requested by the user. |

If `repo` is missing, infer it only from the current Git remote after verifying
the result. If it cannot be determined confidently, ask the user for the repo.

---

## Workflow

1. Verify explicit user intent.
   - Proceed only when the latest user instruction specifically requests
     creating GitHub issue(s).
   - If the user asks to draft, plan, identify, or recommend issues, produce
     Markdown drafts and stop.

2. Resolve and verify the repository.
   - Prefer the user-provided `OWNER/REPO` or `[HOST/]OWNER/REPO`.
   - If absent, use `gh repo view --json nameWithOwner --jq '.nameWithOwner'`
     from the target repository, then state the inferred repo before creating.
   - Do not create issues when the repo target is ambiguous.

3. Check GitHub CLI readiness.
   - Run `command -v gh` to verify the GitHub CLI is installed.
   - Run `gh auth status` to verify authentication.
   - Do not print or request tokens. Do not run `gh auth status --show-token`.

4. Prepare issue content.
   - Use concrete user-provided title/body when available.
   - When deriving issues from a bug report, review notes, or failing tests,
     draft concise titles and bodies first.
   - Include enough context for another developer to act without reading the
     chat transcript.

5. Create issues with `gh issue create`.
   - Use `--repo` to avoid writing to the wrong repository.
   - Use `--body-file` for multi-line Markdown bodies.
   - Add labels, assignees, milestone, project, or template only when requested
     or clearly established by the repo conventions.

6. Report results.
   - Return each created issue URL.
   - Include any issue that was skipped and the reason.
   - If a command fails, stop and show the failure context without retrying a
     potentially duplicate creation unless the issue URL confirms success.

---

## Command Patterns

Check prerequisites:

```bash
command -v gh
gh auth status
gh repo view --repo OWNER/REPO --json nameWithOwner,url
```

Create one issue:

```bash
gh issue create \
  --repo OWNER/REPO \
  --title "Short imperative title" \
  --body-file /path/to/body.md
```

Create with optional metadata:

```bash
gh issue create \
  --repo OWNER/REPO \
  --title "Short imperative title" \
  --body-file /path/to/body.md \
  --label "bug" \
  --assignee "@me" \
  --milestone "v1.2"
```

When adding an issue to a GitHub Project, verify the authenticated account has
the required project scope before creation:

```bash
gh auth status
gh issue create \
  --repo OWNER/REPO \
  --title "Short imperative title" \
  --body-file /path/to/body.md \
  --project "Roadmap"
```

---

## Issue Body Template

Use this structure unless the repository has a more specific issue template:

```markdown
## Context

<Why this issue exists and what prompted it.>

## Expected Outcome

<The observable behavior or deliverable that should exist when complete.>

## Tasks

- [ ] <Actionable task>
- [ ] <Actionable task>

## Acceptance Criteria

- <Verifiable condition>
- <Verifiable condition>
```

For bugs, prefer:

```markdown
## Summary

<What is broken.>

## Steps to Reproduce

1. <Step>
2. <Step>
3. <Step>

## Expected Behavior

<What should happen.>

## Actual Behavior

<What happens instead.>

## Evidence

<Logs, failing test names, screenshots, or links.>
```

---

## Issue Triage and Closure

Before implementing or closing an existing issue, verify its factual claims
against current repo state, an issue's body is a snapshot from when it was
filed and can go stale after unrelated cleanup work (file renames, deletions,
convention changes). Do not take a cited file path, "established convention,"
or cross-reference at face value.

Verification pattern:

```bash
# Does a file/path the issue cites still exist?
ls <path-cited-in-issue> 2>&1

# Does a "convention" the issue asserts actually hold in history?
git log --oneline --merges -10
git branch -a --sort=-committerdate

# Does the issue collide with an unmerged PR touching the same lines?
gh pr list --state open --json number,title,files
```

If the premise no longer holds (cited file deleted, convention never
actually enforced, goal already achieved via a different mechanism), close
with `gh issue close <n> --comment "..."` explaining specifically what
changed and why the issue's version should not be resurrected as written, 
not just "stale," but what a future reader would otherwise re-litigate.

```bash
gh issue close <number> --comment "$(cat <<'EOF'
Closing as <outmoded|stale>. <One sentence: what the issue claims.> <One
sentence: what is actually true now, with the file/PR/commit that changed
it.> <If applicable: what a fresh issue would need to state instead.>
EOF
)"
```

This is a mutation (§Core Rule applies): only close an issue when the user
asked for it, or the user explicitly delegated triage of open issues.

---

## Closing Keywords and Stacked Pull Requests

Two failure modes, both observed closing real issues in this repository.

### A closing keyword fires even when negated

GitHub's parser scans a PR body for `close`, `fixes`, `resolves` and friends
adjacent to an issue number. It has no notion of negation, so writing a
sentence explaining that a PR does *not* close an issue is what closes it:

```
Does not close #91: the CI backstop remains open.   <- closes #91 on merge
Leaves #91 open: the CI backstop remains.           <- safe
```

Never put a closing keyword next to an issue number unless you intend the
close. Phrase the negative as "leaves #N open" or "#N remains open". A `Refs
#N` header does not protect you; the prose is scanned too.

Use `Closes` only for issues the PR actually resolves. A PR that finishes half
an issue carries `Refs`, and the remaining tasks are recorded on the issue
before merge, otherwise the merge buries them.

### Merging a stack deletes the wrong things

When PR B is based on PR A's branch, merging A with `--delete-branch` removes
B's base branch, and GitHub **closes** B. A closed PR cannot be retargeted and
cannot be reopened while its base is missing, so the recovery is awkward:

```bash
git push origin <sha>:refs/heads/<deleted-base>   # restore the base
gh pr reopen <B> --repo OWNER/REPO
gh pr edit <B> --repo OWNER/REPO --base main
```

Merge a stack bottom-up, retargeting before each merge, and delete branches
only for the leaf:

```bash
gh pr merge <A> --repo OWNER/REPO --merge                 # base of another PR
gh pr edit  <B> --repo OWNER/REPO --base main             # retarget first
gh pr merge <B> --repo OWNER/REPO --merge --delete-branch # leaf
```

Verify what actually closed rather than assuming the keywords behaved:

```bash
gh issue view <N> --repo OWNER/REPO --json state,closedByPullRequestsReferences
```

---

## Safety Constraints

- Treat GitHub issue creation as an external write operation.
- Never create issues from speculative recommendations without explicit user
  approval to create them.
- Never use issue creation as a substitute for completing requested code work.
- Never create duplicate issues intentionally. For obvious duplicate risk, run
  `gh issue list --repo OWNER/REPO --search "<key terms>"` before creating.
- Never include secrets, private credentials, or unredacted sensitive data in an
  issue title or body.
- Prefer stopping on the first failure during bulk creation to avoid partial,
  confusing issue sets.
