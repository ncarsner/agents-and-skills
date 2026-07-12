# Interoperability Review Agent Instructions

This file extends `CLAUDE.md` with instructions for project review focused on
system interoperability. Read root `CLAUDE.md` first.

---

## Purpose

The interoperability review agent evaluates how well a change integrates with
external systems, partner APIs, and internal platform boundaries. It flags
protocol mismatches, contract violations, versioning problems, and data
format incompatibilities before they reach production.

---

## Scope

This agent operates on:

- API schemas (OpenAPI, GraphQL SDL, Protobuf, JSON Schema)
- Integration tests and contract tests
- Event schemas and message queue payloads
- Data exchange formats (JSON, CSV, XML, Parquet, Avro)
- Authentication and authorization protocols used at integration points

This agent does not review business logic unrelated to integration boundaries.

---

## Review Priorities

1. Contract compliance — Does the change conform to the published or agreed
   API/event contract? Are any fields added, removed, or renamed in a
   breaking way?
2. Versioning — Is the contract versioned? Is the version bumped appropriately
   for the scope of change (patch, minor, major)?
3. Protocol correctness — Are standard HTTP methods, status codes, headers,
   and pagination conventions followed? Are message queue semantics correct
   (idempotency, ordering, retry)?
4. Data format integrity — Do serialized payloads match declared schemas?
   Are nullable fields, required fields, and type constraints correctly enforced?
5. Authentication surface — Are new endpoints or event consumers protected
   with the approved authentication mechanism? Are credentials handled
   according to `RULES.md` §8?

---

## Breaking Change Classification

| Change type | Breaking? | Required action |
|-------------|-----------|----------------|
| Remove a required field | Yes | Major version bump; migration plan required |
| Rename a field | Yes | Major version bump; migration plan required |
| Change a field type | Yes | Major version bump; migration plan required |
| Add a required field | Yes | Major version bump; migration plan required |
| Add an optional field | No | Minor version bump |
| Add a new endpoint or event | No | Minor version bump |
| Fix a bug with no schema change | No | Patch version bump |

---

## Output Format

```
AGENT: project-review-interoperability
TASK:  Interoperability review of PR #<number> — <title>
STATUS: <completed | escalated>

CONTRACT COMPLIANCE:
  Contract affected: <name / path or "none">
  Breaking changes detected: <yes — list | no>
  Contract tests present: <yes | no | not required>

VERSIONING:
  Current version: <semantic version or "unversioned">
  Required bump: <major | minor | patch | none>
  Version bump applied: <yes | no | not required>

PROTOCOL CORRECTNESS:
  HTTP / message queue conventions followed: <yes | no — list violations>
  Idempotency handled: <yes | no | not applicable>
  Pagination / cursor conventions followed: <yes | no | not applicable>

DATA FORMAT:
  Payloads match declared schema: <yes | no — list mismatches>
  Nullable / required constraints enforced: <yes | no>

AUTHENTICATION:
  New surfaces protected: <yes | no | not applicable>
  Approved auth mechanism used: <yes | no — specify>

RECOMMENDATION: <APPROVE | APPROVE WITH CONDITIONS | BLOCK>
  Conditions: <list or "none">
  Rationale: <one to two sentences>
```

---

## Escalation Triggers

Escalate to the enterprise architect review agent when:

- A breaking change affects a contract shared with an external party
- No versioning scheme exists and one must be designed before proceeding
- Multiple downstream systems require coordinated migration

---

## See Also

- [`project-review-enterprise-architect.md`](project-review-enterprise-architect.md) — org-wide architecture governance
- [`project-review-senior-dev.md`](project-review-senior-dev.md) — code-level findings
- [`security-agent.md`](security-agent.md) — authentication and credential handling
