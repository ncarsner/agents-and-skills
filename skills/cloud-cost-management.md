# Skill: Cloud Resource Cost Management

Guidelines for managing cloud compute, storage, and service costs for
agent-based deployments. Any infrastructure-touching PR must include a
cost-review section in the PR description.

---

## Tagging Conventions

All cloud resources must be tagged at creation. These tags enable cost
attribution by workload, owner, and environment.

### Required Tags

| Tag key | Values | Purpose |
|---------|--------|---------|
| `project` | `<repo-slug>` | Top-level cost grouping |
| `env` | `development` · `staging` · `production` | Per-environment cost split |
| `owner` | GitHub username or team slug | Accountability |
| `workload` | `api` · `batch` · `etl` · `cli` · `infra` | Workload type for right-sizing |
| `cost-center` | `<department or project code>` | Finance attribution |

Add tags at resource creation — retrofitting tags is error-prone and misses
historical spend.

### Terraform/IaC Example

```hcl
locals {
  common_tags = {
    project     = "agents-and-skills"
    env         = var.environment
    owner       = "ncarsner"
    workload    = "api"
    cost-center = "engineering"
  }
}

resource "aws_instance" "app" {
  # ...
  tags = local.common_tags
}
```

---

## Automated Budget Alerts

Set budget alerts before deploying to staging or production. Never rely on
manual review to catch cost overruns.

### Alert Thresholds

| Alert type | Threshold | Notification |
|-----------|-----------|-------------|
| Monthly actual spend | 80% of budget | Email + Slack `#infra-alerts` |
| Monthly actual spend | 100% of budget | Email + Slack + open GitHub issue |
| Daily spike | > 2× 7-day average | Email + open GitHub issue |
| Forecasted monthly | > 120% of budget | Email + Slack |

### AWS Budgets (CLI setup)

```bash
aws budgets create-budget \
  --account-id <account-id> \
  --budget '{
    "BudgetName": "<project>-<env>-monthly",
    "BudgetLimit": {"Amount": "200", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {"TagKeyValue": ["project$<project-slug>"]}
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "<owner-email>"}]
  }]'
```

---

## Right-Sizing Recommendations

### Compute (EC2 / Cloud Run / ECS)

| Workload | Starting size | Scale trigger | Notes |
|----------|-------------|--------------|-------|
| API service (FastAPI/Flask) | 0.5 vCPU · 512 MB | p95 CPU > 70% for 5 min | Use autoscaling; never over-provision |
| Batch ETL job | 1 vCPU · 1 GB per worker | Job duration > 2× budget | Prefer spot/preemptible instances |
| CLI tool (one-shot) | 0.25 vCPU · 256 MB | N/A (ephemeral) | Use serverless (Lambda, Cloud Run jobs) |
| NLP/ML inference | 2 vCPU · 4 GB | p95 latency > 500 ms | Evaluate GPU only after CPU profiling |

### Storage

| Storage type | Use case | Cost control |
|-------------|---------|-------------|
| Object storage (S3, GCS) | Raw data, backups, reports | Lifecycle rules: move to IA after 30 days, Glacier after 90 days |
| Relational DB (RDS, Cloud SQL) | Transactional data | Use db.t3.micro for dev; reserved instances for production |
| Managed cache (ElastiCache) | Session cache, rate-limit counters | Eviction policy: `allkeys-lru`; size to fit working set |

Enable storage lifecycle rules at bucket/volume creation — do not add them later.

---

## Cost-Review Checklist (Required in Infrastructure PRs)

Every PR that creates, modifies, or deletes cloud resources must include this
section in the PR description:

```markdown
## Cost Review

- [ ] New resources tagged with all required tags (project, env, owner, workload, cost-center)
- [ ] Monthly cost estimate added below
- [ ] Budget alert configured (or existing alert covers this resource)
- [ ] Storage lifecycle rules set (if applicable)
- [ ] Instance size justified against right-sizing table
- [ ] Spot/preemptible instances used for batch workloads where possible
- [ ] No resources left running in development after testing is complete

### Estimated Monthly Cost

| Resource | Size | Estimated cost/month |
|----------|------|---------------------|
| | | |
| **Total** | | **$X.XX** |

Cost estimated using: [AWS Pricing Calculator](https://calculator.aws) /
[GCP Pricing Calculator](https://cloud.google.com/products/calculator) /
[Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/).
```

---

## See Also

- [`skills/containerization.md`](containerization.md) — right-sizing in Docker/Kubernetes context
- [`skills/cost-management.md`](cost-management.md) — LLM API token cost tracking
- [`RULES.md §17`](../RULES.md#17-deployment-and-environment-parity) — deployment standards
