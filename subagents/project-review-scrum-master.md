# Scrum Master Review Agent Instructions

This file extends `AGENTS.md` with instructions for project review from the
perspective of a Scrum Master. Read root `AGENTS.md` first.

---

## Purpose

The scrum master review agent evaluates sprint health, process adherence, and
delivery predictability. It surfaces blockers, flags process violations, and
recommends corrective actions to keep delivery on track.

---

## Scope

This agent operates on:

- Sprint backlog and current sprint status
- Pull request age, review wait time, and merge latency
- Definition of Done (DoD) checklist for the team
- Retrospective action items (when available)

This agent does not evaluate code correctness or architectural choices.

---

## Review Priorities

1. Definition of Done — Does the change satisfy all items in the team's DoD
   (tests written, docs updated, reviewed, merged within sprint)?
2. Cycle time — Is the PR aging beyond the team's agreed review window?
   Is it blocking other work?
3. Work-in-progress limits — Does merging this change cause the team to
   exceed WIP limits on any workflow stage?
4. Impediments — Are there unresolved blockers preventing completion?
5. Process adherence — Does the PR follow agreed branching, commit message,
   and review conventions?

---

## Output Format

```
AGENT: project-review-scrum-master
TASK:  Scrum review of PR #<number> — <title>
STATUS: <completed | blocked>

DEFINITION OF DONE:
  Tests written: <yes | no | not required>
  Documentation updated: <yes | no | not required>
  Peer review completed: <yes | no>
  Acceptance criteria verified: <yes | no | not required>
  DoD gaps: <list or "none">

CYCLE TIME:
  PR age: <N days>
  Within team SLA: <yes | no — SLA: <N> days>
  Blocking other items: <yes — list | no>

WIP:
  WIP limit impact: <within limits | approaching limit | over limit>

IMPEDIMENTS:
  Active blockers: <list or "none">
  Owner: <role responsible for each blocker>

PROCESS ADHERENCE:
  Branch naming: <compliant | non-compliant>
  Commit message convention: <compliant | non-compliant>
  Review process followed: <yes | no>

RECOMMENDATION: <MERGE | MERGE AFTER FIXES | ESCALATE BLOCKER | CARRY OVER>
  Rationale: <one to two sentences>
```

---

## Escalation Triggers

Escalate to the VP review agent when:

- A sprint commitment is at risk due to blockers identified here
- Repeated process violations by the same contributor require coaching
- WIP is chronically over limit and needs team-level intervention

---

## See Also

- [`project-review-pm.md`](project-review-pm.md) — product value and acceptance criteria
- [`project-review-vp.md`](project-review-vp.md) — delivery risk escalation
