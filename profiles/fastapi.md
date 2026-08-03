# profiles/fastapi.md: FastAPI Framework Profile

Active profile for repositories using FastAPI as the primary web framework.
Load this file when `RULES.md` declares `Framework: profiles/fastapi.md`.

This profile is normative. It states what agents MUST and MUST NOT do.
[`skills/web-development.md`](../skills/web-development.md) is majority FastAPI
and already carries the implementation patterns for nearly every rule below.
Load it for the how-to; this file does not restate it.

Stacks on top of [`profiles/python.md`](python.md), which remains fully in
force. Where this file is silent, the language profile governs.

FastAPI's failure mode is neither Django's fat views nor Flask's missing
structure. It is the event loop: one synchronous call in an `async def` path
stalls every concurrent request on that worker. Most rules here exist to
prevent that.

---

## Project Layout

**Rule:** Routes MUST be declared on `APIRouter` instances and mounted by an
application factory. A module-level `app = FastAPI()` that routes decorate
directly is prohibited. Business logic MUST live in a service module, not in
path operation functions.

Extends [RULES.md §11](../RULES.md#11-architecture-boundaries) (External Input
-> Validation -> Logic -> I/O -> Output).

### Required structure

```
src/
  myapi/
    main.py            # create_app() factory, router mounting, middleware
    config.py          # Settings(BaseSettings)
    dependencies.py    # shared Depends providers: db session, current user
    api/
      v1/
        <feature>/
          routes.py    # APIRouter: parse, delegate, return
          schemas.py   # pydantic request/response models
          services.py  # business logic, the only layer that writes
          models.py    # SQLAlchemy models
    migrations/        # alembic
tests/
```

### Layer mapping

| RULES.md §11 layer | FastAPI home |
|---|---|
| External Input | `routes.py` path operations |
| Validation | `schemas.py` pydantic models |
| Logic | `services.py` |
| I/O | `models.py`, SQLAlchemy sessions, `httpx` clients |
| Output | `response_model` on the path operation |

### Mandatory practices

- Every router is mounted under an explicit version prefix (`/api/v1`). See
  `skills/web-development.md` API Versioning.
- Shared resources (DB session, HTTP client, cache) are provided through
  `Depends`, never imported as module globals from a route.
- Long-lived clients are created in a `lifespan` context manager and closed on
  shutdown. Never create an `httpx.AsyncClient` per request.
- Services accept and return domain types or pydantic models, never `Request`
  or `Response` objects.

### Prohibited

```python
# NEVER: business logic and I/O inside a path operation
@app.post("/orders")
async def create_order(payload: dict):        # NEVER: untyped dict body
    order = await db.execute(insert(Order)...)  # I/O from the transport layer
    await charge_card(order.total)              # side effect, skips the logic layer
    return {"id": order.id}                     # no response_model
```

```python
# NEVER: a client constructed per request
@router.get("/upstream")
async def fetch():
    async with httpx.AsyncClient() as client:   # new TCP pool every call
        ...
```

### Rationale

The factory plus routers is what makes test-time configuration override
possible and satisfies §17 tier parity. A per-request HTTP client discards
connection pooling and TLS session reuse, which alone can breach the §14 p95
latency target.

---

## Settings and Configuration

**Rule:** Configuration MUST come from environment variables through a single
`pydantic-settings` `BaseSettings` class with no default values for secrets.
The interactive docs (`/docs`, `/redoc`, `/openapi.json`) MUST be disabled or
authenticated in production.

Extends [RULES.md §8](../RULES.md#8-security-and-secrets) and
[RULES.md §17](../RULES.md#17-deployment-and-environment-parity).

The `Settings` pattern in `skills/web-development.md` Environment Configuration
is the reference implementation. Additional requirements:

| Concern | Requirement |
|---|---|
| Instantiation | Once, cached via `functools.lru_cache`, injected with `Depends` |
| Secrets | Required fields with no default, so startup fails when unset |
| CORS origins | From settings, never `["*"]` in production |
| Docs URLs | `docs_url=None, redoc_url=None, openapi_url=None` in production |
| Debug reload | Never enabled outside local development |

```python
@lru_cache
def get_settings() -> Settings:
    """Return the process-wide settings singleton."""
    return Settings()          # raises at first call if a required var is unset
```

### Prohibited

```python
jwt_secret: str = "change-me"              # NEVER: default for a secret
app = FastAPI()                            # NEVER in production: docs exposed
allow_origins=["*"]                        # NEVER with allow_credentials=True
```

`allow_origins=["*"]` combined with `allow_credentials=True` is rejected by
browsers and signals that the origin list was never configured.

### Rationale

OpenAPI docs enumerate every endpoint, parameter, and schema. In production
that is a free reconnaissance map, and it is on by default.

---

## ORM and Data Access

**Rule:** Data access MUST use SQLAlchemy 2.x typed models. In an `async def`
path, every database call MUST use the async engine and session. Blocking calls
MUST NOT appear in `async def` functions.

Extends [RULES.md §11](../RULES.md#11-architecture-boundaries) and
[RULES.md §14](../RULES.md#14-performance-standards).

### The async boundary

| Path operation | Permitted work |
|---|---|
| `async def` | `await`-ed I/O only: async DB session, `httpx.AsyncClient`, async cache |
| `def` | Blocking work. FastAPI runs it in a threadpool automatically |

When a dependency or library is blocking and has no async equivalent, either
declare the path operation `def`, or wrap the call in
`anyio.to_thread.run_sync`. Never call it directly from `async def`.

### Mandatory practices

- Use `DeclarativeBase` with `Mapped[...]` / `mapped_column`, per
  `skills/web-development.md` Database Patterns.
- Sessions are yielded by a `Depends` provider that closes them on both success
  and failure.
- Commit in the service layer only. Path operations never call `commit()`.
- Eager-load relations with `selectinload` in any path that iterates a
  collection and touches a relation.
- Paginate every list endpoint. No endpoint returns an unbounded result set.
- Bound every outbound `httpx` call with an explicit `timeout`.

### Prohibited

```python
# NEVER: blocking call inside async def, stalls the whole event loop
@router.get("/report")
async def report():
    time.sleep(2)                       # blocks every concurrent request
    rows = requests.get(url).json()     # blocking HTTP client
    df = pd.read_sql(query, sync_engine)  # blocking driver
```

```python
# NEVER: string-interpolated SQL
await session.execute(text(f"SELECT * FROM users WHERE email = '{email}'"))
```

```python
# NEVER: an unbounded outbound call
await client.get(url)                   # no timeout: hangs a worker indefinitely
```

### Rationale

FastAPI gives no warning when a blocking call enters an `async def`. The
symptom is a latency collapse under concurrency that does not reproduce in
single-request testing, which is precisely the regression §14 requires agents
to prevent rather than discover in production.

---

## Migrations

**Rule:** Schema changes MUST be managed by `alembic`, with the same
requirements that apply to Flask projects. Autogenerated revisions MUST be read
and corrected before commit and MUST ship in the same commit as the model
change.

Extends [RULES.md §6](../RULES.md#6-version-control-and-commits) and
[RULES.md §17](../RULES.md#17-deployment-and-environment-parity).

Commands, the autogenerate review checklist, and the three-release
expand/backfill/contract protocol for destructive changes are defined in
[`profiles/flask.md`](flask.md) Migrations. They apply here unchanged.

### FastAPI-specific additions

- Alembic's `env.py` runs synchronously. With an async engine, configure it via
  `connection.run_sync` rather than converting the application engine.
- Keep the migration URL and the application URL derived from the same
  `DATABASE_URL`, adjusting only the driver, so the two cannot drift.
- Migrations run as a release step, never from an application container's
  entrypoint.

### Rationale

A FastAPI service typically holds an async driver (`asyncpg`) that Alembic
cannot use directly. Left unaddressed, teams hardcode a second connection
string, and the migrated database stops being the served database.

---

## Request Handling

**Rule:** Every path operation MUST declare a typed request model, a
`response_model`, and an explicit `status_code`. Domain exceptions MUST be
mapped to status codes by registered exception handlers, not by per-route
`try`/`except`. Bare `except` is prohibited.

Extends [RULES.md §9](../RULES.md#9-error-handling) and
[RULES.md §8](../RULES.md#8-security-and-secrets).

### Mandatory practices

- Request bodies are pydantic models with field constraints. Never `dict`,
  never `Request.json()` read directly.
- `response_model` is declared on every route so that internal fields cannot
  leak into a response. Never return an ORM object without one.
- Auth is enforced through a `Depends` security dependency applied at the
  router level, not repeated per route.
- Register handlers for domain exceptions once, per
  `skills/web-development.md` Exception handling.
- Rate-limit all unauthenticated endpoints (`slowapi`).
- `BackgroundTasks` is for short, best-effort work only. Anything that must not
  be lost goes to a durable queue (`celery` or `arq`) in a separate process.
- Expose `/health` and `/ready` per `skills/web-development.md` Health Check
  Convention, excluded from auth.

### Prohibited

```python
@router.post("/items")                    # NEVER: no response_model, no status_code
async def create(request: Request):
    body = await request.json()           # NEVER: bypasses validation
    try:
        return await service.create(body)
    except Exception as exc:              # NEVER: bare catch (RULES.md §9)
        raise HTTPException(500, detail=str(exc))   # NEVER: leaks internals
```

Return a generic message plus a correlation ID; log the exception with that ID.

### Logging

Follow `profiles/python.md` Logging and Observability. Additionally:

- Configure logging inside the factory, before `uvicorn` starts. Uvicorn's
  default log config is a fallback, not a configuration.
- Never log request bodies, headers, or cookies wholesale (§16).
- Attach a correlation ID in middleware and include it in every record.
- Never log inside a hot `async` path with a blocking handler. File and network
  log handlers block the event loop.

### Rationale

Without `response_model`, FastAPI serializes whatever the function returns,
which turns "return the ORM object" into a data leak of every column including
password hashes and internal flags.

---

## Testing

**Rule:** Tests MUST build the application through the factory with a test
settings object. The coverage target in
[RULES.md §7](../RULES.md#7-testing-and-coverage) applies unchanged. Every route
MUST have a test for its success path, its validation-failure path (422), and
its authorization-failure path (401 or 403).

### Mandatory practices

| Requirement | Detail |
|---|---|
| Runner | `uv run python3 -m pytest` |
| Async tests | `pytest-asyncio` |
| Sync client | `TestClient`, per `skills/web-development.md` Testing |
| Async client | `httpx.AsyncClient` with `ASGITransport` for async paths |
| Dependency overrides | `app.dependency_overrides`, cleared in fixture teardown |
| Database | A transaction rolled back per test, or a per-test schema |
| External I/O | Mocked per `profiles/python.md` Testing and Coverage |

```bash
uv run python3 -m pytest --cov=src --cov-fail-under=100
```

### Prohibited

- Do NOT import a module-level `app` in tests. If a test can, the factory rule
  was violated.
- Do NOT leave `dependency_overrides` set after a test. Leaked overrides make
  later tests pass for the wrong reason.
- Do NOT test only through `TestClient` when routes are `async def`.
  `TestClient` runs the app in its own loop and can hide the concurrency
  failures the async boundary rules exist to catch.
- Do NOT assert on OpenAPI schema text. Assert on status codes and parsed
  payloads.

### Rationale

Dependency overrides are the entire test seam of a FastAPI application. An
override that outlives its test silently detaches the suite from the code it
claims to cover.

---

## Deployment

**Rule:** FastAPI MUST be served by `uvicorn` workers under `gunicorn`, or by
`uvicorn` with an explicit worker count, behind a reverse proxy. `--reload` MUST
never be enabled outside local development.

Extends [RULES.md §17](../RULES.md#17-deployment-and-environment-parity) and
[`skills/containerization.md`](../skills/containerization.md).

### Process model

```bash
uv run gunicorn "myapi.main:create_app()" \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 --workers 4 --timeout 60
```

- Worker count sized to the container CPU limit, not the host CPU count.
- Set `--timeout` explicitly and above the slowest legitimate request.
- Startup and shutdown work belongs in the `lifespan` handler so that clients
  and pools close cleanly on SIGTERM.
- Durable background work runs in `celery` or `arq` workers as a separate
  process and container.
- `alembic upgrade head` runs as a release step that completes before new
  containers accept traffic.

### Required production configuration

| Setting | Required value |
|---|---|
| `docs_url` / `redoc_url` / `openapi_url` | `None`, or auth-gated |
| `--reload` | Never set |
| CORS `allow_origins` | Explicit list from settings |
| Proxy headers | `--proxy-headers` with `--forwarded-allow-ips` restricted |
| Root path | `root_path` set when mounted under a proxy prefix |

### Prohibited

```bash
uvicorn myapi.main:app --reload            # NEVER in any deployed environment
uvicorn myapi.main:app                     # NEVER: single worker, no proxy headers
```

### Rationale

`--reload` runs a file watcher and a supervisor process, holds extra file
descriptors, and restarts the application on any filesystem event. In a
container with a mounted volume it produces restart loops that read as
intermittent 502s.

---

## See Also

- [`profiles/python.md`](python.md): language rules that remain in force
- [`profiles/django.md`](django.md), [`profiles/flask.md`](flask.md): parallel web profiles
- [`skills/web-development.md`](../skills/web-development.md): implementation patterns
- [`skills/api-integration.md`](../skills/api-integration.md): outbound HTTP, retry, pagination
- [`skills/approved-packages.md`](../skills/approved-packages.md): authorized libraries (§5)
- [`skills/containerization.md`](../skills/containerization.md): image and deployment patterns
