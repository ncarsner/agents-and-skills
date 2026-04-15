# Skill: Web Development

Patterns and recipes for building Python web applications and REST APIs using
FastAPI, Flask, and Django.

---

## Framework Selection Guide

| Criteria | FastAPI | Flask | Django |
|----------|---------|-------|--------|
| REST API (new project) | ✅ Default choice | ✓ | — |
| Async support | ✅ Native | Partial | Partial |
| Auto-generated OpenAPI docs | ✅ Built-in | Manual | Manual |
| Full-featured app (auth, admin, ORM) | — | — | ✅ |
| Quick prototype / script serving | — | ✅ | — |
| Existing codebase | Match existing | — | — |

---

## FastAPI Patterns

### Request validation with Pydantic
```python
from pydantic import BaseModel, Field, EmailStr
from fastapi import FastAPI

app = FastAPI()


class UserCreate(BaseModel):
    """Request body for creating a user."""
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    age: int = Field(..., ge=18, le=120)


class UserResponse(BaseModel):
    """Response body for a user."""
    id: int
    name: str
    email: str

    model_config = {"from_attributes": True}


@app.post("/users", response_model=UserResponse, status_code=201)
async def create_user(payload: UserCreate) -> UserResponse:
    """Create a new user account."""
    user = await user_service.create(payload)
    return user
```

### Dependency injection
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()


async def verify_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> str:
    """Verify Bearer token and return user ID.

    Raises:
        HTTPException: 401 if token is invalid.
    """
    token = credentials.credentials
    user_id = await auth_service.validate(token)
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    return user_id


@app.get("/profile")
async def get_profile(user_id: str = Depends(verify_token)) -> dict:
    """Return the authenticated user's profile."""
    return await user_service.get_profile(user_id)
```

### Background tasks
```python
from fastapi import BackgroundTasks


@app.post("/reports/generate")
async def generate_report(
    report_id: int, background_tasks: BackgroundTasks
) -> dict:
    """Kick off report generation in the background."""
    background_tasks.add_task(report_service.generate, report_id)
    return {"status": "queued", "report_id": report_id}
```

### Exception handling
```python
from fastapi import Request
from fastapi.responses import JSONResponse


class EntityNotFoundError(Exception):
    """Raised when a requested resource does not exist."""
    def __init__(self, entity: str, entity_id: int) -> None:
        self.entity = entity
        self.entity_id = entity_id


@app.exception_handler(EntityNotFoundError)
async def entity_not_found_handler(
    request: Request, exc: EntityNotFoundError
) -> JSONResponse:
    """Return 404 JSON response for EntityNotFoundError."""
    return JSONResponse(
        status_code=404,
        content={"detail": f"{exc.entity} with id {exc.entity_id} not found"},
    )
```

---

## Flask Patterns

### App factory
```python
"""Flask application factory."""

from flask import Flask
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def create_app(config: dict | None = None) -> Flask:
    """Create and configure a Flask app instance."""
    app = Flask(__name__)
    app.config.from_mapping(
        SECRET_KEY="dev",
        SQLALCHEMY_DATABASE_URI="sqlite:///dev.db",
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
    )
    if config:
        app.config.update(config)

    db.init_app(app)

    from .routes import items_bp
    app.register_blueprint(items_bp, url_prefix="/api/items")

    return app
```

### Blueprint pattern
```python
"""Items blueprint."""

from flask import Blueprint, jsonify, request, abort

items_bp = Blueprint("items", __name__)


@items_bp.get("/")
def list_items():
    """Return all items as JSON."""
    items = item_service.list_all()
    return jsonify([i.to_dict() for i in items])


@items_bp.get("/<int:item_id>")
def get_item(item_id: int):
    """Return a single item or 404."""
    item = item_service.get_by_id(item_id)
    if item is None:
        abort(404, description=f"Item {item_id} not found")
    return jsonify(item.to_dict())


@items_bp.post("/")
def create_item():
    """Create a new item from JSON body."""
    data = request.get_json(force=True)
    if not data or "name" not in data:
        abort(400, description="Field 'name' is required")
    item = item_service.create(data)
    return jsonify(item.to_dict()), 201
```

---

## Database Patterns (SQLAlchemy 2.x)

```python
"""SQLAlchemy 2.x async database setup."""

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Declarative base for all models."""


class Item(Base):
    """Database model for an item."""

    __tablename__ = "items"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(nullable=False)
    value: Mapped[float] = mapped_column(default=0.0)


engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/mydb")
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


async def get_db_session() -> AsyncSession:
    """FastAPI dependency: yield a database session."""
    async with AsyncSessionLocal() as session:
        yield session
```

---

## API Versioning

Structure routes with version prefix:
```
/api/v1/users/
/api/v1/items/
/api/v2/users/    ← breaking changes go in v2
```

```python
# FastAPI
app.include_router(v1_router, prefix="/api/v1")
app.include_router(v2_router, prefix="/api/v2")
```

---

## Environment Configuration

```python
"""Settings using pydantic-settings with validation."""

from pydantic import PostgresDsn, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)

    app_name: str = "My API"
    debug: bool = False
    database_url: PostgresDsn
    jwt_secret: str
    jwt_expire_minutes: int = 30
    allowed_origins: list[str] = ["http://localhost:3000"]

    @field_validator("jwt_secret")
    @classmethod
    def secret_must_be_long(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("jwt_secret must be at least 32 characters")
        return v
```

---

## Security Patterns

```python
"""JWT authentication utilities."""

from datetime import datetime, timedelta, timezone

import jwt


def create_access_token(user_id: str, secret: str, expire_minutes: int = 30) -> str:
    """Create a signed JWT access token.

    Args:
        user_id: Subject identifier.
        secret: HMAC secret key.
        expire_minutes: Token lifetime in minutes.

    Returns:
        Encoded JWT string.
    """
    payload = {
        "sub": user_id,
        "exp": datetime.now(tz=timezone.utc) + timedelta(minutes=expire_minutes),
        "iat": datetime.now(tz=timezone.utc),
    }
    return jwt.encode(payload, secret, algorithm="HS256")


def decode_access_token(token: str, secret: str) -> dict:
    """Decode and verify a JWT token.

    Raises:
        jwt.ExpiredSignatureError: If token has expired.
        jwt.InvalidTokenError: If token is malformed or signature is invalid.
    """
    return jwt.decode(token, secret, algorithms=["HS256"])
```

---

## CORS and Headers

```python
# FastAPI CORS (development — restrict in production)
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,   # never use ["*"] in production
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

---

## Testing

```python
"""FastAPI integration tests."""

import pytest
from fastapi.testclient import TestClient
from my_api.main import create_app


@pytest.fixture(scope="module")
def client() -> TestClient:
    """Test client with in-memory SQLite database."""
    app = create_app({"database_url": "sqlite:///./test.db", "debug": True})
    return TestClient(app)


def test_health_check(client: TestClient) -> None:
    assert client.get("/health").status_code == 200


def test_create_item_validates_name(client: TestClient) -> None:
    """Empty name should return 422 Unprocessable Entity."""
    response = client.post("/api/v1/items/", json={"name": "", "value": 10.0})
    assert response.status_code == 422
```

---

## See Also

- [`agents/web-dev-agent.md`](../agents/web-dev-agent.md)
- [`skills/python-testing.md`](python-testing.md)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
