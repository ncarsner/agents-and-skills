# profiles/tsql.md: T-SQL Dialect Profile (Microsoft SQL Server)

Active profile for repositories whose primary database is Microsoft SQL Server.
Load this file when `RULES.md` declares `Domain: profiles/tsql.md`.

This profile is normative. It states what agents MUST and MUST NOT do. For
implementation patterns, load
[`skills/database-access.md`](../skills/database-access.md); this file does not
restate its recipes.

Stacks on top of [`profiles/python.md`](python.md) and any active framework
profile, all of which remain in force. The framework profiles already mandate
SQLAlchemy 2.x typed models, which abstracts most of what follows. The rules
here bind the places dialect actually leaks through: raw SQL, DDL, connection
strings, stored procedures, and error handling.

---

## Connectivity

**Rule:** No SQL Server driver is currently authorized. `pyodbc`, `pymssql`, and
the Microsoft ODBC driver appear in neither
[`templates/authorized_libraries.md`](../templates/authorized_libraries.md) nor
[`skills/approved-packages.md`](../skills/approved-packages.md). Adding one
requires the [RULES.md §5](../RULES.md#5-third-party-library-authorization)
authorization and 72-hour cooling process before any connection code is
committed.

Note that `skills/database-access.md` Connection String Reference already
documents an `mssql+pyodbc://` DSN. That entry predates this profile and does
not constitute authorization.

Once a driver is authorized, these requirements apply:

| Concern | Requirement |
|---|---|
| DSN | From a `DATABASE_URL` environment variable, never a literal |
| Encryption | `Encrypt=yes`; `TrustServerCertificate=yes` only for local development, never a deployed tier |
| Authentication | Integrated or managed identity where available, in preference to a SQL login |
| Pooling | Explicit pool size; never the driver defaults in a service |
| ODBC driver version | Pinned explicitly in the DSN, so a host upgrade cannot change behavior silently |

Extends [RULES.md §8](../RULES.md#8-security-and-secrets).

### Prohibited

```python
create_engine("mssql+pyodbc://sa:hunter2@prod/app?driver=...")  # NEVER: literal credentials
logger.info("connecting to %s", settings.database_url)          # NEVER: DSN carries the password
```

---

## Identifiers and Types

**Rule:** Identifiers MUST be unquoted, and every object reference MUST be
schema-qualified. Column types MUST be chosen from the table below.

Bracket quoting (`[Order Details]`) is permitted only when an identifier cannot
be renamed. New objects MUST NOT require it.

### Required type choices

| Use | Use this | Not this | Why |
|---|---|---|---|
| Text | `NVARCHAR(n)` or `NVARCHAR(MAX)` | `VARCHAR`, `TEXT` | `VARCHAR` loses non-Latin characters; `TEXT` is deprecated |
| Timestamp | `DATETIME2` | `DATETIME`, `SMALLDATETIME` | `DATETIME` has ~3ms granularity and a 1753 floor |
| Timestamp with offset | `DATETIMEOFFSET` | `DATETIME2` for cross-zone data | `DATETIME2` carries no offset |
| Money and exact decimals | `DECIMAL(p,s)` | `MONEY`, `FLOAT` | `MONEY` has 4-digit scale and silent truncation |
| Surrogate key | `INT`/`BIGINT IDENTITY(1,1)` or a `SEQUENCE` | `UNIQUEIDENTIFIER` as a clustered key | Random GUIDs fragment the clustered index |
| Row versioning | `ROWVERSION` | A hand-maintained column | `ROWVERSION` is maintained by the engine |

Schema-qualify every reference (`dbo.orders`, not `orders`). An unqualified
name resolves against the caller's default schema, so the same statement can
hit different tables for different users.

### Rationale

SQL Server's default collation is usually case-insensitive, so case bugs stay
hidden until the database is restored with a different collation, or until the
same query is ported to Postgres or Oracle.

---

## Parameterization

**Rule:** Every value interpolated into SQL MUST be a bind parameter. Dynamic
SQL built by string concatenation is prohibited. Where dynamic SQL is
unavoidable, it MUST use `sp_executesql` with declared parameters.

Extends [RULES.md §8](../RULES.md#8-security-and-secrets).

| Layer | Placeholder |
|---|---|
| SQLAlchemy `text()` | `:name` |
| `pyodbc` directly | `?` positional |
| T-SQL batch or procedure | `@name` declared parameters |

### Prohibited

```python
cursor.execute(f"SELECT * FROM dbo.users WHERE email = '{email}'")   # NEVER
```

```sql
-- NEVER: concatenated dynamic SQL
SET @sql = N'SELECT * FROM dbo.users WHERE email = ''' + @email + '''';
EXEC(@sql);

-- Correct: parameterized dynamic SQL
SET @sql = N'SELECT * FROM dbo.users WHERE email = @e';
EXEC sp_executesql @sql, N'@e NVARCHAR(320)', @e = @email;
```

`EXEC(@sql)` with a concatenated string is a SQL injection vector even when the
input appears internal.

---

## Query Constructs

**Rule:** Every query that returns a set MUST be bounded, and every paginated
query MUST have an `ORDER BY`. `NOLOCK` is prohibited.

Extends [RULES.md §14](../RULES.md#14-performance-standards).

### Pagination

```sql
SELECT id, email FROM dbo.users
ORDER BY id
OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY;
```

`OFFSET ... FETCH` requires `ORDER BY`; SQL Server rejects it otherwise. `TOP n`
is acceptable for a bounded single page but cannot express an offset. Note that
`LIMIT` does not exist in T-SQL: any query written with `LIMIT` came from
another dialect and is a portability defect, not a syntax preference.

For deep paging, use keyset pagination:

```sql
SELECT TOP (:limit) id, email FROM dbo.users WHERE id > :last_id ORDER BY id;
```

### Upsert

`MERGE` is available but has a long history of concurrency and correctness
defects. Prefer an explicit guarded pattern:

```sql
BEGIN TRANSACTION;
UPDATE dbo.counters WITH (UPDLOCK, HOLDLOCK)
   SET value = @value WHERE [key] = @key;
IF @@ROWCOUNT = 0
    INSERT INTO dbo.counters ([key], value) VALUES (@key, @value);
COMMIT;
```

`UPDLOCK, HOLDLOCK` is what makes the check-then-insert race-free. Without it,
two concurrent callers both see zero rows and both insert.

If `MERGE` is used, it MUST include `HOLDLOCK` on the target and MUST be
justified in a comment on the statement.

### NULL ordering and comparison

SQL Server sorts `NULL` **first** in `ASC`, the opposite of PostgreSQL and
Oracle. There is no `NULLS LAST` clause; emulate it with
`ORDER BY CASE WHEN col IS NULL THEN 1 ELSE 0 END, col`.

`+` propagates `NULL` through string concatenation; `CONCAT()` treats `NULL` as
an empty string. Choose deliberately.

### Prohibited

```sql
SELECT * FROM dbo.events WITH (NOLOCK);     -- NEVER: dirty reads, and can
                                            -- return duplicated or missing rows
SELECT * FROM dbo.events;                   -- NEVER: unbounded in a request path
```

`NOLOCK` is not a performance setting. It permits reading uncommitted data and,
under page splits, the same row twice or not at all. Use
`READ_COMMITTED_SNAPSHOT` instead.

---

## Transactions and Locking

**Rule:** `SET XACT_ABORT ON` MUST be set in every stored procedure and every
multi-statement batch that writes. Database-level
`READ_COMMITTED_SNAPSHOT` MUST be enabled unless a documented reason prevents
it.

### Mandatory settings

| Setting | Requirement |
|---|---|
| `XACT_ABORT` | `ON` in every writing procedure or batch |
| `READ_COMMITTED_SNAPSHOT` | `ON` at the database level |
| Lock timeout | `SET LOCK_TIMEOUT` set, so a blocked writer fails fast |
| Isolation | Default `READ COMMITTED` under RCSI; `SERIALIZABLE` only where required and documented |

Retry on deadlock (error `1205`) with backoff. Deadlocks are an expected
outcome under concurrency, not a defect to be caught and swallowed.

### Prohibited

```sql
-- NEVER: without XACT_ABORT ON, a failed statement can leave the
-- transaction open and the connection returns it to the pool mid-transaction
BEGIN TRANSACTION;
INSERT INTO dbo.orders ...;
COMMIT;
```

- Do NOT hold a transaction open across a network call to another service.
- Do NOT rely on `@@ERROR` after each statement. Use `TRY`/`CATCH`.

### Rationale

Without `XACT_ABORT ON`, many errors abort only the current statement, leaving
an open transaction that holds locks until the pooled connection is reused or
reset. That failure mode presents as unrelated timeouts elsewhere in the
application.

---

## DDL and Migrations

**Rule:** Schema changes MUST run through `alembic`, per the migration rules in
the active framework profile. Every migration MUST be wrapped so a failure
rolls back cleanly.

SQL Server DDL is transactional, so a migration can roll back. The risk is lock
duration and blocking, not partial application.

| Operation | Lock impact |
|---|---|
| `ADD COLUMN` nullable, no default | Metadata only |
| `ADD COLUMN NOT NULL` with default | Metadata only on Enterprise 2012+, full rewrite otherwise |
| `ALTER COLUMN` type change | Full rewrite, blocks the table |
| `CREATE INDEX` | Blocks writes; `ONLINE = ON` requires Enterprise |
| Adding a foreign key | Validates all rows unless created `WITH NOCHECK` |

Verify the target edition before assuming an online operation is available.
`ONLINE = ON` silently is not available on Standard edition below 2019.

### Prohibited

- Do NOT drop a column in the same release that stops writing it. Use the
  three-release expand/backfill/contract protocol in
  [`profiles/flask.md`](flask.md) Migrations.
- Do NOT add a foreign key `WITH NOCHECK` and leave it untrusted. An untrusted
  constraint is ignored by the query optimizer.

---

## Error Handling and Testing

**Rule:** Errors MUST be handled with `TRY`/`CATCH` in T-SQL and by specific
exception type in Python. `RAISERROR` MUST NOT be used in new code; use
`THROW`. Bare `except` is prohibited
([RULES.md §9](../RULES.md#9-error-handling)).

```sql
BEGIN TRY
    BEGIN TRANSACTION;
    -- work
    COMMIT;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;                          -- preserves error number, severity, and line
END CATCH;
```

`XACT_STATE()` MUST be checked before rolling back: an uncommittable
transaction (`-1`) cannot be committed, and rolling back a nonexistent
transaction (`0`) raises a second error that masks the first.

### Error number mapping

| Error | Meaning | Correct handling |
|---|---|---|
| `2627` / `2601` | Unique constraint or index violation | Map to a 409 or a domain "already exists" error |
| `547` | Foreign key or check constraint violation | Map to a 422, not a 500 |
| `1205` | Deadlock victim | Retry with backoff |
| `-2` | Query timeout | Map to a 504, log the query |

Match on error number, never on message text; messages are localized.

### Testing

Do NOT substitute SQLite for SQL Server in tests. They disagree on types,
`NULL` ordering, identifier resolution, and locking semantics. Run a real
instance in a container and roll back a transaction per test.

---

## See Also

- [`profiles/python.md`](python.md): language rules that remain in force
- [`profiles/postgres.md`](postgres.md), [`profiles/plsql.md`](plsql.md): parallel dialect profiles
- [`skills/database-access.md`](../skills/database-access.md): SQLAlchemy patterns, migrations, connection strings
- [`skills/approved-packages.md`](../skills/approved-packages.md): authorized libraries (§5)
