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
2. **Validate scope** — Confirm the task falls within the agent's declared scope. Reject out-of-scope tasks immediately with a clear explanation.
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
- Agents **must** version-stamp any artifact they produce with the task ID and timestamp.

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
