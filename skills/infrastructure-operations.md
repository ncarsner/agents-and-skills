# Skill: Infrastructure and Operations

Patterns for feature flags, canary/blue-green deployment validation, and
operational conventions for agent-built services.

---

## Feature Flags

Feature flags allow incomplete or experimental features to ship behind a gate,
decoupling deployment from release.

### Approved Approaches

| Approach | When to use | Implementation |
|----------|------------|---------------|
| Environment variable | Simple on/off for a single env | `os.getenv("ENABLE_NEW_FEATURE", "false") == "true"` |
| `flagsmith` | Multi-environment, user-segment flags | `uv add flagsmith` |
| `launchdarkly` | Enterprise; real-time flag updates | `uv add launchdarkly-server-sdk` |

Default to the **environment variable approach** for agent-generated code unless
the project has already adopted a flag management service.

### Environment Variable Pattern

```python
import os


def feature_enabled(flag: str, default: bool = False) -> bool:
    """Return True if the named feature flag is enabled.

    Args:
        flag: Environment variable name (e.g. "ENABLE_NEW_PARSER").
        default: Value when the variable is unset.

    Returns:
        True when the flag is explicitly set to "true" or "1".
    """
    val = os.getenv(flag, "").strip().lower()
    if not val:
        return default
    return val in {"true", "1", "yes"}
```

```python
# Usage
if feature_enabled("ENABLE_NEW_PARSER"):
    result = new_parser(data)
else:
    result = legacy_parser(data)
```

### Flag Lifecycle Rules

- Every flag must have a declared **owner** (person or team) and a **removal date**
  in a comment adjacent to its usage:
  ```python
  # FLAG: ENABLE_NEW_PARSER, owner: @ncarsner, remove after: 2026-08-01
  if feature_enabled("ENABLE_NEW_PARSER"):
  ```
- Flags older than their removal date are stale and must be cleaned up in the next
  sprint. The default behavior (feature fully on or fully off) must be committed
  before the flag is deleted.
- Never nest feature flags more than one level deep.
- Do not use feature flags to hide broken code indefinitely; flags are not a
  substitute for fixing the underlying issue.

---

## Canary and Blue/Green Deployment Validation

`RULES.md §17` defines the blue/green deployment procedure. This section defines
the **success metrics agents must validate** before a full cutover and the
**rollback decision rules**.

### Pre-Cutover Smoke Tests

Run against the green environment before switching the load balancer:

```bash
# 1. Liveness: process is running
curl -sf http://<green-host>/health | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['status'] == 'ok', f'health check failed: {d}'
print('liveness OK')
"

# 2. Readiness: dependencies reachable
curl -sf http://<green-host>/ready | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['status'] == 'ready', f'readiness failed: {d}'
print('readiness OK')
"

# 3. Synthetic critical-path request
curl -sf -X POST http://<green-host>/api/v1/items/ \
  -H "Content-Type: application/json" \
  -d '{"name": "smoke-test", "value": 1.0}' | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert 'id' in d, f'unexpected response: {d}'
print('critical path OK')
"
```

All three must pass before the load balancer switches. If any fails: abort
cutover, leave blue active, open an incident.

### Success Metrics for Full Cutover

Monitor these for **at least 5 minutes** after switching traffic to green:

| Metric | Threshold | Action on breach |
|--------|-----------|-----------------|
| HTTP 5xx error rate | ≤ 1% of requests | Immediate rollback to blue |
| p95 response latency | ≤ 200 ms (or project target) | Immediate rollback to blue |
| Unhandled exception rate | 0 new exception types | Investigate; rollback if persistent |
| Database connection errors | 0 | Immediate rollback to blue |

### Rollback Procedure

```bash
# 1. Switch load balancer back to blue (exact command depends on infra)
# AWS ALB example:
aws elbv2 modify-listener \
  --listener-arn <listener-arn> \
  --default-actions Type=forward,TargetGroupArn=<blue-target-group-arn>

# 2. Verify blue is serving traffic
curl -sf http://<blue-host>/health

# 3. Open incident issue
gh issue create \
  --title "Rollback: <service> vX.Y.Z, <date>" \
  --body "Rolled back from green (vX.Y.Z) to blue (vX.Y.Z-1). Trigger: <metric that breached>."

# 4. Keep green running for post-mortem analysis: do not tear it down yet
```

Agents must not trigger a rollback without logging the triggering metric and
opening a GitHub issue. Human approval is required before any force-push or
database migration rollback.

---

## See Also

- [`RULES.md §17`](../RULES.md#17-deployment-and-environment-parity-profileservice): deployment standards
- [`skills/containerization.md`](containerization.md): Docker and health check setup
- [`skills/web-development.md`](web-development.md): `/health` and `/ready` endpoint pattern
- [`skills/secret-scanning.md`](secret-scanning.md): credential rotation
