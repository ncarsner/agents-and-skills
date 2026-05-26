---
description: Rebuild working context after /clear
allowed-tools: Bash(git *), Read, Glob
---

Load my current working state into this conversation. Read the following:

1. All uncommitted changes (staged and unstaged):
!`git diff HEAD`

2. The 5 most recent commits with full diffs:
!`git log --oneline -5`

3. Any TODO/FIXME markers in modified files:
!`git diff --name-only HEAD | head -20`

Read each modified file listed above. Identify any TODO, FIXME, or HACK comments in those files.

4. Current branch and its relationship to main:
!`git branch --show-current`
!`git log main..HEAD --oneline 2>/dev/null || echo "No commits ahead of main"`

After loading all of this, give me a brief summary:
- What I appear to be working on (inferred from changes)
- Key files modified
- Any TODOs or incomplete work flagged in the code
- How far ahead of main this branch is
