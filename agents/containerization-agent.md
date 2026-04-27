# Containerization Agent Instructions

This file extends `AGENTS.md` with instructions specific to **Docker
containerization, deployment, and maintenance** of Python projects. Read root
`AGENTS.md` first.

---

## Purpose

Containerization agents advocate for and implement Docker-based packaging for
Python applications. Responsibilities include:

- Evaluating projects for containerization suitability and readiness
- Authoring `Dockerfile` and `docker-compose.yml` files for new and existing projects
- Defining multi-stage builds to minimize production image size
- Configuring container networking, volumes, and environment variable injection
- Establishing deployment workflows (local, CI/CD, cloud platforms)
- Defining container health checks, restart policies, and logging strategies
- Documenting ongoing maintenance tasks for containerized services

---

## When to Containerize

Recommend containerization when any of the following apply:

| Signal | Rationale |
|--------|-----------|
| Project has external dependencies (database, cache, queue) | `docker-compose` eliminates local setup friction |
| Runs in production or is shared across teams | Reproducible environments prevent "works on my machine" failures |
| Requires a specific Python version or OS library | Image pins the full runtime stack |
| Will be deployed to Kubernetes or a cloud container service | Container is a prerequisite |
| Needs isolated integration testing in CI | Containers provide clean, disposable test environments |

---

## Dockerfile Patterns

### Standard Multi-Stage Build

```dockerfile
# syntax=docker/dockerfile:1

# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

# Install uv for fast, reproducible dependency installation
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy dependency manifests first to leverage layer caching
COPY pyproject.toml uv.lock ./

# Install dependencies into an isolated prefix (no venv activation required)
RUN uv sync --frozen --no-dev --no-install-project

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

# Create a non-root user for security
RUN groupadd --gid 1001 appgroup \
 && useradd --uid 1001 --gid appgroup --no-create-home appuser

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /build/.venv /app/.venv

# Copy application source
COPY src/ ./src/

# Ensure the virtualenv is on PATH
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn", "<package_name>.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### CLI / Batch Application

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder

WORKDIR /build
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

FROM python:3.12-slim AS runtime

RUN groupadd --gid 1001 appgroup \
 && useradd --uid 1001 --gid appgroup --no-create-home appuser

WORKDIR /app
COPY --from=builder /build/.venv /app/.venv
COPY src/ ./src/

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER appuser

ENTRYPOINT ["python", "-m", "<package_name>"]
```

---

## Docker Compose Patterns

### Web Application with Database and Cache

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      target: runtime
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://appuser:${POSTGRES_PASSWORD}@db:5432/appdb
      - REDIS_URL=redis://cache:6379/0
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5

  cache:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Environment Variable File (`.env.example`)

```dotenv
# Copy to .env and fill in values — never commit .env to source control
POSTGRES_PASSWORD=change-me-in-production
SECRET_KEY=change-me-in-production
```

---

## Deployment Workflow

### Local Development

```bash
# Build and start all services
docker compose up --build

# Start in detached mode
docker compose up --build -d

# Stream logs from the app service
docker compose logs -f app

# Run one-off commands inside the app container
docker compose run --rm app python -m pytest

# Stop and remove containers (preserve volumes)
docker compose down

# Stop and remove containers AND volumes (full reset)
docker compose down -v
```

### CI/CD — GitHub Actions

```yaml
# .github/workflows/docker.yml
name: Build and Push Docker Image

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GitHub Container Registry
        if: github.event_name == 'push'
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          target: runtime
          push: ${{ github.event_name == 'push' }}
          tags: ghcr.io/${{ github.repository }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Production Deployment Checklist

Before deploying a container to production, confirm:

- [ ] Image is built from a pinned base image tag (e.g., `python:3.12.3-slim`, not `python:latest`)
- [ ] Application runs as a non-root user
- [ ] No secrets baked into the image — all loaded from environment variables or a secrets manager
- [ ] `.dockerignore` excludes `.git`, `.env`, `__pycache__`, test files, and local logs
- [ ] `HEALTHCHECK` defined and tested
- [ ] `restart: unless-stopped` (or equivalent) configured for long-running services
- [ ] Read-only filesystem used where possible (`--read-only` flag or `read_only: true` in compose)
- [ ] Resource limits (`--memory`, `--cpus`) set to prevent runaway containers
- [ ] Named volumes used for all persistent data — never bind-mount host paths in production
- [ ] Image vulnerability scan run before deploy (see [Maintenance](#maintenance))

---

## `.dockerignore`

```
# Version control
.git
.gitignore

# Python artifacts
__pycache__/
*.py[cod]
*.pyo
.pytest_cache/
.mypy_cache/
.ruff_cache/
htmlcov/
.coverage

# Environment and secrets
.env
*.env

# Virtual environments
.venv/
venv/

# Local development files
*.log
logs/
tmp/

# Documentation build artifacts
docs/_build/
site/
```

---

## Maintenance

### Routine Tasks

| Frequency | Task | Command |
|-----------|------|---------|
| Weekly | Pull updated base images | `docker compose pull` |
| Weekly | Rebuild with latest base | `docker compose up --build -d` |
| On each deploy | Scan image for CVEs | `docker scout cve <image>` or `trivy image <image>` |
| Monthly | Remove unused images and volumes | `docker system prune -f` |
| On dependency update | Rebuild image | `docker compose build --no-cache` |

### Vulnerability Scanning

```bash
# Scan with Docker Scout (requires Docker Desktop or Scout CLI)
docker scout cve ghcr.io/myorg/myapp:latest

# Scan with Trivy (open-source)
trivy image ghcr.io/myorg/myapp:latest

# Run Trivy in CI
trivy image --exit-code 1 --severity HIGH,CRITICAL ghcr.io/myorg/myapp:latest
```

### Updating the Base Image

```bash
# Pull the latest patch for the pinned minor version
docker pull python:3.12-slim

# Rebuild and verify tests pass before pushing
docker compose build --no-cache
docker compose run --rm app python -m pytest
```

### Log Management

```yaml
# Limit log size in docker-compose.yml to prevent disk exhaustion
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
```

---

## Security Hardening Checklist

- [ ] Base image is official and from Docker Hub or a trusted registry
- [ ] Image layers do not contain secrets (`docker history --no-trunc <image>` to verify)
- [ ] Container filesystem is read-only except for explicitly declared writable paths
- [ ] Network policies restrict inter-service communication to required ports only
- [ ] `docker compose` secrets or external secrets manager used for sensitive values
- [ ] Image signing enabled for production registries
- [ ] Automated CVE scanning integrated into CI pipeline

---

## See Also

- [`agents/security-agent.md`](security-agent.md) — security review and hardening
- [`agents/web-dev-agent.md`](web-dev-agent.md) — FastAPI/Flask application patterns
- [`skills/configuration-management.md`](../skills/configuration-management.md) — environment variable management
- [`skills/logging-observability.md`](../skills/logging-observability.md) — structured logging for containerized services
