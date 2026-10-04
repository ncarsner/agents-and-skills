---
name: prd-to-issues
description: Convert a Product Requirements Document into structured GitHub issues with a preview-before-create confirmation step. Use when the user provides a PRD or feature spec and wants it broken into trackable issues.
disable-model-invocation: true
argument-hint: [prd-file-path]
allowed-tools: Read Bash
---

Convert the PRD at $ARGUMENTS (or content pasted after the command) into structured GitHub issues.

Steps:
1. Parse the PRD into discrete, independently deliverable features or tasks.
2. For each item, generate:
   - Title: imperative sentence, ≤60 characters
   - Body: one-paragraph context + acceptance criteria as a checkbox list, following `/pr`'s [Version control prose](../pr/SKILL.md#version-control-prose) rules: an engineering record of the work, American spelling, one line per paragraph and list item, no stray blank lines
   - Labels: infer from [feature, enhancement, bug, chore, documentation]
3. Group related sub-tasks under a parent issue with a task list rather than creating many tiny issues.
4. Write each body to its own file and lint it:
   ```bash
   .claude/skills/pr/lint-prose.sh body /tmp/issue-<n>.md   # silent and exit 0 when clean
   ```
   Revise until every body lints clean. A hit may stay only when it is an identifier, a quotation, or a quoted example of a defect; list each retained hit in the preview.
5. Preview all issues to the user. Ask for explicit confirmation before creating any.
6. On confirmation, create each issue from its linted file. Infer the repo from `gh repo view` unless the user specifies one:
   ```bash
   gh issue create --repo "$REPO" --title "<title>" --label "<label>" --body-file /tmp/issue-<n>.md
   ```
   A body edited after the preview is linted again before creation.
7. Return all created issue URLs and remove the `/tmp/issue-*.md` files.

Constraints:
- Never create issues without explicit user confirmation of the full preview.
- Never embed tokens or credentials in any command.
- Stop on the first creation failure unless the user explicitly permits best-effort bulk creation.
