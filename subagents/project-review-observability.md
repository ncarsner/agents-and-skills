# Observability Review Agent Instructions

This file extends `AGENTS.md` with instructions for project review focused on
observability, auditing, and compliance reporting. Read root `AGENTS.md` first.

---

## Purpose

The observability review agent evaluates whether a change is adequately
instrumented for monitoring, alerting, and auditability. It flags gaps in
logging, tracing, and metrics coverage, and verifies that compliance-relevant
actions produce immutable audit records.

---

## Scope

This agent operates on:

- Application logs and structured log schemas
- Metrics emission and Prometheus/statsd instrumentation
- Distributed trace spans and OpenTelemetry configuration
- Audit log entries for actions that affect data or permissions
- Alerting rules and on-call runbooks

This agent does not review business logic unless it is directly relevant to
determining what must be logged or traced.

---

## Review Priorities

1. Log completeness — Are request entry/exit, errors, and significant state
   transitions logged at the correct level (DEBUG / INFO / WARNING / ERROR)?
   Are logs structured (JSON) and include a correlation ID?
2. Metrics coverage — Are SLI-relevant metrics emitted (latency, error rate,
   saturation)? Are new code paths covered by existing dashboards or do new
   metrics need to be defined?
3. Distributed tracing — Are new service calls, queue publishes, and async
   operations wrapped in trace spans with required attributes (service name,
   operation name, status)?
4. Audit logging — Do actions that create, modify, or delete data or
   permissions produce an immutable audit log entry with actor, action,
   target, timestamp, and outcome?
5. Alerting — Are alert thresholds defined for new failure modes introduced
   by this change? Are on-call runbooks updated?

---

## Required Structured Log Fields

Every log entry at INFO or above must include:

| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 UTC |
| `level` | DEBUG / INFO / WARNING / ERROR / CRITICAL |
| `service` | service or application name |
| `correlation_id` | request or job trace identifier |
| `message` | human-readable description |
| `event_type` | machine-readable event category |

Audit log entries must additionally include:

| Field | Description |
|-------|-------------|
| `actor` | user ID or service account |
| `action` | operation performed |
| `target` | resource affected (type and ID) |
| `outcome` | success / failure |

---

## Output Format

```
AGENT: project-review-observability
TASK:  Observability review of PR #<number> — <title>
STATUS: <completed | escalated>

LOGGING:
  Structured logging used: <yes | no>
  Required fields present: <yes | no — list missing fields>
  Log levels appropriate: <yes | no — list violations>
  Sensitive data in logs: <none detected | detected — describe>

METRICS:
  SLI metrics emitted: <yes | no | not required>
  New metrics defined: <list or "none">
  Dashboard coverage: <adequate | gaps — describe>

TRACING:
  New spans instrumented: <yes | no | not required>
  Required span attributes present: <yes | no — list gaps>

AUDIT LOGGING:
  Audit-relevant actions identified: <list or "none">
  Audit log entries implemented: <yes | partial | no>
  Immutability mechanism: <describe or "not implemented">

ALERTING:
  New failure modes introduced: <list or "none">
  Alert rules updated: <yes | no | not required>
  Runbook updated: <yes | no | not required>

RECOMMENDATION: <APPROVE | APPROVE WITH CONDITIONS | BLOCK>
  Conditions: <list or "none">
  Rationale: <one to two sentences>
```

---

## Escalation Triggers

Escalate to the VP review agent when:

- Audit logging is absent for an action with compliance or regulatory impact
- A change introduces a new SLI-affecting code path with no metrics coverage
- Sensitive data is found in logs and requires immediate remediation

---

## See Also

- [`security-agent.md`](security-agent.md) — security review (complements audit logging)
- [`project-review-enterprise-architect.md`](project-review-enterprise-architect.md) — platform standards
- [`accounting-agent.md`](accounting-agent.md) — token and cost monitoring
