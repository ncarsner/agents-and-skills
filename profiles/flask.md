# profiles/flask.md: Flask Framework Profile

Active profile for repositories using Flask as the primary web framework.
Load this file when `RULES.md` declares `Framework: profiles/flask.md`.

This profile is normative. It states what agents MUST and MUST NOT do. For
implementation patterns and copyable code, load
[`skills/web-development.md`](../skills/web-development.md); do not restate
its recipes here.

Stacks on top of [`profiles/python.md`](python.md), which remains fully in
force. Where this file is silent, the language profile governs.

Flask ships almost nothing by default, so this profile is stricter than
[`profiles/django.md`](django.md) about structure. Django's conventions are
enforced by the framework; Flask's must be enforced by the agent.

---

## Project Layout

**Rule:** Every Flask application MUST be created by an application factory and
MUST register routes through blueprints. A module-level `app = Flask(__name__)`
is prohibited. Business logic MUST live in a service module, not in view
functions.

Extends [RULES.md §11](../RULES.md#11-architecture-boundaries) (External Input
-> Validation -> Logic -> I/O -> Output).

### Required structure

```
src/
  myapp/
    __init__.py        # create_app() factory only
    config.py          # Settings class, env-driven
    extensions.py      # db = SQLAlchemy(), migrate = Migrate(), ... uninitialized
    api/
      <feature>/
        routes.py      # blueprint: parse request, call service, return
        schemas.py     # validation layer (pydantic or marshmallow)
        services.py    # business logic, the only layer that writes
        models.py      # I/O layer: SQLAlchemy models
    migrations/        # alembic
tests/
```

### Layer mapping

| RULES.md §11 layer | Flask home |
|---|---|
| External Input | `routes.py`, CLI commands |
| Validation | `schemas.py` |
| Logic | `services.py` |
| I/O | `models.py`, SQLAlchemy sessions, external clients |
| Output | `schemas.py` dump, `jsonify` |

### Mandatory practices

- Extensions are instantiated unbound in `extensions.py` and bound inside
  `create_app` via `init_app(app)`.
- `create_app` accepts a config object or mapping so tests can override it.
- Every blueprint is registered with an explicit `url_prefix`.
- Application state lives on `app.config` or `app.extensions`, never in module
  globals.

### Prohibited

```python
# NEVER: module-level app, unconfigurable and untestable
app = Flask(__name__)

@app.route("/orders", methods=["POST"])
def create_order():
    order = Order(**request.json)     # NEVER: unvalidated, and I/O from transport
    db.session.add(order)
    db.session.commit()
    charge_card(order.total)          # NEVER: side effect skips the logic layer
    return jsonify(id=order.id)
```

```python
# NEVER: mutable module globals as request state
_current_tenant = None                # not request-scoped, unsafe under threads
```

Use `flask.g` for request-scoped state and `current_app` to reach configuration.

### Rationale

A module-level app binds configuration at import time, which makes isolated
test configuration impossible and forces test-only branches into production
code. The factory is the only structure that satisfies §17 tier parity.

---

## Settings and Configuration

**Rule:** Configuration MUST come from environment variables through a single
validated settings object. `SECRET_KEY` MUST never appear as a literal in a
tracked file, and `DEBUG` MUST default to `False`.

Extends [RULES.md §8](../RULES.md#8-security-and-secrets) and
[RULES.md §17](../RULES.md#17-deployment-and-environment-parity).

### Mandatory practices

| Concern | Requirement |
|---|---|
| Settings source | `pydantic-settings` `BaseSettings` (see `skills/web-development.md`) |
| Selection | `APP_ENV` env var, one settings class per tier |
| Secrets | Required fields with no default, so startup fails when unset |
| Database | `DATABASE_URL` env var |
| Session cookies | `SESSION_COOKIE_SECURE=True`, `SESSION_COOKIE_HTTPONLY=True`, `SESSION_COOKIE_SAMESITE="Lax"` |

```python
def create_app(config: Settings | None = None) -> Flask:
    """Create and configure a Flask app instance."""
    app = Flask(__name__)
    app.config.from_object(config or Settings())     # validated at construction
    ...
```

### Prohibited

```python
app.config["SECRET_KEY"] = "dev"                     # NEVER: literal secret
app.config.from_pyfile("secrets.cfg")                # NEVER: secrets in a tracked file
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev")  # NEVER: silent fallback
```

Flask's own tutorial uses `SECRET_KEY="dev"`. That is a documentation
convenience, not a permitted pattern here. A missing secret MUST crash at
startup.

### Rationale

Flask signs session cookies with `SECRET_KEY`. A leaked or defaulted key lets
any client forge a session, so §8 applies to it with no exceptions.

---

## ORM and Data Access

**Rule:** Data access MUST use SQLAlchemy 2.x typed models with parameterized
queries. Raw SQL MUST use bound parameters. Sessions MUST be closed or rolled
back on every request path, including error paths.

Extends [RULES.md §11](../RULES.md#11-architecture-boundaries) and
[RULES.md §14](../RULES.md#14-performance-standards).

### Mandatory practices

- Use `DeclarativeBase` with `Mapped[...]` / `mapped_column`, not the legacy
  `Column` style, so `mypy` can check the models.
- Use `select()` statements, not the legacy `Model.query` interface.
- Eager-load relations with `selectinload` or `joinedload` in any code path
  that iterates a collection and touches a relation.
- Commit in the service layer only. View functions never call
  `session.commit()`.
- Register a teardown that removes the session for both success and failure.
- Paginate every list endpoint. No endpoint returns an unbounded result set.

### Prohibited

```python
# NEVER: string-interpolated SQL
db.session.execute(text(f"SELECT * FROM users WHERE email = '{email}'"))

# Correct
db.session.execute(
    text("SELECT * FROM users WHERE email = :email"), {"email": email}
)
```

```python
# NEVER: N+1 across a relation
for order in db.session.scalars(select(Order)):
    print(order.customer.name)          # one query per order

# Correct
stmt = select(Order).options(selectinload(Order.customer))
```

```python
# NEVER: commit from a view function
@bp.post("/")
def create_item():
    db.session.add(item)
    db.session.commit()                 # transaction boundary belongs in services
```

### Rationale

Flask gives no session lifecycle by default. A session left open after an
exception holds a connection and can leak an uncommitted transaction into the
next request served by that worker.

---

## Migrations

**Rule:** Schema changes MUST be managed by `alembic`. Auto-generated
migrations MUST be read and corrected before commit, and MUST ship in the same
commit as the model change. `alembic` MUST never run against a database it did
not create without a reviewed baseline revision.

Extends [RULES.md §6](../RULES.md#6-version-control-and-commits) and
[RULES.md §17](../RULES.md#17-deployment-and-environment-parity).

### Mandatory commands

| Action | Command |
|---|---|
| Generate a revision | `uv run alembic revision --autogenerate -m "<summary>"` |
| Inspect pending SQL | `uv run alembic upgrade head --sql` |
| Apply migrations | `uv run alembic upgrade head` |
| Roll back one revision | `uv run alembic downgrade -1` |
| Show current revision | `uv run alembic current` |

### Autogenerate review checklist

`--autogenerate` is a draft, not an artifact. Before committing, confirm:

- No unintended `drop_table` or `drop_column`.
- Server defaults and nullability match the model.
- Index and unique-constraint names are explicit, not database-generated.
- Type changes that require a rewrite are acceptable at production table size.
- `downgrade()` is implemented, or documents in-file why it cannot be.

### Destructive change protocol

Dropping or renaming a column requires three releases, identical to the
protocol in [`profiles/django.md`](django.md) Migrations: expand, backfill,
contract.

### Prohibited

- Do NOT edit a revision that has been applied in any shared environment.
- Do NOT commit an autogenerated revision without reading it.
- Do NOT create multiple heads. Merge before pushing.
- Do NOT reference application models inside a migration. Use
  `sa.table()` / `sa.column()` lightweight constructs for data migrations.

### Rationale

Alembic autogenerate compares metadata to the live schema and cannot infer
intent. A rename reads as a drop plus an add, which silently destroys data.

---

## Request Handling

**Rule:** Every route MUST validate its input against a schema before use, MUST
declare its HTTP methods explicitly, and MUST NOT catch bare exceptions. Every
application MUST register error handlers that return JSON for API blueprints.

Extends [RULES.md §9](../RULES.md#9-error-handling) and
[RULES.md §8](../RULES.md#8-security-and-secrets).

### Mandatory practices

- Parse bodies with `request.get_json()` then validate through a schema. Never
  index into the raw payload.
- Register handlers for 400, 401, 403, 404, 422, and 500 that return JSON, not
  Flask's default HTML error pages.
- Define domain exception classes and map them to status codes in a single
  `@app.errorhandler` registration, not in each view.
- Enable CSRF protection on any session-authenticated HTML form, using the
  library authorized in [`skills/approved-packages.md`](../skills/approved-packages.md)
  (`wtforms` CSRF at time of writing). Any other CSRF library requires §5
  authorization first. Token-authenticated JSON APIs are exempt and MUST
  document that exemption in the blueprint module.
- Set CORS allowed origins from configuration. Never `*` in production.
- Rate-limit all unauthenticated endpoints.
- Expose `/health` and `/ready` per `skills/web-development.md` Health Check
  Convention, excluded from auth.

### Prohibited

```python
@bp.route("/items")                     # NEVER: implicitly GET-only and unclear
def items():
    data = request.get_json()
    name = data["name"]                 # NEVER: unvalidated, KeyError becomes a 500
    try:
        return jsonify(service.create(name))
    except Exception:                   # NEVER: bare catch (RULES.md §9)
        return "error", 500             # NEVER: bare string response
```

```python
@app.errorhandler(Exception)
def handle_all(exc):
    return jsonify(detail=str(exc)), 500   # NEVER: leaks internals to the client
```

Log the exception with a correlation ID; return a generic message and that ID
to the client.

### Logging

Follow `profiles/python.md` Logging and Observability. Additionally:

- Configure logging inside `create_app`, before any handler is registered.
  Flask's default logger is a fallback, not a configuration.
- Never log `request.get_data()`, headers, or cookies wholesale (§16).
- Attach a correlation ID in `before_request` and include it in every record.

### Rationale

Flask returns HTML error pages by default, which breaks API clients, and
propagates the exception message when the default handler is overridden
carelessly. Neither default is acceptable under §9.

---

## Testing

**Rule:** Tests MUST build the application through `create_app` with a test
configuration. The coverage target in
[RULES.md §7](../RULES.md#7-testing-and-coverage) applies unchanged. Every route
MUST have a test for its success path, its validation-failure path, and its
authorization-failure path.

### Mandatory practices

| Requirement | Detail |
|---|---|
| Runner | `uv run python3 -m pytest` |
| App fixture | Calls `create_app(TestSettings())`, function or module scoped |
| Client | `app.test_client()` from that fixture |
| Database | A transaction rolled back per test, or a per-test schema |
| External I/O | Mocked per `profiles/python.md` Testing and Coverage |
| Migrations | A test asserting `alembic upgrade head` succeeds from empty |

```bash
uv run python3 -m pytest --cov=src --cov-fail-under=100
```

### Prohibited

- Do NOT import a module-level `app` in tests. If a test can, the factory rule
  was violated.
- Do NOT share a database session across tests. Cross-test state produces
  order-dependent failures.
- Do NOT test through a real network, mail backend, or cache server.
- Do NOT assert on rendered HTML strings. Assert on status codes and parsed
  JSON payloads.

### Rationale

The factory exists so that each test gets an independently configured
application. Reusing one app instance reintroduces the global state the factory
was adopted to eliminate.

---

## Deployment

**Rule:** Flask MUST be served by `gunicorn` behind a reverse proxy, never by
`flask run` or `app.run()`. The application factory MUST be referenced by
import path, and migrations MUST run as a separate release step.

Extends [RULES.md §17](../RULES.md#17-deployment-and-environment-parity) and
[`skills/containerization.md`](../skills/containerization.md).

### Process model

```bash
uv run gunicorn "myapp:create_app()" --bind 0.0.0.0:8000 --workers 4
```

- Worker count sized to the container CPU limit, not the host CPU count.
- Set `--timeout` explicitly. The 30 second default silently kills slow
  requests without a log line from the application.
- Background work runs in `celery` or `arq` workers as a separate process and
  container. Never in a request thread or a `threading.Thread`.
- `alembic upgrade head` runs as a release step that completes before new
  containers accept traffic, never from a serving container's entrypoint.
- Static assets are served by the proxy or a CDN, never by Flask.

### Required production configuration

| Setting | Required value |
|---|---|
| `DEBUG` | `False` |
| `TESTING` | `False` |
| `SESSION_COOKIE_SECURE` | `True` |
| `SESSION_COOKIE_HTTPONLY` | `True` |
| `SESSION_COOKIE_SAMESITE` | `"Lax"` or `"Strict"` |
| `PREFERRED_URL_SCHEME` | `"https"` |
| `ProxyFix` middleware | Applied when behind a TLS-terminating proxy |

### Prohibited

```python
if __name__ == "__main__":
    app.run(debug=True)                  # NEVER in any deployed environment
```

```bash
flask run --host 0.0.0.0                 # NEVER in any deployed environment
```

The Werkzeug development server is single-worker by default and, with `debug`
enabled, exposes an interactive debugger console that executes arbitrary code.

### Rationale

Flask's development server is documented as unsuitable for production. Its
debugger console is a remote code execution path, which makes an accidental
production `debug=True` a §8 incident rather than a performance problem.

---

## See Also

- [`profiles/python.md`](python.md): language rules that remain in force
- [`profiles/django.md`](django.md): parallel profile for Django projects
- [`skills/web-development.md`](../skills/web-development.md): implementation patterns
- [`skills/approved-packages.md`](../skills/approved-packages.md): authorized libraries (§5)
- [`skills/database-access.md`](../skills/database-access.md): query patterns
- [`skills/containerization.md`](../skills/containerization.md): image and deployment patterns
