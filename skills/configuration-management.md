# Skill: Configuration Management

Patterns for loading, validating, and distributing application configuration
in Python. Covers environment variables, TOML files, and Pydantic-based settings.

---

## Quick Reference

```bash
uv add python-dotenv           # load .env files into os.environ
uv add pydantic-settings       # type-safe settings from env vars + .env
```

The rule is simple:

| Type | Source |
|------|--------|
| **Secrets** (passwords, keys, tokens) | Environment variables only — never files |
| **Parameters** (timeouts, paths, feature flags) | TOML file (committed) or env vars |
| **Defaults** | Hard-coded in the settings class/dataclass |

---

## Pydantic Settings (Recommended for Services)

`pydantic-settings` reads from environment variables and optionally from `.env`
files, with full type coercion and validation.

```python
"""Application settings using pydantic-settings."""

from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration loaded from environment variables.

    All settings can be overridden by setting the corresponding
    environment variable (case-insensitive).
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",  # silently ignore unrecognized env vars
    )

    # --- Application ---
    app_name: str = "my-app"
    version: str = "0.1.0"
    debug: bool = False
    log_level: str = Field(default="INFO", pattern="^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$")

    # --- Database ---
    database_url: str  # required; no default; must be set in environment

    # --- External APIs ---
    api_key: str  # required; no default

    # --- Pipeline ---
    batch_size: int = Field(default=1000, gt=0)
    output_dir: Path = Path("output")
    request_timeout_seconds: float = Field(default=10.0, gt=0)

    @field_validator("output_dir", mode="before")
    @classmethod
    def coerce_path(cls, v: object) -> Path:
        """Accept string or Path for output_dir."""
        return Path(str(v))


# Module-level singleton — import this in other modules
_settings: Settings | None = None


def get_settings() -> Settings:
    """Return the application settings singleton.

    Loads from environment on first call; cached thereafter.
    """
    global _settings
    if _settings is None:
        _settings = Settings()
    return _settings
```

Usage in application code:

```python
from my_app.config import get_settings

settings = get_settings()
print(settings.batch_size)   # 1000
print(settings.output_dir)   # Path('output')
```

---

## TOML Configuration (For Pipeline Parameters)

For non-secret parameters that benefit from file-based configuration with
comments and structure, use TOML (stdlib `tomllib` in Python 3.11+).

```toml
# config/settings.toml

[pipeline]
source_path = "data/raw/orders.csv"
output_path = "data/processed/orders_clean.csv"
batch_size = 500

[pipeline.column_renames]
"Order ID"  = "order_id"
"Unit Price" = "unit_price"

[notifications]
enabled = true
recipients = ["ops@example.com", "data@example.com"]
smtp_host = "smtp.example.com"
smtp_port = 587
```

```python
"""TOML configuration loader."""

import tomllib
from pathlib import Path
from typing import Any


DEFAULT_CONFIG_PATH = Path("config/settings.toml")


def load_config(path: Path = DEFAULT_CONFIG_PATH) -> dict[str, Any]:
    """Load a TOML configuration file.

    Args:
        path: Path to the .toml config file.

    Returns:
        Parsed configuration as a nested dict.

    Raises:
        FileNotFoundError: If the config file does not exist.
        tomllib.TOMLDecodeError: If the file contains invalid TOML.
    """
    if not path.exists():
        raise FileNotFoundError(
            f"Config file not found: {path}\n"
            f"Copy config/settings.example.toml to {path} and edit it."
        )
    with path.open("rb") as f:
        return tomllib.load(f)


def require(config: dict[str, Any], *keys: str) -> Any:
    """Retrieve a nested config value; raise if any key is absent.

    Args:
        config: Root configuration dict.
        *keys: Path of keys for nested access.

    Returns:
        The value at the specified path.

    Raises:
        KeyError: If any key in the path is missing.

    Example::

        smtp_host = require(config, "notifications", "smtp_host")
    """
    current: Any = config
    breadcrumb: list[str] = []
    for key in keys:
        breadcrumb.append(key)
        if not isinstance(current, dict) or key not in current:
            raise KeyError(f"Missing required config key: {'.'.join(breadcrumb)}")
        current = current[key]
    return current
```

---

## Environment File Templates

### `.env.example` (committed to version control)

```dotenv
# Copy this file to .env and fill in real values.
# NEVER commit .env to version control.

# Database
DATABASE_URL=postgresql+psycopg2://user:password@localhost:5432/mydb

# External API
API_KEY=your-api-key-here

# Application
DEBUG=false
LOG_LEVEL=INFO
BATCH_SIZE=1000
OUTPUT_DIR=output
REQUEST_TIMEOUT_SECONDS=10.0
```

### `.gitignore` entries

```
.env
*.env
.env.*
!.env.example
```

---

## Testing Configuration

```python
"""Tests for configuration loading."""

from pathlib import Path

import pytest

from my_app.config import Settings


def test_settings_load_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Settings should load values from environment variables."""
    monkeypatch.setenv("DATABASE_URL", "sqlite:///:memory:")
    monkeypatch.setenv("API_KEY", "test-key")
    monkeypatch.setenv("BATCH_SIZE", "250")

    settings = Settings()
    assert settings.database_url == "sqlite:///:memory:"
    assert settings.batch_size == 250


def test_settings_raises_on_missing_required(monkeypatch: pytest.MonkeyPatch) -> None:
    """Settings should raise ValidationError when required fields are absent."""
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("API_KEY", raising=False)

    from pydantic import ValidationError
    with pytest.raises(ValidationError):
        Settings()


def test_load_config_raises_on_missing_file(tmp_path: Path) -> None:
    """load_config should raise FileNotFoundError for a missing TOML file."""
    from my_app.config import load_config
    with pytest.raises(FileNotFoundError, match="Config file not found"):
        load_config(tmp_path / "nonexistent.toml")


def test_load_config_parses_valid_toml(tmp_path: Path) -> None:
    """load_config should return a dict for a valid TOML file."""
    toml_file = tmp_path / "settings.toml"
    toml_file.write_text('[pipeline]\nbatch_size = 100\n', encoding="utf-8")

    from my_app.config import load_config
    config = load_config(toml_file)
    assert config["pipeline"]["batch_size"] == 100
```

---

## Decision Guide

| Scenario | Approach |
|----------|---------|
| Secrets (DB password, API key) | `os.environ` / `pydantic-settings` / `.env` |
| Service configuration (ports, feature flags) | `pydantic-settings` with env var overrides |
| Batch pipeline parameters | TOML file (`config/settings.toml`) |
| Developer overrides in testing | `monkeypatch.setenv` in pytest |
| Per-environment overrides (dev/staging/prod) | Environment variables set in CI/CD or container |

---

## See Also

- [`agents/security-agent.md`](../agents/security-agent.md) — secrets management
- [`skills/logging-observability.md`](logging-observability.md) — logging configuration
- [`templates/pyproject.toml`](../templates/pyproject.toml) — project config template
