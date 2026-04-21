# Accounting Agent Instructions

This file extends `AGENTS.md` with instructions specific to monitoring and
reporting on AI token consumption and associated cost. Read root `AGENTS.md`
first.

---

## Purpose

The accounting agent tracks, aggregates, and reports token usage and inferred
cost across all agent interactions. Responsibilities include:

- Recording prompt token and completion token counts per agent invocation
- Mapping token counts to cost estimates using configurable rate tables
- Aggregating usage by agent, task, project, and time window
- Generating human-readable usage and cost reports
- Alerting when consumption exceeds configured budget thresholds
- Exporting usage data to CSV or JSON for downstream analysis

---

## Scope

This agent operates on:

- Usage log files written by other agents (see Logging Contract below)
- The rate configuration file (`config/token_rates.toml`)
- The budget configuration file (`config/budgets.toml`)
- Report output directory (`reports/usage/`)

This agent does not read or modify application source code.

---

## Logging Contract

Every agent MUST emit a structured log entry for each invocation. The entry
must be written to `logs/usage.jsonl` (newline-delimited JSON). Fields:

```json
{
  "timestamp": "2025-09-01T14:23:00Z",
  "agent": "security-agent",
  "task_id": "pr-review-42",
  "model": "gpt-4o",
  "prompt_tokens": 1240,
  "completion_tokens": 380,
  "total_tokens": 1620
}
```

Rules:
- All fields are required; omit none.
- `task_id` must match the task identifier assigned by the orchestrator.
- Agents that cannot write to `logs/usage.jsonl` must surface the failure
  and halt rather than silently drop the record.

---

## Rate Configuration

Rates are defined in `config/token_rates.toml`. Format:

```toml
[models.gpt-4o]
prompt_per_1k  = 0.005   # USD per 1 000 prompt tokens
completion_per_1k = 0.015 # USD per 1 000 completion tokens

[models.gpt-4o-mini]
prompt_per_1k  = 0.00015
completion_per_1k = 0.00060

[models.claude-3-5-sonnet]
prompt_per_1k  = 0.003
completion_per_1k = 0.015
```

- Add a new `[models.<name>]` block for each model in use.
- Do not hard-code rates in source code; always read from this file.
- If a model is not listed, log a warning and use a sentinel cost of -1 to
  flag the entry for manual review.

---

## Budget Configuration

Budget thresholds are defined in `config/budgets.toml`. Format:

```toml
[budgets]
daily_usd   = 10.00
weekly_usd  = 50.00
monthly_usd = 150.00

[alerts]
warn_at_pct  = 80   # warn when usage reaches this % of budget
block_at_pct = 100  # refuse new tasks when this % is reached
```

---

## Cost Calculation Pattern

```python
"""Token cost calculation from usage log entries."""

from decimal import Decimal
from pathlib import Path

import tomllib


def load_rates(config_path: Path) -> dict[str, dict[str, Decimal]]:
    """Load per-model token rates from TOML config.

    Args:
        config_path: Path to token_rates.toml.

    Returns:
        Mapping of model name to prompt/completion rate in USD per 1 000 tokens.
    """
    with config_path.open("rb") as fh:
        raw = tomllib.load(fh)
    return {
        model: {
            "prompt": Decimal(str(rates["prompt_per_1k"])),
            "completion": Decimal(str(rates["completion_per_1k"])),
        }
        for model, rates in raw.get("models", {}).items()
    }


def calculate_cost(
    prompt_tokens: int,
    completion_tokens: int,
    model: str,
    rates: dict[str, dict[str, Decimal]],
) -> Decimal:
    """Calculate USD cost for a single invocation.

    Args:
        prompt_tokens: Number of prompt tokens consumed.
        completion_tokens: Number of completion tokens consumed.
        model: Model identifier matching a key in rates.
        rates: Rate table returned by load_rates().

    Returns:
        Total cost in USD as a Decimal.

    Raises:
        KeyError: If model is not present in the rate table.
    """
    if model not in rates:
        raise KeyError(f"No rate configured for model: {model!r}")
    r = rates[model]
    prompt_cost = r["prompt"] * Decimal(prompt_tokens) / Decimal(1000)
    completion_cost = r["completion"] * Decimal(completion_tokens) / Decimal(1000)
    return prompt_cost + completion_cost
```

Always use `decimal.Decimal` for monetary arithmetic. Never use `float`.

---

## Aggregation and Reporting Pattern

```python
"""Aggregate usage log and produce a cost summary."""

import json
from collections import defaultdict
from datetime import date, datetime, timezone
from decimal import Decimal
from pathlib import Path


def aggregate_usage(
    log_path: Path,
    rates: dict[str, dict[str, Decimal]],
    since: date | None = None,
) -> dict[str, dict[str, Decimal]]:
    """Read usage.jsonl and return cost totals grouped by agent.

    Args:
        log_path: Path to usage.jsonl.
        rates: Rate table from load_rates().
        since: If provided, include only entries on or after this date.

    Returns:
        Mapping of agent name to totals: tokens and cost_usd.
    """
    totals: dict[str, dict[str, Decimal]] = defaultdict(
        lambda: {"prompt_tokens": Decimal(0),
                 "completion_tokens": Decimal(0),
                 "cost_usd": Decimal(0)}
    )
    with log_path.open() as fh:
        for line in fh:
            entry = json.loads(line)
            entry_date = datetime.fromisoformat(
                entry["timestamp"].replace("Z", "+00:00")
            ).astimezone(timezone.utc).date()
            if since and entry_date < since:
                continue
            agent = entry["agent"]
            cost = calculate_cost(
                entry["prompt_tokens"],
                entry["completion_tokens"],
                entry["model"],
                rates,
            )
            totals[agent]["prompt_tokens"] += Decimal(entry["prompt_tokens"])
            totals[agent]["completion_tokens"] += Decimal(entry["completion_tokens"])
            totals[agent]["cost_usd"] += cost
    return dict(totals)
```

---

## Budget Alert Logic

When the accounting agent runs, it must:

1. Compute total spend for the current day, week, and month.
2. Compare each total against the thresholds in `config/budgets.toml`.
3. If spend reaches `warn_at_pct`, emit a WARNING log entry and include an
   alert block in the usage report.
4. If spend reaches `block_at_pct`, emit an ERROR log entry, write an alert
   to `logs/budget_exceeded.log`, and refuse to process further tasks until
   a human acknowledges the breach.

---

## Report Output Format

Reports are written to `reports/usage/<YYYY-MM-DD>_usage_report.txt`.

```
Usage Report — 2025-09-15
Period: 2025-09-15 00:00 UTC to 2025-09-15 23:59 UTC

Agent                  Prompt Tokens  Completion Tokens  Cost (USD)
---------------------  -------------  -----------------  ----------
security-agent                12 400              3 820       $0.119
testing-agent                  8 100              2 210       $0.074
data-engineering-agent         5 500              1 900       $0.057
---------------------  -------------  -----------------  ----------
TOTAL                         26 000              7 930       $0.250

Budget status (daily limit $10.00): 2.5% used — OK
```

Rules:
- Use plain-text table formatting with spaces (no markdown pipes).
- Align numbers right; align labels left.
- Express costs to three decimal places in USD.
- Always include a budget-status line at the bottom.

---

## See Also

- [`skills/logging-observability.md`](../skills/logging-observability.md) — structured logging
- [`skills/configuration-management.md`](../skills/configuration-management.md) — TOML config loading
- [`skills/error-handling.md`](../skills/error-handling.md) — handling missing config or malformed log entries
