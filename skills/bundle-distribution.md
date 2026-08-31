# Skill: Bundle Distribution

Patterns for copying a curated file bundle from a master repository into
downstream projects with rsync and a shell wrapper, and the platform pitfalls
that make a naive implementation silently wrong.

---

## Quick Reference

```bash
rsync -av --include-from="$LIST" "$SRC" "$DEST/"   # additive, never deletes
rsync --version | head -1                          # check for openrsync on macOS
```

| Symptom | Cause |
|---------|-------|
| Deleted-upstream files persist downstream | rsync is additive by default |
| `--delete` misses stale top-level files | a trailing `- *` protects them |
| `--delete-excluded` does nothing | macOS ships openrsync, not GNU rsync |
| `.claude/.claude` appears after a re-run | `mv` into an existing directory nests |
| Function edits have no effect in an open shell | a same-named alias shadows it |

---

## Pattern: Include-List with a Trailing Exclude-All

An include list that ends in `- *` ships only what is listed:

```
- /.claude/worktrees/***
+ AGENTS.md
+ /skills/***
+ /sessions/
+ /sessions/README.md
- *
```

Two rules govern correctness:

1. **Exclusions must precede the include that would otherwise match.** rsync is
   first-match-wins, so `- /.claude/worktrees/***` has to appear above
   `+ /.claude/***`.
2. **A file deeper than the root needs its parent directory included.**
   `+ /sessions/README.md` alone never matches, because `- *` excludes the
   `sessions` directory and rsync never descends into it. Add `+ /sessions/`
   first.

Verify with a dry run rather than reasoning about precedence:

```bash
rsync -avn --include-from="$LIST" "$SRC" /tmp/dryrun/
```

---

## Pattern: Clean Slate Instead of rsync Delete Flags

Neither delete flag can be trusted to prune a bundle built this way.

`--delete` respects receiver-side protections, so it removes stale files
*inside* included directories but leaves stale files at the top level, which
the trailing `- *` protects:

```
templates/epilogue.md: deleting     <- removed
AGENTS.md                           <- survives
GEMINI.md                           <- survives
```

`--delete-excluded` would cover those, but macOS ships `openrsync` (reports as
"rsync version 2.6.9 compatible") where the flag is accepted and silently does
nothing. A dry run prints no deletion lines at all.

When the destination is a pure copy target that is never hand-edited, wipe it:

```bash
rm -rf "$DEST"
mkdir -p "$DEST"
rsync -av --include-from="$LIST" "$SRC" "$DEST/"
```

**Validate any argument that reaches `rm -rf`.** Once a folder-name parameter
is deleted rather than merely created, a typo becomes destructive:

```bash
case "$FOLDER_NAME" in
    ""|.|..|*/*|.*) echo "invalid folder name: $FOLDER_NAME"; return 1 ;;
esac
```

---

## Pattern: Merging a Subtree Without Nesting

`mv src/dir .` does not fail when `./dir` already exists. It *succeeds* by
moving the source inside the target, producing `./dir/dir`. A `|| true` guard
catches nothing because the exit status is zero.

Use rsync for the merge, and wipe only the subdirectories that are pure copies
so upstream deletions propagate while local files survive:

```bash
rm -rf ./.claude/commands ./.claude/skills   # bundle-owned, mirror exactly
rsync -a "$DEST/.claude/" "./.claude/"       # local-only settings survive
rm -rf "$DEST/.claude"
```

Decide deliberately which paths are bundle-owned and which accumulate local
state. State files that gain rows or entries over time must be seeded only when
absent:

```bash
[ -f index.md ] || printf '# index.md\n' > index.md
```

Ship a spec without shipping the directory its output belongs in. The bundle
carries `sessions/README.md` (the page format), but the pages it describes are
git-tracked project state and belong at the destination project's root, not
under the gitignored bundle directory. Ship the README, leave the root
`sessions/` for the agent to create on first write, and never seed a second
copy of the README at the root. See RULES.md §12.

---

## Pattern: Appending to a Downstream .gitignore Idempotently

A wrapper that runs more than once must not duplicate lines, and must not
append onto a file whose last line has no newline:

```bash
touch .gitignore
if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ]; then
    echo "" >> .gitignore
fi
for entry in "AGENTS/" ".claude/" "ralph.sh"; do
    grep -qxF "$entry" .gitignore 2>/dev/null || echo "$entry" >> .gitignore
done
```

`grep -qxF` matches the whole line literally, which is what a `.gitignore`
entry comparison needs.

---

## Pattern: Refusing to Run in the Source Repository

A distribution wrapper invoked inside its own master repo will happily
gitignore that repo's tracked files. Guard on the resolved path, and normalize
case so the check holds on case-insensitive filesystems:

```bash
if [ "${PWD:A:l}" = "${SRC:A:l}" ]; then
    echo "refusing to run in the source repo"
    return 1
fi
```

`:A` resolves to an absolute path, `:l` lowercases. Both are zsh modifiers.

---

## Pattern: An Alias Shadows a Same-Named Function

Converting a shell alias into a function is invisible to already-running
shells. Aliases are resolved before functions, so the stale alias keeps
winning even after the file is re-sourced:

```bash
source ~/.<shellrc>   # defines the new function
<name>                # still runs the OLD alias
unalias <name>        # now the function is reachable
```

This matters most when the old and new definitions are partially compatible.
An old alias running against a new data file can execute the destructive half
of the new behavior and then fail, which looks like a copy failure rather than
a stale-definition problem.

When shipping such a change, tell the user explicitly to open a new terminal or
run `unalias <name> && source` the shell rc file. When testing one, clear the alias
inside the test shell or the results are meaningless.
