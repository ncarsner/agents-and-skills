# STRATEGY.md — Multi-Agent Project Execution Within Subscription Windows

A practical guide for completing a full project in one day using three phased
agent sessions, each constrained to a 5-hour subscription window.

---

## Core Constraint

Most subscription LLM agent plans enforce a 5-hour rolling usage window.
To ship a full project in a single day, divide work into three non-overlapping
sessions aligned with natural work rhythms:

| Session   | Time window      | Primary objective                     |
|-----------|------------------|---------------------------------------|
| Morning   | 08:00 – 12:00    | Architecture, scaffold, core logic    |
| Afternoon | 13:00 – 17:00    | Integration, data layer, tests        |
| Evening   | 18:00 – 22:00    | Polish, review, documentation, deploy |

Each session is self-contained: it begins from written context, produces
working artifacts, and ends with a written handoff so the next session
requires zero verbal re-orientation.

---

## Strategy 1 — Session-Scoped Context Documents

Each session opens by reading one short context file and closes by updating it.
Never rely on conversational memory across session boundaries.

**Opening ritual (< 5 minutes):**

1. Read the most recent dated session summary (`yyyy-mm-dd-session-summary.md`).
2. Read `CLAUDE.md` / `GEMINI.md` / agent context file for current project state.
3. Read the `Next Steps` section only — ignore the rest of the summary.

**Closing ritual (< 10 minutes):**

1. Invoke the appropriate epilogue template (`templates/epilogue_claude.md`,
   `epilogue_gemini.md`, or `epilogue_codex.md`).
2. Write a dated session summary using the naming convention
   `yyyy-mm-dd-<phase>-summary.md` (e.g., `2026-04-29-morning-summary.md`).
3. Commit and push.

This keeps every session startup under 5 minutes and eliminates re-explanation.

---

## Strategy 2 — Narrow Scope Per Session, Broad Goals Per Day

Assign each session a single architectural layer. Crossing layers within one
session inflates context and wastes tokens.

| Session   | Scope                                              |
|-----------|----------------------------------------------------|
| Morning   | Project scaffold, domain models, core business logic |
| Afternoon | I/O layer (DB, APIs, CLI), integration, tests      |
| Evening   | Edge cases, security audit, docs, deploy pipeline  |

Within each session, use the `subagents/` roster to deploy a specialist rather
than a general-purpose agent. For example:

- Morning → `data-engineering-agent.md` or `cli-agent.md`
- Afternoon → `testing-agent.md` + `security-agent.md`
- Evening → `containerization-agent.md` + `senior-dev-review-agent.md`

One specialist agent per task keeps prompts lean and outputs deterministic.

---

## Strategy 3 — Skills Caching: Attach, Don't Repeat

Skills documents (`skills/`) are pre-written, condensed knowledge. Pass them
as attached context at session start instead of describing patterns inline.
This saves hundreds of tokens per interaction and improves consistency.

**Pattern:**

```
Read the following skills documents before proceeding:
  - skills/python-testing.md
  - skills/error-handling.md
  - skills/logging-observability.md
Then complete the task: <one-sentence task description>
```

Only attach skills relevant to the current session's scope. Attaching
unrelated skills wastes context budget. Update or extend a skills document
whenever a session discovers a better pattern — future sessions inherit the
improvement automatically.

---

## Strategy 4 — Subagent Decomposition at Session Boundaries

At the end of each session, decompose the next session's work into discrete
subtasks and assign each to a named subagent. Write these assignments into
the session summary under a `Subagent Plan` heading.

**Example (end of morning session):**

```markdown
## Subagent Plan — Afternoon Session

1. testing-agent: write unit tests for `src/pipeline/transform.py`; target 100% coverage.
2. security-agent: audit `src/api/routes.py` for injection and auth gaps.
3. data-engineering-agent: implement SQLAlchemy session management per `skills/database-access.md`.
```

The afternoon session opens these assignments and spawns one agent call per
subtask sequentially, each with a minimal prompt and the relevant skills file
attached. This avoids a bloated single prompt that wastes the context window.

---

## Strategy 5 — Progressive Documentation as a Project Asset

At the end of each day, the aggregate session summaries, updated skills files,
and context documents form a reusable asset for the next project.

**End-of-day actions:**

1. Consolidate the three phase summaries into a single
   `yyyy-mm-dd-project-retrospective.md` at the project root.
2. Extract any new patterns into a new or updated `skills/` document.
3. Update `AGENTS.md` if a new agent or workflow was used successfully.
4. Tag the commit with the project name:
   ```bash
   git tag project/<project-name>-complete
   git push origin --tags
   ```

The next project begins by reading the most recent retrospective and the
updated skills documents. The agents start with accumulated institutional
knowledge rather than from zero.

---

## Daily Execution Checklist

### Morning Session
- [ ] Read current context file and most recent retrospective
- [ ] Confirm session scope (architecture layer only)
- [ ] Attach relevant skills documents; deploy specialist subagent
- [ ] Produce: scaffold, models, core logic
- [ ] Write `yyyy-mm-dd-morning-summary.md`; commit and push

### Afternoon Session
- [ ] Read morning summary (`Next Steps` section only)
- [ ] Execute subagent plan from morning summary
- [ ] Attach relevant skills documents per subtask
- [ ] Produce: I/O layer, tests, integration
- [ ] Write `yyyy-mm-dd-afternoon-summary.md`; commit and push

### Evening Session
- [ ] Read afternoon summary (`Next Steps` section only)
- [ ] Execute subagent plan from afternoon summary
- [ ] Run full CI checks; invoke review agents
- [ ] Produce: hardened, documented, deployable artifact
- [ ] Write `yyyy-mm-dd-evening-summary.md`; commit and push
- [ ] Consolidate into `yyyy-mm-dd-project-retrospective.md`
- [ ] Extract new patterns into `skills/`; update `AGENTS.md` if needed
- [ ] Tag commit; push tags

---

## Anti-Patterns to Avoid

- Carrying context verbally across sessions — always write it down.
- Assigning a generalist agent to a specialist task — use the `subagents/` roster.
- Attaching all skills files at once — attach only what the session needs.
- Skipping the closing ritual — one missed summary breaks the next session's startup.
- Mixing architectural layers in one session — context bloat stalls progress.
