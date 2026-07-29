# Agent Protocol Reference

This document defines the protocol and directives that agents must follow when operating within this project. Agents should read and internalize these guidelines before executing any task.

---

## 1. Agent Identity

Every agent must declare:

- **Name** — a unique, lowercase, hyphenated identifier (e.g., `code-review-agent`).
- **Role** — a single sentence describing what the agent is responsible for.
- **Scope** — the set of tasks, files, or domains the agent is permitted to act on.

---

## 2. Input Processing Directives

When an agent receives a task, it must follow this sequence:

1. **Parse the task** — Extract the intent, target, and any constraints from the input.
2. **Validate scope** — Confirm the task falls within the agent's declared scope. Reject out-of-scope tasks immediately with a clear explanation. Also check pipeline stage: if `plans/*.json` exists with `done:false` tasks, the correct action is `/ralph`, not direct implementation or `/ideate`. If no `plans/*.json` exists and the task is a new feature, begin at `/ideate` and do not implement until issues exist.
3. **Identify required skills** — Determine which registered skills are needed to complete the task (see `skills/` directory).
4. **Plan before acting** — Produce a short ordered list of steps before executing any action.
5. **Execute step-by-step** — Carry out each planned step in order. Do not skip steps.
6. **Report outcome** — Return a structured result (see Section 5).

---

## 3. Decision-Making Rules

Agents must abide by the following rules at all times:

- **Least-privilege action** — Take the smallest action necessary to fulfill the task. Do not modify anything outside the declared scope.
- **No hallucination** — If the agent lacks sufficient context or data, it must say so rather than guess or fabricate output.
- **Determinism** — Given the same input and context, an agent must produce the same output. Avoid randomness unless explicitly instructed.
- **Explainability** — Every non-trivial decision must be accompanied by a brief rationale.
- **Human escalation** — If a task is ambiguous, potentially destructive, or outside defined scope, pause and request human clarification before proceeding.

---

## 4. Skill Invocation Protocol

When calling a skill:

1. Reference the skill by its canonical name as defined in `skills/skills.md`.
2. Pass only the data the skill explicitly requires — do not expose unrelated context.
3. Validate the skill's output before using it in downstream steps.
4. If a skill returns an error, log it and halt unless a fallback is defined.

```
INVOKE SKILL: <skill-name>
  INPUT: <structured input>
  ON ERROR: <halt | fallback-skill-name | ignore>
```

## 4.1. Cross-Agent Skill Reuse

Skills in `skills/` are shared across all registered agents. To reference a skill
from any agent:

- Name the skill file by its canonical path: `skills/<name>.md`.
- In a headless prompt, include the relevant excerpt directly rather than assuming
  the subagent can read files.
- Never duplicate skill content inside an agent definition file — reference the
  canonical `skills/` file to prevent drift between copies.
- If a skill needs to be extended for a specific agent's domain, add a new section
  to the skill file under a clearly labeled heading (e.g., `## For data-engineering-agent`).
  Do not fork the file.

Example reference in an agent prompt:

```
Follow the retry and backoff patterns defined in skills/api-integration.md §Rate Limiting.
```

---

## 5. Output Format

All agent responses must follow this structure:

```
AGENT: <agent-name>
TASK:  <one-line task summary>
STATUS: <completed | failed | escalated>

STEPS TAKEN:
  1. <description of step>
  2. <description of step>
  ...

RESULT:
  <The output, finding, or artifact produced by the agent.>

NOTES (optional):
  <Any caveats, assumptions made, or follow-up recommendations.>
```

### Response Style Rules

- Write in plain prose. Do not use markdown stylizing such as bold (**text**),
  italics (*text*), or inline emphasis in running text.
- Use plain numbered lists and plain bullet lists only.
- Tables are permitted for structured data comparisons.
- Code blocks (triple-backtick fences) are permitted for code and commands.
- Headers (# / ##) are permitted only inside generated documents, not in
  conversational or status responses.
- Never underline text.
- No emojis unless the user explicitly requests them.
- No em dashes (`—`) in any documentation, comments, or agent-generated text. Use commas, colons, or rewrite the sentence.

---

## 6. Error Handling

| Situation | Required Action |
|---|---|
| Out-of-scope task | Reject with explanation; do not attempt. |
| Missing context | Request clarification before proceeding. |
| Skill invocation failure | Log error; halt or use defined fallback. |
| Ambiguous instructions | Escalate to human; do not guess. |
| Partial completion | Report completed steps and reason for halting. |

---

## 7. Constraints

- Agents **must not** modify files outside their declared scope without explicit human approval.
- Agents **must not** store, log, or transmit sensitive data (credentials, PII, proprietary content).
- Agents **must not** invoke other agents directly; all cross-agent coordination must go through the orchestrator.
- Background agents operating in a worktree **must not** modify files in
  `skills/`, `subagents/`, or `templates/` unless that modification is the
  explicit, sole scope of the task. These are shared reference libraries;
  a worktree edit is isolated to that branch until merged, and concurrent
  worktrees touching the same reference file produce avoidable merge
  conflicts. Improvements to reference libraries discovered incidentally
  during a background task belong in a dedicated feature branch, noted in
  the task's output, not applied in-flight.

---

## 8. Creating a New Agent

To add a new agent to this project:

1. Create a markdown file in this directory named `<agent-name>.md`.
2. Follow the template below:

```markdown
# Agent: <agent-name>

**Role:** <one sentence>
**Scope:** <files, domains, or task types this agent handles>
**Skills Used:** <comma-separated list of skill names from skills/skills.md>

## Directives
<Any agent-specific rules or overrides to the base protocol above.>

## Examples
<One or two example tasks and expected outputs.>
```

---

## 8.1. Agent and Skill Versioning

### Version Field

Every agent and skill file should declare its version in the header:

```
**Version:** 1.0.0
```

Format: `MAJOR.MINOR.PATCH` per semantic versioning.

| Increment | When to use |
|-----------|------------|
| MAJOR | Breaking change to the agent's scope, interface, or required inputs |
| MINOR | New capability, new section, or significant behavior change |
| PATCH | Correction, clarification, or minor wording update |

### Changelog Convention

Each file should maintain a changelog table near its end:

```markdown
## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | YYYY-MM-DD | Initial version |
```

### Deprecation Policy

1. Add a deprecation notice at the top of the file:

```
> **DEPRECATED as of YYYY-MM-DD.** Use `<replacement-file>` instead.
> This file will be removed on YYYY-MM-DD (30 days after deprecation).
```

2. Set `"status": "deprecated"` in `subagents/registry.json` with
   `"deprecation_date"` and `"removal_date"`.
3. Deprecated files remain for **30 days**, then are deleted.
4. Any agent that depends on a deprecated file must be updated before
   its removal date.

### Machine-Readable Registry

`subagents/registry.json` catalogs all agents and skills with their domain,
version, and status. Update it whenever an agent or skill file is added,
modified to a new MINOR/MAJOR version, deprecated, or removed.

---

## 9. Registered Agents

| Agent file | Role |
|-----------|------|
| [`cli-agent.md`](cli-agent.md) | Build terminal-based CLI tools |
| [`web-dev-agent.md`](web-dev-agent.md) | Build REST APIs and web services |
| [`data-engineering-agent.md`](data-engineering-agent.md) | Build ETL pipelines and database integrations |
| [`nlp-agent.md`](nlp-agent.md) | Build NLP and text-analysis systems |
| [`legal-fiscal-agent.md`](legal-fiscal-agent.md) | Analyze legal documents and financial data |
| [`dashboard-reporting-agent.md`](dashboard-reporting-agent.md) | Build dashboards and generate reports |
| [`process-modernization-agent.md`](process-modernization-agent.md) | Modernize legacy processes |
| [`security-agent.md`](security-agent.md) | Audit and harden application security |
| [`testing-agent.md`](testing-agent.md) | Design and implement test suites |
| [`containerization-agent.md`](containerization-agent.md) | Containerize projects with Docker; guide deployment and maintenance |
| [`accounting-agent.md`](accounting-agent.md) | Monitor token usage and estimate cost |
| [`project-review-senior-dev.md`](project-review-senior-dev.md) | Ad hoc review: architectural efficiency and code quality |
| [`project-review-vp.md`](project-review-vp.md) | Ad hoc review: risk/reward tradeoffs |
| [`project-review-cto.md`](project-review-cto.md) | Ad hoc review: C-suite strategic overview |
| [`project-review-accessibility.md`](project-review-accessibility.md) | Identify accessibility deficiencies in public-facing projects and publications |
| [`project-review-pm.md`](project-review-pm.md) | Ad hoc review: product value, acceptance criteria, and release readiness |
| [`project-review-enterprise-architect.md`](project-review-enterprise-architect.md) | Ad hoc review: org-wide architecture standards and integration governance |
| [`project-review-scrum-master.md`](project-review-scrum-master.md) | Ad hoc review: sprint health, Definition of Done, and delivery process |
| [`project-review-change-manager.md`](project-review-change-manager.md) | Ad hoc review: rollout readiness, rollback plans, and stakeholder communication |
| [`project-review-interoperability.md`](project-review-interoperability.md) | Ad hoc review: API contracts, protocol correctness, and integration compatibility |
| [`project-review-observability.md`](project-review-observability.md) | Ad hoc review: logging, metrics, tracing, and audit log coverage |
| [`data-collection-agent.md`](data-collection-agent.md) | Audit and implement data collection pipelines: provenance, quality, PII, compliance |
| [`release-agent.md`](release-agent.md) | Manage PyPI package releases: semantic versioning, CHANGELOG, build, publish, GitHub Release |

---

## 10. External CLI Agents

The orchestrator may delegate to external headless agents. These agents are not governed by internal markdown files but must be invoked with specific constraints:

| Agent | CLI Command | Primary Use Case |
|-------|-------------|------------------|
| Claude | `claude -p ... --allowedTools "Read,Edit,Bash"` | Reasoning, complex edits, research |
| Codex | `codex exec ...` | Surgical generation, translations |

**Constraint:** Results from headless agents must be captured and summarized in the "Steps Taken" or "Result" section of the orchestrator's response.
