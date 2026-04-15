# Web Development Agent Instructions

This file extends `AGENTS.md` with instructions specific to **Python web
development**. Read root `AGENTS.md` first.

---

## Supported Frameworks

| Framework | Use Case | Install |
|-----------|----------|---------|
| **FastAPI** | REST APIs, async services | `uv add fastapi uvicorn` |
| **Flask** | Lightweight web apps, quick prototypes | `uv add flask` |
| **Django** | Full-featured apps with ORM and admin | `uv add django` |

Default choice for new REST APIs: **FastAPI** — unless the project already uses
Flask or Django.

---

## Project Structure (FastAPI)

```
my-api/
├── pyproject.toml
├── uv.lock
├── .python-version
├── .env.example
├── README.md
├── AGENTS.md
├── src/
│   └── my_api/
│       ├── __init__.py
│       ├── main.py            # FastAPI app factory
│       ├── config.py          # settings via pydantic-settings
│       ├── dependencies.py    # shared FastAPI dependencies
│       ├── routers/
│       │   ├── __init__.py
│       │   └── items.py
│       ├── models/
│       │   ├── __init__.py
│       │   └── item.py        # Pydantic request/response models
│       ├── services/
│       │   ├── __init__.py
│       │   └── item_service.py
│       └── db/
│           ├── __init__.py
│           └── session.py
└── tests/
    ├── conftest.py
    ├── unit/
    │   └── test_item_service.py
    └── integration/
        └── test_items_router.py
```

---

## FastAPI App Factory

```python
"""FastAPI application factory."""

from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from my_api.config import Settings
from my_api.routers import items


def create_app(settings: Settings | None = None) -> FastAPI:
    """Create and configure the FastAPI application."""
    if settings is None:
        settings = Settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
        # startup
        yield
        # shutdown

    app = FastAPI(
        title=settings.app_name,
        version=settings.version,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(items.router, prefix="/api/v1")
    return app


app = create_app()
```

---

## Settings Management

```python
"""Application settings using pydantic-settings."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    app_name: str = "My API"
    version: str = "0.1.0"
    debug: bool = False
    allowed_origins: list[str] = ["http://localhost:3000"]
    database_url: str = "sqlite:///./dev.db"
    secret_key: str  # required — no default, must be in .env
```

---

## Router Pattern

```python
"""Items router."""

from fastapi import APIRouter, Depends, HTTPException, status

from my_api.models.item import ItemCreate, ItemResponse
from my_api.services.item_service import ItemService

router = APIRouter(prefix="/items", tags=["items"])


def get_service() -> ItemService:
    """Dependency: return ItemService instance."""
    return ItemService()


@router.get("/", response_model=list[ItemResponse])
async def list_items(service: ItemService = Depends(get_service)) -> list[ItemResponse]:
    """Return all items."""
    return await service.list_all()


@router.get("/{item_id}", response_model=ItemResponse)
async def get_item(
    item_id: int, service: ItemService = Depends(get_service)
) -> ItemResponse:
    """Return a single item by ID."""
    item = await service.get_by_id(item_id)
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
    return item


@router.post("/", response_model=ItemResponse, status_code=status.HTTP_201_CREATED)
async def create_item(
    payload: ItemCreate, service: ItemService = Depends(get_service)
) -> ItemResponse:
    """Create a new item."""
    return await service.create(payload)
```

---

## Pydantic Models

```python
"""Pydantic request/response models for items."""

from pydantic import BaseModel, Field, field_validator


class ItemBase(BaseModel):
    """Shared item fields."""

    name: str = Field(..., min_length=1, max_length=100)
    value: float = Field(..., ge=0)


class ItemCreate(ItemBase):
    """Request model for creating an item."""


class ItemResponse(ItemBase):
    """Response model for an item."""

    id: int

    model_config = {"from_attributes": True}
```

---

## Testing FastAPI with TestClient

```python
"""Integration tests for items router."""

import pytest
from fastapi.testclient import TestClient

from my_api.main import create_app
from my_api.config import Settings


@pytest.fixture
def client() -> TestClient:
    """Provide a synchronous test client with test settings."""
    settings = Settings(database_url="sqlite:///./test.db", secret_key="test-secret")
    app = create_app(settings)
    return TestClient(app)


def test_list_items_empty(client: TestClient) -> None:
    """GET /items should return empty list when no items exist."""
    response = client.get("/api/v1/items/")
    assert response.status_code == 200
    assert response.json() == []


def test_create_and_retrieve_item(client: TestClient) -> None:
    """POST then GET should return the created item."""
    payload = {"name": "Widget", "value": 9.99}
    create_resp = client.post("/api/v1/items/", json=payload)
    assert create_resp.status_code == 201
    item_id = create_resp.json()["id"]

    get_resp = client.get(f"/api/v1/items/{item_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["name"] == "Widget"


def test_get_nonexistent_item_returns_404(client: TestClient) -> None:
    """GET /items/{id} with unknown id should return 404."""
    response = client.get("/api/v1/items/99999")
    assert response.status_code == 404
```

---

## Running Locally

```bash
# Development server with auto-reload
uvicorn my_api.main:app --reload --host 0.0.0.0 --port 8000

# Production server
uvicorn my_api.main:app --workers 4 --host 0.0.0.0 --port 8000
```

---

## Environment File (`.env.example`)

```dotenv
APP_NAME=My API
VERSION=0.1.0
DEBUG=false
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/mydb
SECRET_KEY=change-me-in-production
ALLOWED_ORIGINS=["http://localhost:3000","https://myapp.example.com"]
```

---

## Security Checklist

- [ ] All secrets in `.env` (never in source code)
- [ ] `.env` in `.gitignore`
- [ ] Input validated via Pydantic models
- [ ] Authentication enforced on protected routes (OAuth2 / API key)
- [ ] HTTPS in production (TLS termination at load balancer or reverse proxy)
- [ ] Rate limiting configured
- [ ] SQL queries use ORM or parameterized statements
- [ ] CORS `allow_origins` locked down (not `["*"]`) in production

---

## See Also

- [`skills/web-development.md`](../skills/web-development.md) — detailed patterns
- [`skills/python-testing.md`](../skills/python-testing.md) — testing cookbook
- [`templates/pyproject.toml`](../templates/pyproject.toml) — starter config
