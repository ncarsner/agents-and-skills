---
description: Pre-commit scan for debug artifacts and code smells
allowed-tools: Bash(git *), Bash(grep *), Read, Glob
---

Scan all staged changes for the following issues:

## What to scan
!`git diff --cached`

## Rules
Check for ALL of the following in the staged diff:
1. console.log, console.debug, console.warn statements (unless in a logger utility)
2. TODO, FIXME, HACK, XXX comments
3. Commented-out code blocks (3+ consecutive commented lines)
4. Hardcoded secrets: API keys, tokens, passwords, connection strings
5. .only or .skip in test files (jest, mocha, vitest)
6. Debug flags: debugger statements, #debug, verbose: true in config
7. Large binary files or data dumps added to the commit
8. Import statements for dev-only packages in production code paths

## Output format
If ALL checks pass: respond with "✅ Preflight clear. Staged changes look clean."

If ANY issues found: list every issue with its file path and line context.
Do NOT fix anything. Do NOT unstage anything. Report only.
