---
name: orient
description: Bootstrap agent context by reading AGENTS.md, RULES.md, the subagent registry, and the skills index, then surveying the repo structure. Run at the start of every new session before acting on any task.
disable-model-invocation: true
allowed-tools: Read Bash
---

Orient yourself to this repository before acting. Complete all five steps in order.

## Step 1 — Core identity and rules

Read both files in full:

- `AGENTS.md` — agent identity, toolchain, post-edit checklist, and on-demand resource table
- `RULES.md` — mandatory compliance rules (all 12 enforced sections + placeholders)

Key rules to internalize:
- Package manager: `uv` only (RULES.md §1)
- Python executable: `python3` only (RULES.md §2)
- Docstrings + type hints required on all public symbols (RULES.md §3)
- No secrets in source; load via env vars (RULES.md §8)
- No agent attribution in commits or PRs (RULES.md §6)
- 100% test coverage target for new modules (RULES.md §7)

## Step 2 — Delegation and skills registry

Read both index files:

- `subagents/subagents.md` — agent identity protocol, delegation rules, registered agents
- `skills/skills.md` — available reference files and invokable slash commands

## Step 3 — Content catalog query (pre-fetch)

Grep `index.md` for pages matching the incoming task's domain keywords
(if $ARGUMENTS is non-empty). Load only the matching `sessions/` pages from
the project root; do not read the whole catalog into context. This closes 12-Factor Agents
F13 (pre-fetch context); see `.12-FACTOR-AGENTS.md`.

```bash
grep -i "<keyword>" index.md
```

If no keywords match, or $ARGUMENTS is empty, skip loading any pages and
proceed to Step 4.

## Step 4 — Repo structure survey

```bash
find . -maxdepth 3 \
  -not -path './.git/*' \
  -not -path './.venv/*' \
  -not -path './node_modules/*' \
  -not -path './__pycache__/*' \
  | sort
```

Also run:

```bash
ls -1 subagents/ && ls -1 skills/
```

## Step 5 — Orientation summary

Report a concise summary covering:
1. Agent identity (from AGENTS.md §Identity)
2. Which subagents are registered and which to delegate to for the current task
3. Repo layout — top-level directories and their purpose
4. Any RULES.md constraints directly relevant to the current task (if one was provided via $ARGUMENTS)
5. Any `index.md` pages loaded in Step 3, and a one-line note on their relevance

If $ARGUMENTS is non-empty, treat it as the incoming task description and note which
registered subagent(s) and skills are relevant before proceeding.
