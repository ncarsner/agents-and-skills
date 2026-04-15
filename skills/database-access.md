# Skill: Database Access

Complete reference for database access patterns in Python using SQLAlchemy.
Covers connection management, ORM models, raw queries, migrations, and testing.

---

## Quick Reference: Key Commands

```bash
uv add sqlalchemy                  # core ORM
uv add alembic                     # schema migrations
uv add psycopg2-binary             # PostgreSQL driver
uv add aiosqlite                   # async SQLite driver
uv run alembic init alembic        # initialize migration environment
uv run alembic revision --autogenerate -m "add users table"
uv run alembic upgrade head        # apply all pending migrations
uv run alembic downgrade -1        # revert last migration
```

---

## Engine and Session Factory

```python
"""Database engine and session management."""

from collections.abc import Generator
from contextlib import contextmanager

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    """Shared declarative base for all ORM models."""


def make_engine(database_url: str, *, echo: bool = False):
    """Create a SQLAlchemy engine.

    Args:
        database_url: Connection string (e.g., sqlite:///app.db,
            postgresql+psycopg2://user:pass@host/db).
        echo: If True, log all SQL statements (development only).

    Returns:
        Configured Engine instance.
    """
    return create_engine(database_url, echo=echo, pool_pre_ping=True)


def make_session_factory(database_url: str) -> sessionmaker[Session]:
    """Create a session factory and initialize the schema.

    Args:
        database_url: SQLAlchemy-compatible connection string.

    Returns:
        Configured sessionmaker.
    """
    engine = make_engine(database_url)
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine, expire_on_commit=False)


@contextmanager
def get_session(factory: sessionmaker[Session]) -> Generator[Session, None, None]:
    """Provide a transactional session scope.

    Commits on success; rolls back and re-raises on exception.

    Args:
        factory: The sessionmaker to use.

    Yields:
        Active SQLAlchemy Session.
    """
    session = factory()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
```

---

## ORM Model Pattern

```python
"""SQLAlchemy ORM models."""

from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from my_app.db.session import Base


class User(Base):
    """Registered application user."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    orders: Mapped[list["Order"]] = relationship("Order", back_populates="user")


class Order(Base):
    """A purchase order belonging to a user."""

    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    total: Mapped[float] = mapped_column(Float, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    user: Mapped[User] = relationship("User", back_populates="orders")
```

---

## CRUD Patterns

```python
"""Standard CRUD operations using SQLAlchemy ORM."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from my_app.db.models import User


def create_user(session: Session, email: str, name: str) -> User:
    """Insert a new user and return the persisted instance."""
    user = User(email=email, name=name)
    session.add(user)
    session.flush()  # assigns user.id without committing
    return user


def get_user_by_id(session: Session, user_id: int) -> User | None:
    """Fetch a user by primary key; return None if not found."""
    return session.get(User, user_id)


def get_user_by_email(session: Session, email: str) -> User | None:
    """Fetch a user by email address."""
    return session.scalar(select(User).where(User.email == email))


def list_users(session: Session, *, limit: int = 100, offset: int = 0) -> list[User]:
    """Return a paginated list of users ordered by creation date."""
    stmt = select(User).order_by(User.created_at.desc()).limit(limit).offset(offset)
    return list(session.scalars(stmt))


def update_user_name(session: Session, user_id: int, new_name: str) -> User:
    """Update a user's name; raise ValueError if user not found."""
    user = get_user_by_id(session, user_id)
    if user is None:
        raise ValueError(f"User {user_id} not found")
    user.name = new_name
    session.flush()
    return user


def delete_user(session: Session, user_id: int) -> None:
    """Delete a user by ID; raise ValueError if not found."""
    user = get_user_by_id(session, user_id)
    if user is None:
        raise ValueError(f"User {user_id} not found")
    session.delete(user)
```

---

## Raw Query Pattern (Parameterized)

```python
"""Parameterized raw SQL for complex queries not suited to ORM."""

from sqlalchemy import text
from sqlalchemy.orm import Session


def get_top_spenders(session: Session, *, top_n: int = 10) -> list[dict]:
    """Return the top N users by total order value.

    Uses a raw SQL query with a named bind parameter.

    Args:
        session: Active database session.
        top_n: Number of results to return.

    Returns:
        List of dicts with keys: user_id, email, total_spent.
    """
    stmt = text("""
        SELECT u.id AS user_id, u.email, SUM(o.total) AS total_spent
        FROM users u
        JOIN orders o ON o.user_id = u.id
        GROUP BY u.id, u.email
        ORDER BY total_spent DESC
        LIMIT :top_n
    """)
    rows = session.execute(stmt, {"top_n": top_n}).mappings().all()
    return [dict(row) for row in rows]
```

---

## Alembic Migration Workflow

```
alembic/
├── env.py          # migration environment (edit to import your Base)
├── script.py.mako  # template for migration scripts
└── versions/       # auto-generated migration files
```

Edit `alembic/env.py` to point at your models:

```python
from my_app.db.session import Base
target_metadata = Base.metadata
```

```bash
# Generate a migration from model changes
uv run alembic revision --autogenerate -m "add orders table"

# Review the generated file in alembic/versions/, then apply
uv run alembic upgrade head

# Check current revision
uv run alembic current

# Roll back one step
uv run alembic downgrade -1
```

---

## Testing with an In-Memory Database

```python
"""Fixtures for database-backed tests using SQLite in-memory."""

from collections.abc import Generator

import pytest
from sqlalchemy.orm import Session

from my_app.db.session import Base, get_session, make_session_factory


@pytest.fixture(scope="session")
def db_factory():
    """Session-scoped SQLite in-memory database factory."""
    factory = make_session_factory("sqlite:///:memory:")
    return factory


@pytest.fixture
def db_session(db_factory) -> Generator[Session, None, None]:
    """Function-scoped session; each test gets a clean transaction."""
    with get_session(db_factory) as session:
        yield session
        session.rollback()


def test_create_and_fetch_user(db_session: Session) -> None:
    """Creating a user should persist it and make it retrievable."""
    from my_app.db.crud import create_user, get_user_by_email

    user = create_user(db_session, email="alice@example.com", name="Alice")
    assert user.id is not None

    fetched = get_user_by_email(db_session, "alice@example.com")
    assert fetched is not None
    assert fetched.name == "Alice"
```

---

## Connection String Reference

| Database | URL Format |
|----------|-----------|
| SQLite (file) | `sqlite:///./app.db` |
| SQLite (memory) | `sqlite:///:memory:` |
| PostgreSQL | `postgresql+psycopg2://user:pass@host:5432/dbname` |
| MySQL | `mysql+pymysql://user:pass@host:3306/dbname` |
| SQL Server | `mssql+pyodbc://user:pass@host/dbname?driver=ODBC+Driver+17+for+SQL+Server` |

Always load connection strings from environment variables — never hard-code them.

---

## See Also

- [`agents/data-engineering-agent.md`](../agents/data-engineering-agent.md)
- [`agents/security-agent.md`](../agents/security-agent.md) — SQL injection prevention
- [`skills/configuration-management.md`](configuration-management.md) — secrets via env vars
- [`skills/python-testing.md`](python-testing.md) — testing cookbook
