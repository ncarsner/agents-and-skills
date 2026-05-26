---
description: Deep structural review of a file or module
allowed-tools: Read, Glob, Grep
argument-hint: <file-path-or-directory>
---

Perform a deep structural review of: $ARGUMENTS

## Review dimensions (check all of these)

**Error handling:**
- Are all error paths handled explicitly (no empty catch blocks)?
- Do async operations have proper error propagation?
- Are there any swallowed errors that would fail silently?

**Edge cases:**
- What happens with null/undefined/empty inputs?
- What happens at boundary values (0, -1, MAX_INT, empty arrays)?
- Are there implicit type coercions that could cause subtle bugs?

**Concurrency:**
- Could any state mutation cause race conditions if called concurrently?
- Are shared resources properly synchronized?
- What happens if this function is called twice before the first call completes?

**Dependencies:**
- Are imports used? Flag any unused imports.
- Are there circular dependency risks?
- Is the module tightly coupled to implementation details it shouldn't know about?

**Naming and structure:**
- Do function names accurately describe what they do (including side effects)?
- Are there functions doing more than one thing that should be split?

## Output format
For each finding, give:
- Severity: 🔴 Critical (will cause bugs) / 🟡 Warning (could cause issues) / 🔵 Note (improvement)
- The specific code location
- What could go wrong
- A suggested fix (code, not just description)
