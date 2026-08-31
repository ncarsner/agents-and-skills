# profiles/django.md: Django Framework Profile

Active profile for repositories using Django as the primary web framework.
Load this file when `RULES.md` declares `Framework: profiles/django.md`.

This profile is normative. It states what agents MUST and MUST NOT do. For
implementation patterns and copyable code, load
[`skills/web-development.md`](../skills/web-development.md); do not restate
its recipes here.

Stacks on top of [`profiles/python.md`](python.md), which remains fully in
force. Where this file is silent, the language profile governs.

---

## Project Layout

**Rule:** Every Django project MUST separate the project package (settings,
root URLconf, ASGI/WSGI entry points) from feature apps. Business logic MUST
live in a service layer, not in views or model methods.

Extends [RULES.md §11](../RULES.md#11-architecture-boundaries-core) (External Input
-> Validation -> Logic -> I/O -> Output).

### Required structure

```
src/
  config/              # project package: settings, urls, asgi, wsgi
    settings/
      base.py
      dev.py
      prod.py
  apps/
    <feature>/
      models.py        # I/O layer: schema only
      selectors.py     # read queries
      services.py      # business logic, the only layer that writes
      serializers.py   # validation layer (DRF) or forms.py
      views.py         # transport layer: parse request, call service, return
      urls.py
      migrations/
  manage.py
tests/
```

### Layer mapping

| RULES.md §11 layer | Django home |
|---|---|
| External Input | `views.py`, management commands |
| Validation | `serializers.py`, `forms.py` |
| Logic | `services.py`, `selectors.py` |
| I/O | `models.py`, ORM querysets, cache, external clients |
| Output | `serializers.py`, template rendering, `JsonResponse` |

### Prohibited

```python
# NEVER: business logic inside a view
def create_order(request):
    order = Order.objects.create(...)      # I/O from the transport layer
    send_invoice_email(order)              # side effect from the transport layer
    charge_card(order.total)               # skips the logic layer entirely

# NEVER: cross-app model imports that bypass the owning app's services
from apps.billing.models import Invoice
Invoice.objects.filter(...).update(status="paid")
```

Views call services. Services own writes and side effects. Apps talk to other
apps through service functions, never through another app's models.

### Rationale

Django's defaults invite fat views and fat models, which makes the §11 boundary
unenforceable and leaves business rules untestable without HTTP or a database.

---

## Settings and Configuration

**Rule:** Settings MUST be split by environment and MUST read every secret and
environment-specific value from environment variables. `DEBUG = True` MUST
never be committed in a production settings module, and `SECRET_KEY` MUST never
appear as a literal in any tracked file.

Extends [RULES.md §8](../RULES.md#8-security-and-secrets-core) and
[RULES.md §17](../RULES.md#17-deployment-and-environment-parity-profileservice).

### Mandatory practices

| Concern | Requirement |
|---|---|
| Settings module | `config/settings/base.py` plus one module per tier |
| Selection | `DJANGO_SETTINGS_MODULE` env var, no runtime branching on hostname |
| Secrets | `os.environ["..."]` or `pydantic-settings`, never a default value |
| `ALLOWED_HOSTS` | Explicit list from env, never `["*"]` in production |
| `DEBUG` | Env-derived, defaults to `False` |
| Database | `DATABASE_URL` env var |

```python
# config/settings/prod.py
import os

from .base import *  # noqa: F403

DEBUG = False
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]          # fail loudly if unset
ALLOWED_HOSTS = os.environ["DJANGO_ALLOWED_HOSTS"].split(",")
```

### Prohibited

```python
SECRET_KEY = "django-insecure-8f3k..."     # NEVER: literal secret
SECRET_KEY = os.getenv("SECRET_KEY", "dev-fallback")  # NEVER: silent fallback
DEBUG = True                               # NEVER in a production module
ALLOWED_HOSTS = ["*"]                      # NEVER in a production module
```

A missing secret MUST crash at startup. A fallback default turns a
misconfigured deployment into a silently insecure one.

### Rationale

Tier parity (§17) requires that only environment variables differ between
environments. Branching inside a single settings file makes the deployed
configuration impossible to audit.

---

## ORM and Data Access

**Rule:** All queries MUST be written through the ORM or through parameterized
raw SQL. Every queryset that crosses a relation in a loop MUST use
`select_related` or `prefetch_related`. Read queries belong in `selectors.py`;
writes belong in `services.py`.

Extends [RULES.md §11](../RULES.md#11-architecture-boundaries-core) and
[RULES.md §14](../RULES.md#14-performance-standards-langpython-configurable).

### Mandatory practices

- Annotate every model field and every selector/service signature per
  `profiles/python.md` Code Quality.
- Wrap multi-write operations in `transaction.atomic()`.
- Use `select_for_update()` when a read informs a conditional write.
- Use `.only()` / `.defer()` on wide tables in hot paths.
- Use `bulk_create` / `bulk_update` for batch writes over 100 rows.
- Set `related_name` explicitly on every `ForeignKey` and `ManyToManyField`.

### Prohibited

```python
# NEVER: string-interpolated SQL
User.objects.raw(f"SELECT * FROM users WHERE email = '{email}'")

# NEVER: N+1 query pattern
for order in Order.objects.all():
    print(order.customer.name)          # one query per order

# Correct
for order in Order.objects.select_related("customer"):
    print(order.customer.name)
```

```python
# NEVER: unbounded queryset in a request path
Order.objects.all()                     # paginate or filter

# NEVER: signals for business logic
@receiver(post_save, sender=Order)
def on_order_saved(...): ...            # hidden side effects, untestable ordering
```

Signals are permitted only for cache invalidation and audit logging, never for
domain workflows.

### Rationale

The ORM's laziness makes N+1 queries invisible in code review and fatal under
load. Parameterization is the only reliable defense against SQL injection
(§8). Signals move causality out of the call graph, which breaks §11's explicit
layer flow.

---

## Migrations

**Rule:** Every model change MUST ship with its generated migration in the same
commit. Migrations MUST be reviewed before commit, MUST NOT be edited after
merge, and destructive operations MUST be split across releases.

Extends [RULES.md §6](../RULES.md#6-version-control-and-commits-core) and
[RULES.md §17](../RULES.md#17-deployment-and-environment-parity-profileservice).

### Mandatory commands

| Action | Command |
|---|---|
| Generate migrations | `uv run python3 manage.py makemigrations` |
| Inspect generated SQL | `uv run python3 manage.py sqlmigrate <app> <n>` |
| Apply migrations | `uv run python3 manage.py migrate` |
| Verify none are missing | `uv run python3 manage.py makemigrations --check --dry-run` |
| Roll back locally | `uv run python3 manage.py migrate <app> <previous_n>` |

`makemigrations --check --dry-run` MUST run in CI and MUST fail the build when
a model change has no matching migration.

### Destructive change protocol

Dropping or renaming a column requires three releases:

1. Release 1: add the new column, write to both, read from the old.
2. Release 2: backfill via a data migration, switch reads to the new column.
3. Release 3: stop writing the old column, then drop it.

A data migration MUST define both `forwards` and `reverse` callables. Use
`migrations.RunPython.noop` for `reverse` only when the operation is genuinely
irreversible, and document why in the same file.

### Prohibited

```python
# NEVER: editing a migration that has already been applied in any shared environment
# NEVER: --fake to skip a migration that failed
# NEVER: a data migration that imports the app's models directly
from apps.orders.models import Order       # wrong: uses current code, not historical schema

def backfill(apps, schema_editor):
    Order = apps.get_model("orders", "Order")   # correct: historical model
```

### Rationale

A migration is a deployed artifact. Editing one after merge desynchronizes
environments that already applied the original. Importing live models into a
data migration breaks the moment the model changes again.

---

## Request Handling

**Rule:** Every view MUST validate input through a serializer or form before
using it, MUST return a defined error response for every failure path, and MUST
NOT catch bare exceptions. CSRF protection and authentication MUST NOT be
disabled on a per-view basis without a documented reason in the same file.

Extends [RULES.md §9](../RULES.md#9-error-handling-langpython) and
[RULES.md §8](../RULES.md#8-security-and-secrets-core).

### Mandatory practices

- Use DRF serializers (`djangorestframework`) for JSON APIs, Django forms for
  HTML views. Never read `request.data` fields directly.
- Register a project-level DRF exception handler; map domain exceptions to
  status codes there rather than in each view.
- Return DRF `Response` or `JsonResponse`; never return raw strings.
- Rate-limit authenticated write endpoints and all unauthenticated endpoints.
- Exclude `/health` and `/ready` from auth middleware
  (see `skills/web-development.md` Health Check Convention).

### Prohibited

```python
@csrf_exempt                    # NEVER without a documented reason
@permission_classes([AllowAny]) # NEVER on a write endpoint by default
def update_profile(request):
    name = request.data["name"]     # NEVER: unvalidated access, raises KeyError as a 500
    try:
        service.update(name)
    except Exception:               # NEVER: bare catch (RULES.md §9)
        return Response(status=500)
```

### Logging

Follow `profiles/python.md` Logging and Observability. Additionally:

- Never log `request.body`, `request.POST`, headers, or cookies wholesale;
  they carry credentials and PII (§16).
- Log the authenticated user ID, never the email or name.
- Attach a correlation ID via middleware and include it in every log record.

### Rationale

Django returns a 500 for any uncaught exception, which converts a validation
gap into an availability incident and can leak a stack trace when `DEBUG` is
misconfigured.

---

## Testing

**Rule:** Django projects MUST use `pytest` as the test runner, not
`manage.py test`. The Django pytest integration plugin is not currently listed
in [`skills/approved-packages.md`](../skills/approved-packages.md); adding it
requires the §5 authorization and cooling-period process before it is used.
The coverage target in
[RULES.md §7](../RULES.md#7-testing-and-coverage-langpython-configurable) applies unchanged. Every view
MUST have a test for its success path, its validation-failure path, and its
authorization-failure path.

### Mandatory practices

| Requirement | Detail |
|---|---|
| Runner | `uv run pytest` |
| DB access | Opt in per test, never enabled globally for the suite |
| Fixtures | `pytest` fixtures and factory functions |
| Query counts | Assert an exact query count on every list endpoint |
| External I/O | Mocked per `profiles/python.md` Testing and Coverage |
| Settings | A dedicated `config.settings.test` module |

Query-count assertions use `django.test.TestCase.assertNumQueries` (stdlib
Django, no extra dependency) unless the pytest integration plugin has been
authorized under §5.

```bash
uv run pytest --cov=src --cov-fail-under=100
uv run python3 manage.py makemigrations --check --dry-run
```

### Prohibited

- Do NOT use `--reuse-db` in CI. Local development only.
- Do NOT load JSON fixture files; they drift silently from the schema.
- Do NOT hit the network, the real cache, or a real mail backend. Use
  `locmem` for email and `DummyCache` or a fake for the cache.
- Do NOT assert on rendered HTML strings. Assert on status codes, context
  variables, and serialized payloads.

### Rationale

An asserted query count is the only cheap, automated defense against the
N+1 regressions the ORM makes easy. Fixture files encode a schema snapshot that
no migration updates.

---

## Deployment

**Rule:** Django MUST be served by `gunicorn` behind a reverse proxy, never by
`manage.py runserver`. `manage.py check --deploy` MUST pass with zero warnings
before any production release.

Extends [RULES.md §17](../RULES.md#17-deployment-and-environment-parity-profileservice) and
[`skills/containerization.md`](../skills/containerization.md).

### Mandatory pre-release gate

```bash
uv run python3 manage.py check --deploy          # zero warnings required
uv run python3 manage.py makemigrations --check --dry-run
uv run python3 manage.py collectstatic --no-input
```

### Required production settings

| Setting | Required value |
|---|---|
| `DEBUG` | `False` |
| `SECURE_SSL_REDIRECT` | `True` |
| `SESSION_COOKIE_SECURE` | `True` |
| `CSRF_COOKIE_SECURE` | `True` |
| `SECURE_HSTS_SECONDS` | `31536000` |
| `SECURE_PROXY_SSL_HEADER` | Set when behind a TLS-terminating proxy |
| `X_FRAME_OPTIONS` | `DENY` |

### Process model

- Web: `gunicorn config.wsgi:application` with a worker count sized to the
  container CPU limit.
- Async workloads: `celery` workers as a separate process and separate
  container. Never run background work in a request thread.
- Migrations: a separate release step that completes before new application
  containers accept traffic. Never run `migrate` from a container entrypoint
  that also serves requests.
- Static files: `collectstatic` at image build time, served by the proxy or a
  CDN, never by Django in production.

### Prohibited

```bash
uv run python manage.py runserver 0.0.0.0:8000     # NEVER in any deployed environment
```

`runserver` is single-threaded, auto-reloading, and explicitly documented as
unfit for production.

### Rationale

`check --deploy` encodes Django's own security checklist. Running it as a gate
converts a review checklist into an enforced one.

---

## See Also

- [`profiles/python.md`](python.md): language rules that remain in force
- [`profiles/flask.md`](flask.md): parallel profile for Flask projects
- [`skills/web-development.md`](../skills/web-development.md): implementation patterns
- [`skills/approved-packages.md`](../skills/approved-packages.md): authorized libraries (§5)
- [`skills/database-access.md`](../skills/database-access.md): query patterns
- [`skills/containerization.md`](../skills/containerization.md): image and deployment patterns
