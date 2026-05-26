---
description: Refactor internals without changing public API
allowed-tools: Read, Grep, Glob
argument-hint: <file-or-function>
---

Refactor the internals of: $ARGUMENTS

## Hard constraints
- DO NOT change any exported function signatures
- DO NOT change any return types or shapes
- DO NOT rename any exported symbols
- DO NOT change the module's public interface in any way
- DO NOT add new dependencies
- Preserve all existing behavior, including edge cases and error messages

## What to improve (internal only)
- Extract repeated logic into private helper functions
- Simplify nested conditionals (early returns, guard clauses)
- Remove dead code paths that can never execute
- Replace magic numbers/strings with named constants
- Improve variable names within function bodies
- Reduce function length by extracting logical steps

## Verification
After refactoring, confirm:
1. Every exported function/type/constant still has the same name and signature
2. All existing tests would still pass without modification (don't run them, just verify compatibility)
3. No new imports were added

Present the refactored code with a brief summary of what changed and why.
