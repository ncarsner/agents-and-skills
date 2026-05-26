---
description: Validate and generate PR description from current branch
allowed-tools: Bash(git *), Bash(gh *), Bash(pytest *), Bash(npm test *), Read, Glob
---

Prepare a pull request for the current branch.

## Step 1: Pre-flight validation
Run the test suite before generating anything. If tests fail, stop and report the failures.
!`git diff --stat main..HEAD`

## Step 2: Assess the diff
!`git log main..HEAD --oneline`
!`git diff --stat main..HEAD`

Check:
- If the diff exceeds 500 lines changed, flag it as a large PR and suggest splitting
- If the branch has more than 15 commits, suggest squashing before opening

## Step 3: Generate PR description
Read the actual code changes (not just filenames) to understand what was built:
!`git diff main..HEAD`

Write a PR description with these sections:

**Summary** (2-3 sentences): What this PR does and why, written for someone who hasn't seen the code.

**Changes** (bullet list): Group related changes together. Reference specific files only when it adds clarity. Skip trivial changes like formatting and import reordering.

**How to test**: Step-by-step instructions a reviewer can follow to verify the changes work. Include specific commands to run, endpoints to hit, or behaviors to observe.

**Risk assessment**: What could go wrong with this change? Does it touch shared infrastructure, modify database schemas, change public APIs, or affect performance-sensitive paths? Be specific. "Low risk" is not useful. "Modifies the prediction endpoint response shape, which could break clients that destructure the old format" is useful.

**Related issues**: Scan commit messages for issue references (#123, JIRA-456) and list them.

## Step 4: Output
Print the PR description in markdown, ready to paste into GitHub.
Do NOT create the PR automatically. Output the description for review first.
