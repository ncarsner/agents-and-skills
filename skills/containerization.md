# Skill: Containerization & Docker

Conventions for containerizing Python projects with Docker. Covers base image
selection, multi-stage builds, non-root user setup, .dockerignore, image scanning,
and local development with Docker Compose.

---

## Required Base Image

| Use case | Image |
|----------|-------|
| Standard Python service | `python:3.12-slim` |
| ARM / cross-platform | `python:3.12-slim-bookworm` |
| Minimal (expert use only) | `python:3.12-alpine` |

Never use `python:latest`: pin the minor version to prevent unexpected upgrades.

---

## Mandatory Multi-Stage Build

All Dockerfiles must use multi-stage builds to keep the runtime image small.

```dockerfile
# ---- Build stage ----
FROM python:3.12-slim AS builder

WORKDIR /app

RUN pip install --no-cache-dir uv

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-editable

# ---- Runtime stage ----
FROM python:3.12-slim AS runtime

# Create a non-root user with a fixed UID/GID.
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid appuser --shell /bin/bash --create-home appuser

WORKDIR /app

COPY --from=builder --chown=appuser:appuser /app/.venv /app/.venv
COPY --chown=appuser:appuser src/ ./src/

USER appuser

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

CMD ["python3", "-m", "uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

See `templates/Dockerfile` for the ready-to-copy template.

---

## Non-Root User Rules

- Always create a dedicated `appuser` with fixed UID 1001 / GID 1001.
- Use `COPY --chown=appuser:appuser` on every `COPY` in the runtime stage.
- Run `RUN` build steps as root; switch to `USER appuser` before `CMD`.
- Never grant `sudo` or elevated capabilities to the app user.

---

## .dockerignore

Every project with a Dockerfile must include a `.dockerignore`. See
`templates/.dockerignore` for the canonical list. Required minimum:

```
.git
.venv
__pycache__
*.pyc
.env
.env.*
!.env-template
.secrets.baseline
*.egg-info
dist/
build/
htmlcov/
.pytest_cache/
.mypy_cache/
.ruff_cache/
```

---

## Container Image Scanning

Scan every image with `trivy` before pushing to any registry:

```bash
trivy image --exit-code 1 --severity HIGH,CRITICAL <image>:<tag>
```

| Severity | Policy |
|----------|--------|
| CRITICAL | Block, must be resolved before the image is pushed |
| HIGH | Block if a fix is available; document if not |
| MEDIUM | Advisory; track and review within 30 days |
| LOW | Advisory only |

In CI, the trivy scan step must run after build and before push.

---

## Docker Compose (Local Development)

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      target: runtime
    ports:
      - "8000:8000"
    env_file:
      - .env
    volumes:
      - ./src:/app/src:ro
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

Rules:
- Never commit credentials in `docker-compose.yml`: use `env_file: .env`.
- `.env` must be in `.gitignore`.
- Use named volumes for persistent data; never bind-mount a database directory.

---

## See Also

- `templates/Dockerfile`: ready-to-copy multi-stage Dockerfile
- `templates/.dockerignore`: canonical .dockerignore
- `skills/secret-scanning.md`: ensure no secrets land in the image layer
- `RULES.md §17`: deployment and environment parity rules
