#!/usr/bin/env bash
# Run this locally with: bash /tmp/create_issues.sh
# Prerequisites: gh CLI installed and authenticated (gh auth login)
set -e
REPO="ncarsner/agents-and-skills"

echo "Creating 20 issues in $REPO..."

# Issue 1
gh issue create --repo "$REPO" \
  --title "Security: Secret Scanning & Pre-commit Hook Integration" \
  --body "Define mandatory pre-commit hook setup using \`git-secrets\` or \`trufflehog\` for all projects derived from these templates.

Document the installation steps, CI enforcement gate, and the exact rotation/remediation steps when a secret is accidentally committed (currently only loosely described in RULES.md §8)."

echo "Created issue 1"

# Issue 2
gh issue create --repo "$REPO" \
  --title "Security: Dependency Vulnerability Scanning in CI" \
  --body "Establish \`pip-audit\` (or equivalent) as a required CI step for all new and existing dependencies.

Define severity thresholds: CRITICAL/HIGH must block the PR; MEDIUM must be reviewed within 30 days; LOW is advisory. Add the scan command to the Quick Reference in \`AGENTS.md\` and require it before any \`uv add\` in RULES.md §5."

echo "Created issue 2"

# Issue 3
gh issue create --repo "$REPO" \
  --title "Security: Data Privacy, PII Handling & Compliance Rules" \
  --body "Fill in the \`RULES.md\` \"Placeholder: Data Privacy and Compliance\" section.

Define data classification levels (public / internal / confidential / restricted), required anonymization steps, retention/deletion policies, audit trail requirements, and applicable regulatory frameworks (GDPR, CCPA, HIPAA). Map each framework to concrete code practices agents must follow."

echo "Created issue 3"

# Issue 4
gh issue create --repo "$REPO" \
  --title "Testing: Integration & End-to-End Test Standards" \
  --body "The current testing skill covers unit tests well but leaves integration and E2E tests undefined.

Define where integration tests live (\`tests/integration/\`), what constitutes a boundary to mock vs. hit live, and when E2E tests are required. Add a target coverage minimum for integration tests (suggested: 80%) and document approved HTTP-mocking libraries (e.g., \`responses\`, \`httpretty\`)."

echo "Created issue 4"

# Issue 5
gh issue create --repo "$REPO" \
  --title "Testing: Property-Based & Mutation Testing Strategy" \
  --body "Define optional but recommended practices for property-based testing with \`Hypothesis\` and mutation testing with \`mutmut\`.

Specify when these techniques must be applied (e.g., any parsing or financial calculation module), how to interpret mutation scores, and how mutation testing fits into CI without becoming a performance bottleneck."

echo "Created issue 5"

# Issue 6
gh issue create --repo "$REPO" \
  --title "Publishing: Package Release Workflow & PyPI Standards" \
  --body "Define the end-to-end release workflow: semantic versioning policy (\`semver\`), \`CHANGELOG.md\` format (Keep a Changelog), how to publish via \`uv publish\` or \`twine\`, PyPI token storage (GitHub Actions secret), and the required CI gates (all tests + lint + type-check + audit must pass) before a release tag is cut.

Add a \`release-agent.md\` or a publishing section to the existing \`web-dev-agent.md\`."

echo "Created issue 6"

# Issue 7
gh issue create --repo "$REPO" \
  --title "Containerization: Docker Standards & Image Conventions" \
  --body "Define Dockerfile conventions for Python projects: required base image (e.g., \`python:3.12-slim\`), mandatory multi-stage builds to minimize image size, \`COPY --chown\` and non-root user requirements, \`.dockerignore\` standards, and container image scanning (e.g., \`trivy\` in CI).

Add a \`containerization.md\` skill file and reference it from \`AGENTS.md\`."

echo "Created issue 7"

# Issue 8
gh issue create --repo "$REPO" \
  --title "Containerization & CI/CD: Environment Parity & Pipeline Gates" \
  --body "Fill in the \`RULES.md\` \"Placeholder: Deployment and Environment Parity\" section.

Define required environment variables per deployment tier, Docker Compose setup for local development, mandatory CI/CD gates (tests + lint + type-check + security scan must all pass before deploy), and blue/green deployment conventions. Reference the containerization skill from the Docker Standards issue."

echo "Created issue 8"

# Issue 9
gh issue create --repo "$REPO" \
  --title "Cost Evaluation: LLM/AI API Usage Tracking & Budget Guardrails" \
  --body "Define how agents that call LLM APIs (OpenAI, Anthropic, etc.) must estimate, track, and cap token costs.

Include: required logging of token counts per call, a \`MAX_TOKENS_PER_SESSION\` environment variable convention, pre-flight cost estimation before long batch operations, and alert thresholds. Add a \`cost-management.md\` skill file covering prompt efficiency patterns."

echo "Created issue 9"

# Issue 10
gh issue create --repo "$REPO" \
  --title "Cost Evaluation: Cloud Resource Cost Management Guidelines" \
  --body "Define guidelines for managing cloud compute, storage, and service costs for agent-based deployments.

Include: tagging conventions for cost attribution, automated budget alerts, right-sizing recommendations for common workloads (batch ETL, API services, CLI tools), and a cost-review checklist agents must include in any infrastructure-touching PR."

echo "Created issue 10"

# Issue 11
gh issue create --repo "$REPO" \
  --title "Reporting: Structured Output Standards & Report Generation" \
  --body "Expand \`skills/dashboarding-reporting.md\` with formal output standards: required fields for any machine-readable report (timestamp, run ID, status, source agent), supported formats (JSON, CSV, HTML, PDF), and the approved libraries per format (\`openpyxl\` for Excel, \`weasyprint\` for PDF, \`plotly\` for interactive HTML).

Define a standard report manifest schema agents must follow."

echo "Created issue 11"

# Issue 12
gh issue create --repo "$REPO" \
  --title "Feedback: Human-in-the-Loop Review & Escalation Protocol" \
  --body "Fill in the \`RULES.md\` \"Placeholder: Code Review and Approval Workflow\" section.

Define: minimum number of human approvals per PR type (hotfix vs. feature vs. architectural), automated checks that must pass before review is requested, a review checklist (security, performance, coverage), rules for handling disagreements, and the escalation path for architectural decisions."

echo "Created issue 12"

# Issue 13
gh issue create --repo "$REPO" \
  --title "Feedback: Agent Session Summary & Handoff Protocol" \
  --body "Define a standard protocol for agents to summarize their work at the end of a session.

Include: required fields in a session summary (objective, actions taken, files changed, tests run, open questions), where summaries are stored (PR description, a summary comment, or a \`session_summary.md\`), and how summaries are used by subsequent agents to pick up context without re-reading the full history."

echo "Created issue 13"

# Issue 14
gh issue create --repo "$REPO" \
  --title "Rules: Performance Standards & Profiling Requirements" \
  --body "Fill in the \`RULES.md\` \"Placeholder: Performance Standards\" section.

Define: maximum acceptable latency for API endpoints (p95 < 200 ms suggested), batch job runtime budgets, memory usage limits, approved profiling tools (\`cProfile\`, \`py-spy\`, \`memray\`), when a performance regression must be escalated, and an authorized caching library list."

echo "Created issue 14"

# Issue 15
gh issue create --repo "$REPO" \
  --title "Rules: Accessibility & Internationalization Standards" \
  --body "Fill in the \`RULES.md\` \"Placeholder: Accessibility and Internationalization\" section.

Define: locale and timezone handling via \`zoneinfo\` and \`babel\`, string externalization for i18n using \`gettext\`, WCAG 2.1 AA compliance requirements for any web UI produced by agents, and required accessibility testing tools (e.g., \`axe-core\` for web, contrast checks for CLI color output)."

echo "Created issue 15"

# Issue 16
gh issue create --repo "$REPO" \
  --title "Agent Registry: Versioning, Deprecation & Discovery" \
  --body "Define a versioning scheme for agent and skill files (e.g., a \`version:\` frontmatter field), a changelog convention per file, a deprecation policy (how long deprecated agents stay before removal), and a machine-readable registry (\`agents/registry.json\`) that catalogs all agents with their domain, version, and dependencies.

This enables automated discovery and dependency tracking."

echo "Created issue 16"

# Issue 17
gh issue create --repo "$REPO" \
  --title "Agent Chaining: Multi-Agent Coordination & Context Passing" \
  --body "Define the protocol for chaining agents together: how one agent hands off to another, what context is required in the handoff payload, how conflicts between agent instructions are resolved, how to detect and break infinite loops, and what logging is required for each agent invocation in a chain.

Add a \`multi-agent.md\` skill file."

echo "Created issue 17"

# Issue 18
gh issue create --repo "$REPO" \
  --title "Composite: Infrastructure & Operations Gaps" \
  --body "Collects smaller items not yet warranting standalone issues:

- **Feature flags**: Define an approved library (\`flagsmith\`, \`launchdarkly\`, env-var-based) and agent rules for flag-guarding incomplete features.
- **Canary/blue-green deploys**: Document the rollback procedure and success metrics agents must validate before full cutover.
- **Secrets rotation scheduling**: Define how agents detect and alert on credentials approaching expiration.
- **Rate limiting & backoff**: Add a standard retry/backoff recipe to \`skills/api-integration.md\` covering 429 and 503 responses.
- **Health checks**: Define a \`/health\` endpoint convention and required liveness/readiness probes for containerized services."

echo "Created issue 18"

# Issue 19
gh issue create --repo "$REPO" \
  --title "Composite: Documentation, Prompt Engineering & Knowledge Management" \
  --body "Collects smaller documentation and AI-specific items:

- **Prompt engineering standards**: Define how agents must structure prompts (role, context, constraints, output format) and prohibit prompt injection patterns.
- **\`authorized_libraries.md\` template**: RULES.md §5 references this file but no template exists in \`/templates/\`; create it.
- **Cross-agent skill reuse**: Document how to reference a skill from one agent to avoid duplication.
- **Changelog for \`AGENTS.md\` and \`RULES.md\`**: Add a \"Last updated / Change log\" section so agents can detect stale instructions.
- **Onboarding checklist**: A step-by-step checklist new agents run on first encounter with any project derived from these templates."

echo "Created issue 19"

# Issue 20
gh issue create --repo "$REPO" \
  --title "Composite: Observability, Auditing & Compliance Reporting" \
  --body "Collects smaller observability and audit items:

- **Structured audit logs**: Define which agent actions require an immutable audit log entry (schema, destination, retention).
- **Distributed tracing**: Define when to add \`opentelemetry\` instrumentation and the required span attributes.
- **Alerting thresholds**: Document approved alerting integrations (PagerDuty, Slack webhooks) and required alert fields.
- **Compliance report generation**: Define the format and schedule for automated compliance reports agents must produce for regulated projects.
- **Agent action dry-run mode**: Define a \`--dry-run\` flag convention agents must implement before any destructive operation."

echo "Created issue 20"

echo ""
echo "All 20 issues created successfully in $REPO"
