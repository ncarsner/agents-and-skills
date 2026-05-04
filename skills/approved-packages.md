# Approved Packages — Preferred Libraries by Category

This document lists approved and preferred packages for use in all code
projects governed by these agent instructions. Agents MUST prefer packages
from this list over arbitrary third-party alternatives.

**Legend**

| Symbol | Meaning |
|--------|---------|
| ★ | First choice — prefer this over alternatives in the same cell |
| stdlib | Python standard library — no installation required |
| — | No strong preference; choose based on project requirements |

---

## 1. Python Standard Library (Always Prefer Over Third-Party)

Use these stdlib modules before reaching for a third-party package.

| Purpose | Module |
|---------|--------|
| File and path handling | `pathlib.Path` ★ |
| Enumeration / named constants | `enum.Enum`, `enum.IntEnum`, `enum.StrEnum` |
| Data classes | `dataclasses.dataclass` |
| Abstract base classes | `abc.ABC`, `abc.abstractmethod` |
| Type hints | `typing`, `collections.abc` |
| Async I/O | `asyncio` |
| Logging | `logging` |
| Date and time | `datetime`, `zoneinfo` |
| JSON serialization | `json` |
| CSV handling | `csv` |
| Regular expressions | `re` |
| Argument parsing | `argparse` |
| Unit testing | `unittest`, `unittest.mock` |
| Context managers | `contextlib` |
| Itertools / functools | `itertools`, `functools` |
| Configuration files | `configparser`, `tomllib` (3.11+) |
| OS interaction | `os`, `sys`, `shutil` (use `pathlib` for paths) |
| Temporary files | `tempfile` |
| Threading / multiprocessing | `threading`, `multiprocessing`, `concurrent.futures` |
| URL parsing | `urllib.parse` |
| Base64 / hashing | `hashlib`, `hmac`, `base64`, `secrets` |
| Decimal arithmetic | `decimal.Decimal` |
| Fraction arithmetic | `fractions.Fraction` |

---

## 2. Data Analysis and Manipulation

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Tabular data (large/complex) | `pandas` ★ | `polars` |
| High-performance / lazy eval | `polars` ★ | `pandas` |
| Numerical / array computing | `numpy` ★ | — |
| Statistical functions | `scipy.stats` ★ | `statsmodels` |
| Data validation & parsing | `pydantic` ★ | `marshmallow`, `attrs` |
| Arrow / columnar format | `pyarrow` ★ | — |
| Excel read/write | `openpyxl` ★ | `xlsxwriter` |
| CSV / tabular parsing | stdlib `csv` ★ | `pandas.read_csv` |
| Date/time utilities | stdlib `datetime` + `zoneinfo` ★ | `arrow` |

---

## 3. Scientific Computing and Mathematics

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Linear algebra, FFT, optimization | `scipy` ★ | — |
| Symbolic mathematics | `sympy` ★ | — |
| Numerical arrays | `numpy` ★ | — |
| Unit-aware quantities | `pint` | — |
| Statistics / econometrics | `statsmodels` ★ | `scipy.stats` |

---

## 4. Machine Learning and AI

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Classical ML (classification, regression, clustering) | `scikit-learn` ★ | — |
| Gradient boosting | `xgboost` ★ | `lightgbm`, `catboost` |
| Deep learning (research / general) | `pytorch` (`torch`) ★ | `tensorflow`, `jax` |
| Deep learning (production / inference) | `tensorflow` ★ | `torch` |
| Large language model APIs | `anthrophic` ★ | `openai`, `gemini` |
| Embeddings and transformers | `sentence-transformers` ★ | `transformers` |
| Hugging Face ecosystem | `transformers` ★ | — |
| Model evaluation metrics | `scikit-learn.metrics` ★ | — |
| Hyperparameter tuning | `optuna` ★ | `hyperopt` |
| Experiment tracking | `mlflow` ★ | `wandb` |
| Data pipelines for ML | `scikit-learn.pipeline` ★ | `feature-engine` |

---

## 5. Natural Language Processing

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Production NLP pipelines | `spacy` ★ | `stanza` |
| Classical NLP / research | `nltk` ★ | `spacy` |
| Transformer-based NLP | `transformers` (Hugging Face) ★ | — |
| Tokenization | `tiktoken` ★ | `tokenizers` |
| Text similarity / embeddings | `sentence-transformers` ★ | — |
| Fuzzy string matching | `rapidfuzz` ★ | `fuzzywuzzy` |
| Keyword / phrase extraction | `keybert` | `yake` |

---

## 6. Web Development (Backend)

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Full-featured web framework | `django` ★ | `flask` |
| Lightweight / microservices | `flask` ★ | `django` |
| Async API framework | `fastapi` ★ | `litestar` |
| ASGI server | `uvicorn` ★ | `gunicorn` + `uvicorn` worker |
| WSGI server (production) | `gunicorn` ★ | `waitress` |
| HTTP client (sync + async) | `httpx` ★ | `requests` |
| HTTP client (sync only) | `requests` ★ | `urllib3` |
| WebSockets | `websockets` ★ | `channels` (Django) |
| Form validation (Django) | `django.forms` ★ | `wtforms` |
| REST serialization (Django) | `djangorestframework` ★ | — |
| Schema / OpenAPI docs | `fastapi` built-in ★ | `spectree` |
| Rate limiting | `slowapi` (FastAPI) ★ | `django-ratelimit` |
| Background tasks (simple) | `fastapi.BackgroundTasks` ★ | `huey` |

---

## 7. Frontend / CSS (when generating or serving HTML)

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Utility-first CSS | `TailwindCSS` ★ | `Bootstrap` |
| Component CSS framework | `Bootstrap` ★ | `Bulma` |
| HTML templating (Python) | `jinja2` ★ | `mako` |
| Python-driven UI (reactive) | `dash` ★ | `streamlit`, `panel` |
| Rapid data app UI | `streamlit` ★ | `dash`, `gradio` |

---

## 8. Databases and ORMs

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| SQL ORM (sync) | `sqlalchemy` (2.x) ★ | `peewee` |
| SQL ORM (async) | `sqlalchemy` + `asyncpg` ★ | `tortoise-orm` |
| PostgreSQL driver (sync) | `psycopg2-binary` ★ | `pg8000` |
| PostgreSQL driver (async) | `asyncpg` ★ | `psycopg3` |
| SQLite (stdlib) | stdlib `sqlite3` ★ | — |
| MySQL / MariaDB | `mysqlclient` ★ | `pymysql` |
| Database migrations | `alembic` ★ | `django.db.migrations` |
| Redis client | `redis` (redis-py) ★ | `aioredis` (merged into redis-py) |
| MongoDB client | `pymongo` ★ | `motor` (async) |
| Elasticsearch client | `elasticsearch` (official) ★ | — |
| In-process analytics DB | `duckdb` ★ | — |
| Object storage / caching | `diskcache` ★ | `joblib.Memory` |

---

## 9. Configuration and Environment Management

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Environment variables | stdlib `os.environ` ★ | — |
| `.env` file loading | `python-dotenv` ★ | — |
| Settings / config models | `pydantic-settings` ★ | `dynaconf` |
| TOML config parsing | stdlib `tomllib` (3.11+) ★ | `tomli` (< 3.11) |
| YAML config parsing | `pyyaml` ★ | `ruamel.yaml` |
| INI / config file parsing | stdlib `configparser` ★ | — |

---

## 10. Data Validation and Serialization

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Schema validation / models | `pydantic` (v2) ★ | `attrs`, `marshmallow` |
| JSON serialization (fast) | `orjson` ★ | stdlib `json`, `ujson` |
| MessagePack serialization | `msgpack` ★ | — |
| YAML serialization | `pyyaml` ★ | `ruamel.yaml` |
| CSV validation | `pydantic` + stdlib `csv` ★ | `cerberus` |
| Schema-first API contracts | `pydantic` ★ | `dataclasses` |

---

## 11. Testing and Quality Assurance

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Test runner | `pytest` ★ | `unittest` (stdlib) |
| Code coverage | `pytest-cov` ★ | `coverage` |
| Mocking | `unittest.mock` (stdlib) ★ | `pytest-mock` |
| HTTP mocking | `responses` ★ | `httpretty`, `respx` (async) |
| Async test support | `pytest-asyncio` ★ | `anyio` pytest plugin |
| Factory / fixture data | `factory-boy` ★ | `faker` |
| Fake data generation | `faker` ★ | `mimesis` |
| Property-based testing | `hypothesis` ★ | — |
| Snapshot testing | `syrupy` ★ | — |
| Load / performance testing | `locust` ★ | `k6` |
| Mutation testing | `mutmut` ★ | `cosmic-ray` |

---

## 12. Linting, Formatting, and Type Checking

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Linter + formatter | `ruff` ★ | `flake8` + `black` |
| Static type checker | `mypy` ★ | `pyright`, `pytype` |
| Security linter | `bandit` ★ | `semgrep` |
| Pre-commit hooks | `pre-commit` ★ | — |
| Import sorting | `ruff` (isort rules) ★ | `isort` |
| Dead code detection | `vulture` ★ | — |
| Complexity checker | `complexipy` ★ | `mccabe` |

---

## 13. CLI Development

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Argument parsing (simple) | stdlib `argparse` ★ | — |
| Rich CLI with types | `click` ★ | `typer` |
| Modern CLI with type hints | `typer` ★ | `click` |
| Terminal UI / TUI | `rich` ★ | `textual`, `blessed` |
| Interactive prompts | `questionary` ★ | `prompt-toolkit` |
| Progress bars | `rich` ★ | `tqdm` |
| Colored terminal output | `rich` ★ | `colorama` |
| Shell completion | `click` built-in ★ | `argcomplete` |
| Pager / less-style output | `rich.pager` ★ | stdlib `pydoc.pager` |

---

## 14. Logging and Observability

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Application logging | stdlib `logging` ★ | — |
| Structured (JSON) logging | `structlog` ★ | `loguru` |
| Human-friendly logging | `loguru` ★ | `structlog` |
| Distributed tracing | `opentelemetry-sdk` ★ | `jaeger-client` |
| Metrics / instrumentation | `prometheus-client` ★ | `statsd` |
| Error tracking (cloud) | `sentry-sdk` ★ | `rollbar` |
| Performance profiling | `pyinstrument` ★ | `cProfile` (stdlib) |
| Memory profiling | `memray` ★ | `tracemalloc` (stdlib) |

---

## 15. Async and Concurrency

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Async I/O runtime | stdlib `asyncio` ★ | — |
| Structured concurrency | `anyio` ★ | `trio` |
| Async HTTP client | `httpx` ★ | `aiohttp` |
| Async database (Postgres) | `asyncpg` ★ | `databases` |
| Async task queue | `celery` ★ | `arq`, `rq` |
| Scheduled tasks | `apscheduler` ★ | `celery beat` |
| Thread pool helpers | stdlib `concurrent.futures` ★ | — |
| Async Redis | `redis.asyncio` (redis-py) ★ | — |

---

## 16. Security and Authentication

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Password hashing | `passlib` (bcrypt backend) ★ | `argon2-cffi` |
| JWT tokens | `python-jose` ★ | `PyJWT` |
| OAuth2 / OIDC | `authlib` ★ | `social-auth-app-django` |
| Cryptographic primitives | `cryptography` ★ | `pycryptodome` |
| TLS / certificate handling | `truststore` ★ | stdlib `ssl` |
| Secrets generation | stdlib `secrets` ★ | — |
| Input sanitization (HTML) | `bleach` ★ | `MarkupSafe` |
| CSRF protection | `django-csrf` (built-in) ★ | `wtforms` CSRF |
| API key management | `pydantic-settings` + `python-dotenv` ★ | — |

---

## 17. HTTP and API Integration

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| HTTP client (sync + async) | `httpx` ★ | `requests` |
| HTTP client (sync only) | `requests` ★ | `urllib3` |
| Retry / backoff | `tenacity` ★ | `backoff` |
| Rate limiting (client-side) | `ratelimit` ★ | `throttler` |
| GraphQL client | `gql` ★ | `sgqlc` |
| REST API mocking (tests) | `responses` ★ | `httpretty` |
| WebSocket client | `websockets` ★ | `websocket-client` |
| gRPC | `grpcio` + `grpcio-tools` ★ | — |

---

## 18. Data Visualization and Dashboards

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Static plots (publication) | `matplotlib` ★ | — |
| Statistical plots | `seaborn` ★ | `plotnine` |
| Interactive plots | `plotly` ★ | `bokeh`, `altair` |
| Grammar-of-graphics (Python) | `plotnine` ★ | `altair` |
| Declarative / Vega-Lite | `altair` ★ | `plotly` |
| Interactive web dashboard | `dash` ★ | `streamlit`, `panel` |
| Rapid prototype UI | `streamlit` ★ | `dash` |
| Report generation (PDF) | `reportlab` ★ | `weasyprint` |
| HTML-to-PDF | `weasyprint` ★ | `pdfkit` |
| Excel charts | `openpyxl` ★ | `xlsxwriter` |

---

## 19. File Formats and I/O

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| CSV | stdlib `csv` ★ | `pandas.read_csv` |
| JSON | stdlib `json` ★ | `orjson` (performance) |
| TOML | stdlib `tomllib` (3.11+) ★ | `tomli` |
| YAML | `pyyaml` ★ | `ruamel.yaml` |
| Excel | `openpyxl` ★ | `xlsxwriter` |
| Parquet / Arrow | `pyarrow` ★ | `fastparquet` |
| PDF reading | `pypdf` ★ | `pdfminer.six` |
| PDF generation | `reportlab` ★ | `fpdf2` |
| DOCX / Word | `python-docx` ★ | — |
| ZIP / TAR archives | stdlib `zipfile`, `tarfile` ★ | — |
| Image I/O | `pillow` ★ | `imageio` |

---

## 20. Cloud and Infrastructure

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| AWS SDK | `boto3` ★ | — |
| Azure SDK | `azure-sdk-for-python` (per service) ★ | — |
| Google Cloud SDK | `google-cloud-*` (per service) ★ | — |
| Infrastructure as code (Python) | `pulumi` ★ | `cdktf` |
| Container interaction | `docker` (docker-py) ★ | — |
| SSH / remote execution | `paramiko` ★ | `fabric` |
| Secret stores | `hvac` (HashiCorp Vault) ★ | `boto3` SSM Parameter Store |
| Object storage abstraction | `fsspec` ★ | `smart-open` |

---

## 21. Scheduling and Task Queues

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Distributed task queue | `celery` ★ | `dramatiq`, `rq` |
| Lightweight task queue | `rq` ★ | `huey` |
| Async task queue | `arq` ★ | `celery` (async) |
| Scheduled jobs | `apscheduler` ★ | `celery beat`, `schedule` |
| Simple in-process scheduler | `schedule` ★ | stdlib `sched` |

---

## 22. Documentation

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Static site / docs | `mkdocs` + `mkdocs-material` ★ | `sphinx` |
| API reference docs | `sphinx` ★ | `mkdocstrings` |
| Docstring format | Google style ★ | NumPy style |
| Changelog management | `towncrier` ★ | manual `CHANGELOG.md` |
| README badges | Shields.io ★ | — |

---

## 23. Package and Dependency Management

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Package manager | `uv` ★ | `pip`, `poetry` |
| Virtual environments | `uv venv` ★ | `venv` (stdlib) |
| Dependency file | `pyproject.toml` ★ | `requirements.txt` |
| Lock file | `uv.lock` ★ | `poetry.lock` |
| Version pinning | `uv lock` ★ | `pip-compile` |
| Semantic versioning | `semver` ★ | stdlib `packaging.version` |
| Build backend | `hatchling` ★ | `setuptools`, `flit` |

---

## 24. Dev Tooling and CI/CD

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Pre-commit hooks | `pre-commit` ★ | — |
| CI/CD platform | GitHub Actions ★ | GitLab CI |
| Docker base image | `python:3.13-slim` ★ | `python:3.13-alpine` |
| Environment variable injection | GitHub Secrets ★ | `.env` (local only) |
| Code coverage service | `codecov` ★ | `coveralls` |
| Dependency vulnerability scanning | `pip-audit` ★ | `safety` |

---

## 25. Geospatial

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| Vector geospatial data | `geopandas` ★ | `shapely` |
| Geometry operations | `shapely` ★ | — |
| Coordinate transforms | `pyproj` ★ | — |
| Interactive geospatial maps | `folium` ★ | `keplergl` |
| Raster / satellite data | `rasterio` ★ | `gdal` |

---

## 26. Networking and Protocols

| Purpose | Preferred | Alternatives |
|---------|-----------|--------------|
| DNS resolution | stdlib `socket` ★ | `dnspython` |
| Email sending | `sendgrid` ★ | `smtplib` (stdlib) |
| Email parsing | stdlib `email` ★ | — |
| SFTP / FTP | `paramiko` ★ | stdlib `ftplib` |
| MQTT | `paho-mqtt` ★ | — |
| Kafka | `confluent-kafka` ★ | `kafka-python` |

---

## Evaluation Criteria for Adding New Packages

Before adding any package not listed here, verify all of the following:

1. **Maturity** — The library must have a stable release (not pre-1.0 or an
   initial release within the past month).
2. **Maintenance** — The project must have been actively maintained within the
   past 12 months (check GitHub commits or PyPI release history).
3. **Adoption** — The library must have meaningful adoption (e.g., >1000
   GitHub stars or >10000 monthly PyPI downloads).
4. **Security** — No unpatched critical CVEs. Run `pip-audit` before adding.
5. **License** — Must be permissive (MIT, Apache-2.0, BSD). Avoid GPL unless
   the project itself is GPL-licensed.
6. **Overlap** — If an approved package already covers the need, use it instead
   of adding a new dependency.

If all criteria are satisfied, add the package to this file in the appropriate
category with a brief justification comment in the PR.
