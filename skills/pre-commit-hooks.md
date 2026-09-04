# Skill: Pre-commit Hooks

Writing and installing `pre-commit` hooks, including the `commit-msg` stage,
and the traps that make a hook silently not run or match the wrong thing.

---

## Quick Reference

```bash
uv add --dev pre-commit
pre-commit install --hook-type pre-commit --hook-type commit-msg
pre-commit validate-config .pre-commit-config.yaml
pre-commit run --hook-stage commit-msg --commit-msg-filename <file> <hook-id>
```

| Symptom | Cause |
|---------|-------|
| Message-checking hook never fires | `pre-commit install` alone skips the `commit-msg` stage |
| `Cowardly refusing to install hooks` | `core.hooksPath` is set, even to the default path |
| Pattern matches text on another line | `--multiline` enables `re.DOTALL`, so `.` crosses newlines |
| Hook blocks a commit that only documents the rule | Pattern is unanchored, matching prose as well as trailers |

---

## Pattern: A commit-msg Hook with No External Dependency

`language: pygrep` keeps the whole check inside the YAML, so nothing has to be
installed and no script file has to ship with the config. A pygrep hook
**fails when the pattern matches**, which is what a prohibition wants.

```yaml
repos:
  - repo: local
    hooks:
      - id: no-agent-attribution
        name: reject agent attribution trailers
        language: pygrep
        stages: [commit-msg]
        args: [--multiline, -i]
        entry: "^(?:[ \t>]*)(?:co-authored-by:[^\n]*(?:claude|copilot|chatgpt)|\U0001F916)"
```

At the `commit-msg` stage pre-commit passes the commit message file as the
hook's filename, so the pattern runs against the message, not the diff.

---

## Pattern: Anchor the Match, or Documentation Cannot Be Committed

A repository that documents a prohibited string contains that string. An
unanchored pattern blocks the very commit that adds the documentation.

Match the structural form, not the words:

```
^co-authored-by:[^\n]*<vendor>     matches a trailer line
.*co-authored-by.*                 also matches "we prohibit Co-Authored-By"
```

Test both directions before shipping. The allow cases matter as much as the
block cases:

- a real trailer, several vendor spellings and letter cases
- the same phrase inside ordinary prose
- a trailer naming a human, which stays legitimate
- the detection regex itself, quoted in a skill or doc

Replay real history rather than synthetic strings:

```bash
git log --all --format='%H' | while read -r c; do
  git log -1 --format=%B "$c" > /tmp/m.txt
  pre-commit run --hook-stage commit-msg --commit-msg-filename /tmp/m.txt <id> \
    >/dev/null 2>&1 || echo "would block $c"
done
```

---

## Pattern: `--multiline` Turns On DOTALL

pre-commit's pygrep sets `re.MULTILINE | re.DOTALL` together. `.` then matches
newlines, so `^label:.*keyword` can match a `label:` on one line and a
`keyword` many lines below.

Use `[^\n]*` for "rest of this line". `.*` is almost never what you want in a
multiline pygrep pattern.

---

## Pattern: `core.hooksPath` Blocks Installation

pre-commit refuses to install while `core.hooksPath` is set, even when it
points at `.git/hooks`, the default. The message names the cause:

```
[ERROR] Cowardly refusing to install hooks with `core.hooksPath` set.
```

```bash
git config --get core.hooksPath        # check before assuming install worked
git config --unset-all core.hooksPath  # no-op when it pointed at the default
```

Always confirm the hook file exists rather than trusting the install output:

```bash
ls -l .git/hooks/commit-msg
```

---

## Limits Worth Documenting

A local hook only runs on a local commit. Commits created in the GitHub web
UI, including accepting a Copilot Autofix suggestion, are built server side
and never run one. Where a rule must hold for every commit, pair the hook with
a CI check over the pull request's commit range and say so in the rule, rather
than implying the hook is sufficient.

---

## See Also

- [`skills/secret-scanning.md`](secret-scanning.md)
- [`templates/.pre-commit-config.yaml`](../templates/.pre-commit-config.yaml)
- [`RULES.md` §18](../RULES.md#18-authorship-and-attribution-core)
