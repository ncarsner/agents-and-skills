---
description: Scan for technical debt patterns and prioritize remediation
allowed-tools: Bash(git *), Bash(npm *), Bash(npx *), Bash(wc *), Bash(find *), Read, Glob, Grep
---

Scan this project for technical debt and produce a prioritized remediation report.

## Scan dimensions

**Code complexity:**
- Find the 5 largest files by line count (often a sign of god objects/modules)
- Identify functions longer than 50 lines
- Flag files with more than 10 imports (high coupling)

**Dependency health:**
!`npm outdated 2>/dev/null || pip list --outdated 2>/dev/null | head -20`
- How many dependencies are more than 2 major versions behind?
- Are there any dependencies with known deprecation notices?

**Test coverage gaps:**
- Find source files that have no corresponding test file
- List them with file size (larger untested files = higher risk)

**Code smells:**
- grep for: any-type assertions (as any, type: any), eslint-disable without explanation, @ts-ignore without comment
- Find duplicated code blocks (same 10+ lines appearing in multiple files)
- Check for TODO/FIXME/HACK comments older than 30 days:
  use `git log` to find when each TODO was introduced

**Architectural smells:**
- Circular dependencies (if a tool like madge is available)
- Business logic in API route handlers (should be in service layer)
- Direct database queries outside of a repository/data-access layer

## Output format
Group findings by priority:
🔴 High: Likely to cause incidents or block feature work
🟡 Medium: Increasing maintenance cost over time
🔵 Low: Code quality improvements

For each finding, include:
- The specific file(s) and what's wrong
- Estimated effort to fix (small/medium/large)
- A one-line description suitable for a ticket title
