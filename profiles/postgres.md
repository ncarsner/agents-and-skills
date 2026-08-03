# profiles/postgres.md: PostgreSQL Dialect Profile

Active profile for repositories whose primary database is PostgreSQL. Load this
file when `RULES.md` declares `Domain: profiles/postgres.md`.

This profile is normative. It states what agents MUST and MUST NOT do. For
implementation patterns, load
[`skills/database-access.md`](../skills/database-access.md); this file does not
restate its recipes.

Stacks on top of [`profiles/python.md`](python.md) and any active framework
profile, all of which remain in force. The framework profiles already mandate
SQLAlchemy 2.x typed models, which abstracts most of what follows. The rules
here bind the places dialect actually leaks through: raw SQL, DDL, connection
strings, and error handling.

---

## Connectivity

**Rule:** Connection details MUST come from a `DATABASE_URL` environment
variable. Credentials MUST NOT appear in a connection string literal, a
`.pgpass` file committed to the repository, or a log record.

Extends [RULES.md §8](../RULES.md#8-security-and-secrets).

| Concern | Requirement |
|---|---|
| Sync driver | `psycopg2-binary`, listed in [`skills/approved-packages.md`](../skills/approved-packages.md) |
| Async driver | `asyncpg`, listed in the same file |
| DSN | `postgresql+psycopg2://...` or `postgresql+asyncpg://...`, from env |
| TLS | `sslmode=require` or stricter for any non-local host |
| Pooling | Explicit `pool_size` and `max_overflow`; never the driver defaults in a service |

Both drivers are listed in `skills/approved-packages.md`, the authoritative §5
list, so no approval proposal is needed. Record the one you adopt in the
project's `authorized_libraries.md` and serve the 72-hour cooling period before
committing it.

### Prohibited

```python
create_engine("postgresql://app:hunter2@prod-db/app")   # NEVER: literal credentials
logger.info("connecting to %s", settings.database_url)  # NEVER: DSN carries the password
```

Log the host and database name, never the DSN.

---

## Identifiers and Types

**Rule:** Identifiers MUST be lower_snake_case and unquoted. Column types MUST
be chosen from the table below; the listed alternatives MUST NOT be used
without a documented reason.

### Required type choices

| Use | Use this | Not this | Why |
|---|---|---|---|
| Text of any length | `text` | `varchar(n)` | No performance difference; `n` is a migration waiting to happen |
| Timestamp | `timestamptz` | `timestamp` | `timestamp` silently drops the offset |
| Money and exact decimals | `numeric(p,s)` | `float`, `real`, `money` | Binary floats cannot represent decimal cents |
| Structured document | `jsonb` | `json` | `json` cannot be indexed or searched efficiently |
| Surrogate key | `bigint GENERATED ALWAYS AS IDENTITY` | `serial`, `bigserial` | `serial` leaves an orphaned sequence and non-standard DDL |
| Enumerated value | `text` plus a `CHECK`, or a lookup table | `enum` type | Adding a value to an `enum` needs DDL and cannot be done in one transaction on older versions |

### Prohibited

```sql
CREATE TABLE "Orders" ("orderId" serial PRIMARY KEY);   -- NEVER: quoted mixed case
```

Unquoted identifiers fold to lowercase. Quoting `"orderId"` forces every
subsequent reference, in every tool and every ORM mapping, to quote it
identically forever. Use `order_id`.

### Rationale

Postgres's case folding is the opposite of Oracle's, so mixed-case identifiers
are the single largest source of portability breakage between the two.

---

## Parameterization

**Rule:** Every value interpolated into SQL MUST be a bind parameter. String
formatting into a SQL string is prohibited without exception, including for
values the agent believes are internally generated.

Extends [RULES.md §8](../RULES.md#8-security-and-secrets).

| Layer | Placeholder |
|---|---|
| SQLAlchemy `text()` | `:name` |
| `psycopg2` directly | `%s` positional, `%(name)s` named |
| `asyncpg` directly | `$1`, `$2` |

Identifiers cannot be bound. When a table or column name must be dynamic,
validate it against an allowlist and quote it with
`psycopg2.sql.Identifier`, never with an f-string.

### Prohibited

```python
cur.execute(f"SELECT * FROM users WHERE email = '{email}'")   # NEVER
cur.execute("SELECT * FROM users WHERE email = '%s'" % email) # NEVER
cur.execute(f"SELECT * FROM {table}")                         # NEVER: unvalidated identifier
```

```python
# Correct
cur.execute("SELECT * FROM users WHERE email = %s", (email,))
```

---

## Query Constructs

**Rule:** Every query that returns a set MUST be bounded. `ORDER BY` MUST
accompany every `LIMIT`, and `NULL` ordering MUST be stated explicitly wherever
it affects results.

Extends [RULES.md §14](../RULES.md#14-performance-standards).

### Pagination

```sql
SELECT id, email FROM users ORDER BY id LIMIT :limit OFFSET :offset;
```

`OFFSET` scans and discards every skipped row, so it degrades linearly. For any
endpoint that can page deeply, use keyset pagination instead:

```sql
SELECT id, email FROM users WHERE id > :last_id ORDER BY id LIMIT :limit;
```

A `LIMIT` without `ORDER BY` returns an arbitrary subset that can change
between identical calls.

### Upsert

```sql
INSERT INTO counters (key, value) VALUES (:key, :value)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;
```

`ON CONFLICT` requires a unique index or constraint on the named columns. It is
atomic and race-free, and MUST be used in preference to a read-then-write
sequence.

### NULL ordering and comparison

Postgres sorts `NULL` last in `ASC` and first in `DESC`. State
`NULLS LAST` or `NULLS FIRST` explicitly in any query whose output is
compared against another dialect, since SQL Server sorts the opposite way.

`NULL = NULL` is `NULL`, not true. Use `IS NULL` and `IS DISTINCT FROM`.

### Prohibited

```sql
SELECT * FROM events;                       -- NEVER: unbounded in a request path
SELECT * FROM events LIMIT 100;             -- NEVER: no ORDER BY, arbitrary rows
SELECT a || b FROM t;                       -- careful: NULL operand yields NULL,
                                            -- use concat() when that is wrong
```

---

## Transactions and Locking

**Rule:** Every write path MUST run inside an explicit transaction with a
defined boundary. Timeouts MUST be set; a statement MUST NOT be able to run or
idle indefinitely.

Extends [RULES.md §14](../RULES.md#14-performance-standards).

### Mandatory settings

| Setting | Requirement |
|---|---|
| `statement_timeout` | Set per session or role. Never unlimited in a service |
| `lock_timeout` | Set, so a blocked writer fails fast instead of queueing |
| `idle_in_transaction_session_timeout` | Set, so an abandoned transaction cannot hold locks forever |
| Isolation | `READ COMMITTED` default is acceptable; `REPEATABLE READ` where a read informs a write |

Use `SELECT ... FOR UPDATE` when a read determines a subsequent write. Retry on
serialization failure (SQLSTATE `40001`) and deadlock (`40P01`) with backoff;
both are expected outcomes, not bugs.

### Prohibited

- Do NOT hold a transaction open across a network call to another service.
- Do NOT run a long backfill in a single transaction. Batch it, and commit per
  batch.
- Do NOT use advisory locks as a general-purpose mutex without documenting the
  key allocation; the key space is global to the database.

---

## DDL and Migrations

**Rule:** Schema changes MUST run through `alembic`, per the migration rules in
the active framework profile. Any DDL that takes a long-lived exclusive lock
MUST be split so the lock is not held during a table rewrite.

### Locking behavior

Postgres DDL is transactional, so a failed migration rolls back cleanly. That
makes the danger not partial failure but lock duration:

| Operation | Lock impact |
|---|---|
| `ADD COLUMN` with no default | Instant, metadata only |
| `ADD COLUMN` with a volatile default | Rewrites the table on older versions; check the target version |
| `ALTER COLUMN TYPE` | Full rewrite under `ACCESS EXCLUSIVE` |
| `CREATE INDEX` | Blocks writes for the duration |
| `CREATE INDEX CONCURRENTLY` | Does not block, but cannot run inside a transaction |
| `ADD CONSTRAINT ... NOT VALID` then `VALIDATE` | Two short locks instead of one long one |

Because `CREATE INDEX CONCURRENTLY` cannot run in a transaction, its migration
MUST set `atomic = False` (or the driver equivalent) and MUST be the only
operation in that revision.

### Prohibited

- Do NOT add a `NOT NULL` constraint to a populated table in one step. Add the
  column nullable, backfill in batches, then set `NOT NULL` with a validated
  `CHECK`.
- Do NOT create an index on a large production table without `CONCURRENTLY`.

---

## Error Handling and Testing

**Rule:** Database errors MUST be caught by specific exception type or SQLSTATE
and mapped to a domain error. Bare `except` is prohibited
([RULES.md §9](../RULES.md#9-error-handling)). Tests MUST run against a real
PostgreSQL instance.

### SQLSTATE mapping

| SQLSTATE | Meaning | Correct handling |
|---|---|---|
| `23505` | Unique violation | Map to a 409 or a domain "already exists" error |
| `23503` | Foreign key violation | Map to a 422, not a 500 |
| `40001` | Serialization failure | Retry with backoff |
| `40P01` | Deadlock detected | Retry with backoff |
| `57014` | Query cancelled, statement timeout | Map to a 504, log the query |

Catch `psycopg2.errors.UniqueViolation` and its siblings, or inspect
`exc.orig.sqlstate` through SQLAlchemy. Do not match on message text; messages
are localized and change between versions.

### Testing

Do NOT substitute SQLite for PostgreSQL in tests. The two disagree on type
affinity, `NULL` ordering, `ON CONFLICT` semantics, transactional DDL, and
concurrent behavior, so a passing SQLite suite proves nothing about production.
Run a real instance in a container and roll back a transaction per test.

The in-memory SQLite recipe in `skills/database-access.md` applies only to
projects whose production database is SQLite.

---

## See Also

- [`profiles/python.md`](python.md): language rules that remain in force
- [`profiles/tsql.md`](tsql.md), [`profiles/plsql.md`](plsql.md): parallel dialect profiles
- [`skills/database-access.md`](../skills/database-access.md): SQLAlchemy patterns, migrations, connection strings
- [`skills/approved-packages.md`](../skills/approved-packages.md): authorized libraries (§5)
