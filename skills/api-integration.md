# Skill: API Integration

Patterns for building HTTP API clients in Python. Covers synchronous and
asynchronous requests, authentication, retry logic, pagination, and testing.

---

## Quick Reference

```bash
uv add httpx                    # recommended HTTP client (sync + async)
uv add tenacity                 # retry logic
uv add pydantic                 # response model validation
```

---

## Recommended Library: httpx

`httpx` is the default HTTP client for all new code. It supports:

- Synchronous and async interfaces with identical APIs
- HTTP/1.1 and HTTP/2
- Connection pooling via `Client`/`AsyncClient`
- Built-in timeout, redirect, and proxy support

---

## Synchronous Client Pattern

```python
"""Synchronous REST API client with connection pooling."""

import logging
from typing import Any

import httpx
from pydantic import BaseModel

logger = logging.getLogger(__name__)

BASE_URL = "https://api.example.com/v1"
DEFAULT_TIMEOUT = 10.0


class ApiClient:
    """Thread-safe synchronous HTTP client for the Example API."""

    def __init__(self, api_key: str, *, base_url: str = BASE_URL) -> None:
        self._client = httpx.Client(
            base_url=base_url,
            headers={"Authorization": f"Bearer {api_key}", "Accept": "application/json"},
            timeout=DEFAULT_TIMEOUT,
        )

    def __enter__(self) -> "ApiClient":
        return self

    def __exit__(self, *args: object) -> None:
        self.close()

    def close(self) -> None:
        """Release underlying HTTP connections."""
        self._client.close()

    def get(self, path: str, *, params: dict[str, Any] | None = None) -> dict:
        """Perform a GET request and return the parsed JSON body.

        Args:
            path: URL path relative to base_url.
            params: Optional query parameters.

        Returns:
            Parsed JSON response.

        Raises:
            httpx.HTTPStatusError: On non-2xx response.
        """
        logger.debug("GET %s params=%s", path, params)
        response = self._client.get(path, params=params)
        response.raise_for_status()
        return response.json()

    def post(self, path: str, payload: dict) -> dict:
        """Perform a POST request with a JSON payload.

        Args:
            path: URL path relative to base_url.
            payload: Request body (will be JSON-encoded).

        Returns:
            Parsed JSON response.

        Raises:
            httpx.HTTPStatusError: On non-2xx response.
        """
        logger.debug("POST %s payload=%s", path, payload)
        response = self._client.post(path, json=payload)
        response.raise_for_status()
        return response.json()
```

---

## Async Client Pattern

```python
"""Async REST API client for use in async contexts (FastAPI, asyncio)."""

import logging
from typing import Any

import httpx

logger = logging.getLogger(__name__)


class AsyncApiClient:
    """Async HTTP client for the Example API."""

    def __init__(self, api_key: str, *, base_url: str = "https://api.example.com/v1") -> None:
        self._client = httpx.AsyncClient(
            base_url=base_url,
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=10.0,
        )

    async def __aenter__(self) -> "AsyncApiClient":
        return self

    async def __aexit__(self, *args: object) -> None:
        await self.close()

    async def close(self) -> None:
        """Release underlying async connections."""
        await self._client.aclose()

    async def get(self, path: str, *, params: dict[str, Any] | None = None) -> dict:
        """Async GET request."""
        response = await self._client.get(path, params=params)
        response.raise_for_status()
        return response.json()
```

---

## Retry Pattern (Tenacity)

```python
"""Retry HTTP calls on transient errors with exponential backoff."""

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
    before_sleep_log,
)
import logging

logger = logging.getLogger(__name__)

RETRYABLE = (httpx.TimeoutException, httpx.NetworkError, httpx.RemoteProtocolError)


@retry(
    retry=retry_if_exception_type(RETRYABLE),
    wait=wait_exponential(multiplier=1, min=2, max=30),
    stop=stop_after_attempt(5),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    reraise=True,
)
def get_with_retry(client: httpx.Client, url: str) -> dict:
    """GET a URL with automatic retry on transient network errors.

    Args:
        client: An open httpx.Client instance.
        url: The URL to fetch.

    Returns:
        Parsed JSON response.

    Raises:
        httpx.HTTPStatusError: On non-retryable 4xx/5xx response.
        httpx.TimeoutException: After all retry attempts are exhausted.
    """
    response = client.get(url)
    response.raise_for_status()
    return response.json()
```

---

## Response Validation Pattern (Pydantic)

```python
"""Parse and validate API responses into typed Pydantic models."""

from pydantic import BaseModel, HttpUrl


class Repository(BaseModel):
    """GitHub repository response model."""

    id: int
    name: str
    full_name: str
    private: bool
    html_url: HttpUrl
    description: str | None = None
    stargazers_count: int = 0
    forks_count: int = 0


def parse_repository(data: dict) -> Repository:
    """Parse a raw API response dict into a validated Repository model.

    Args:
        data: Raw JSON dict from the GitHub API.

    Returns:
        Validated Repository instance.

    Raises:
        pydantic.ValidationError: If required fields are missing or invalid.
    """
    return Repository.model_validate(data)
```

---

## Pagination Pattern

```python
"""Cursor- and page-based pagination helpers."""

from collections.abc import Generator
from typing import Any

import httpx


def paginate_cursor(
    client: httpx.Client,
    url: str,
    *,
    cursor_key: str = "next_cursor",
    items_key: str = "items",
) -> Generator[dict, None, None]:
    """Yield items from a cursor-paginated API endpoint.

    Args:
        client: Open httpx.Client instance.
        url: Initial page URL.
        cursor_key: Response field containing the next page cursor.
        items_key: Response field containing the list of items.

    Yields:
        Individual item dicts from each page.
    """
    params: dict[str, Any] = {}
    while True:
        response = client.get(url, params=params)
        response.raise_for_status()
        data = response.json()

        for item in data.get(items_key, []):
            yield item

        cursor = data.get(cursor_key)
        if not cursor:
            break
        params = {"cursor": cursor}


def paginate_offset(
    client: httpx.Client,
    url: str,
    *,
    page_size: int = 100,
    page_param: str = "page",
    size_param: str = "per_page",
    items_key: str = "results",
) -> Generator[dict, None, None]:
    """Yield items from an offset/page-number paginated endpoint.

    Args:
        client: Open httpx.Client instance.
        url: Base URL for the endpoint.
        page_size: Number of items to request per page.
        page_param: Name of the page number query parameter.
        size_param: Name of the page size query parameter.
        items_key: Response field containing the list of items.

    Yields:
        Individual item dicts from each page.
    """
    page = 1
    while True:
        response = client.get(url, params={page_param: page, size_param: page_size})
        response.raise_for_status()
        items = response.json().get(items_key, [])
        if not items:
            break
        yield from items
        if len(items) < page_size:
            break
        page += 1
```

---

## Testing API Clients

```python
"""Tests for the API client using httpx's MockTransport."""

import httpx
import pytest
from pytest_httpx import HTTPXMock  # uv add pytest-httpx

from my_app.api_client import ApiClient


def test_get_returns_parsed_json(httpx_mock: HTTPXMock) -> None:
    """GET /items should return parsed JSON on 200 response."""
    httpx_mock.add_response(url="https://api.example.com/v1/items", json={"items": []})

    with ApiClient(api_key="test-key") as client:
        result = client.get("/items")

    assert result == {"items": []}


def test_get_raises_on_404(httpx_mock: HTTPXMock) -> None:
    """GET with 404 should raise httpx.HTTPStatusError."""
    httpx_mock.add_response(
        url="https://api.example.com/v1/missing",
        status_code=404,
    )

    with ApiClient(api_key="test-key") as client:
        with pytest.raises(httpx.HTTPStatusError):
            client.get("/missing")
```

---

## Authentication Methods Reference

| Method | Implementation |
|--------|---------------|
| Bearer token | `headers={"Authorization": f"Bearer {token}"}` |
| API key (header) | `headers={"X-API-Key": api_key}` |
| Basic auth | `auth=httpx.BasicAuth(username, password)` |
| OAuth2 client credentials | Use `httpx-oauth` or implement token refresh manually |

Always load credentials from environment variables — never hard-code them.

---

## See Also

- [`agents/data-engineering-agent.md`](../agents/data-engineering-agent.md) — ingestion patterns
- [`agents/security-agent.md`](../agents/security-agent.md) — credential safety
- [`skills/error-handling.md`](error-handling.md) — retry and exception patterns
- [`skills/configuration-management.md`](configuration-management.md) — loading API keys
