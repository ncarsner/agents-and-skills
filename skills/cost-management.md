# Skill: LLM/AI API Usage Tracking & Budget Guardrails

How agents that call LLM APIs must estimate, track, and cap token costs.
Covers required logging, environment variable conventions, pre-flight estimation,
alert thresholds, and prompt efficiency patterns.

---

## Environment Variable Conventions

| Variable | Purpose | Example |
|----------|---------|---------|
| `MAX_TOKENS_PER_SESSION` | Hard cap on total tokens consumed per agent session | `100000` |
| `MAX_TOKENS_PER_CALL` | Hard cap on tokens per individual API call | `8000` |
| `LLM_COST_ALERT_THRESHOLD_USD` | Dollar amount that triggers a warning log | `1.00` |
| `LLM_PROVIDER` | Active provider (`anthropic`, `openai`, `gemini`) | `anthropic` |
| `LLM_MODEL` | Model identifier for cost lookups | `claude-sonnet-4-6` |

Load all values via `os.environ` or `python-dotenv`. Never hardcode.

---

## Required Token Logging

Every LLM API call must log the following fields at `INFO` level:

| Field | Description |
|-------|-------------|
| `model` | Model identifier |
| `input_tokens` | Tokens in the prompt |
| `output_tokens` | Tokens in the response |
| `total_tokens` | Sum of input + output |
| `estimated_cost_usd` | Calculated from provider pricing |
| `session_total_tokens` | Running session total after this call |
| `call_id` | UUID4 for the individual call |
| `timestamp` | ISO 8601 UTC |

```python
import logging
import os
import uuid
from datetime import UTC, datetime

logger = logging.getLogger(__name__)

# Approximate pricing (USD per 1M tokens): update as provider pricing changes.
PRICING: dict[str, dict[str, float]] = {
    "claude-opus-4-7": {"input": 15.00, "output": 75.00},
    "claude-sonnet-4-6": {"input": 3.00, "output": 15.00},
    "claude-haiku-4-5": {"input": 0.80, "output": 4.00},
    "gpt-4o": {"input": 5.00, "output": 15.00},
    "gpt-4o-mini": {"input": 0.15, "output": 0.60},
}


def log_api_call(
    model: str,
    input_tokens: int,
    output_tokens: int,
    session_total: int,
) -> float:
    """Log an LLM API call and return the estimated cost in USD.

    Args:
        model: Model identifier string.
        input_tokens: Tokens consumed by the prompt.
        output_tokens: Tokens in the model response.
        session_total: Running token total for this session after this call.

    Returns:
        Estimated cost in USD for this call.
    """
    pricing = PRICING.get(model, {"input": 0.0, "output": 0.0})
    cost = (
        input_tokens * pricing["input"] + output_tokens * pricing["output"]
    ) / 1_000_000

    logger.info(
        "llm_call model=%s input=%d output=%d total=%d cost_usd=%.6f "
        "session_tokens=%d call_id=%s ts=%s",
        model,
        input_tokens,
        output_tokens,
        input_tokens + output_tokens,
        cost,
        session_total,
        str(uuid.uuid4()),
        datetime.now(UTC).isoformat(),
    )
    return cost
```

---

## Session Budget Guard

Call this before every LLM request:

```python
def check_session_budget(session_total: int, tokens_requested: int) -> None:
    """Raise if this call would exceed the session token budget.

    Args:
        session_total: Tokens consumed so far this session.
        tokens_requested: Estimated tokens this call will consume.

    Raises:
        RuntimeError: If the call would push the session over MAX_TOKENS_PER_SESSION.
    """
    max_tokens = int(os.environ.get("MAX_TOKENS_PER_SESSION", "100000"))
    if session_total + tokens_requested > max_tokens:
        raise RuntimeError(
            f"Session budget exceeded: {session_total + tokens_requested} tokens "
            f"would exceed MAX_TOKENS_PER_SESSION={max_tokens}. "
            "Halt and report to operator."
        )
```

---

## Pre-flight Cost Estimation

Before batch operations (>10 calls or >10,000 estimated tokens), run a pre-flight
check and log a warning if the cost exceeds `LLM_COST_ALERT_THRESHOLD_USD`:

```python
def estimate_batch_cost(
    num_calls: int,
    avg_input_tokens: int,
    avg_output_tokens: int,
    model: str,
) -> float:
    """Estimate total USD cost for a batch of LLM calls.

    Args:
        num_calls: Number of API calls in the batch.
        avg_input_tokens: Average input tokens per call.
        avg_output_tokens: Average output tokens per call.
        model: Model identifier for pricing lookup.

    Returns:
        Estimated total cost in USD.
    """
    pricing = PRICING.get(model, {"input": 0.0, "output": 0.0})
    per_call = (
        avg_input_tokens * pricing["input"] + avg_output_tokens * pricing["output"]
    ) / 1_000_000
    return per_call * num_calls


def preflight_batch(
    num_calls: int,
    avg_input_tokens: int,
    avg_output_tokens: int,
    model: str,
) -> None:
    """Log a warning if estimated batch cost exceeds the alert threshold.

    Args:
        num_calls: Number of calls in the batch.
        avg_input_tokens: Average input tokens per call.
        avg_output_tokens: Average output tokens per call.
        model: Model identifier for pricing lookup.
    """
    threshold = float(os.environ.get("LLM_COST_ALERT_THRESHOLD_USD", "1.00"))
    cost = estimate_batch_cost(num_calls, avg_input_tokens, avg_output_tokens, model)
    if cost >= threshold:
        logger.warning(
            "preflight_batch estimated_cost_usd=%.4f calls=%d model=%s "
            "-- exceeds alert threshold of $%.2f",
            cost,
            num_calls,
            model,
            threshold,
        )
```

---

## Alert Thresholds

| Condition | Required action |
|-----------|----------------|
| Call would exceed `MAX_TOKENS_PER_CALL` | Log ERROR; do not send the call |
| Session would exceed `MAX_TOKENS_PER_SESSION` | Raise RuntimeError; halt |
| Batch estimate exceeds `LLM_COST_ALERT_THRESHOLD_USD` | Log WARNING; proceed |
| Session cost exceeds 2× `LLM_COST_ALERT_THRESHOLD_USD` | Log ERROR; escalate to human |

---

## Prompt Efficiency Patterns

Reduce token consumption without degrading output quality:

| Pattern | How |
|---------|-----|
| Trim context aggressively | Pass only the relevant excerpt, not the whole file |
| Specify structured output | JSON/YAML outputs are denser than prose; define the schema |
| Cache system prompts | Use provider prompt-caching APIs for repeated system prompts |
| Route to smaller models | Use Haiku/mini-class models for classification, routing, summarization |
| Batch micro-tasks | Combine 5–10 small tasks into one call instead of separate calls |
| Set `max_tokens` | Always set a response token cap to prevent runaway output |
| Skip redundant context | Do not resend conversation history the model already has in context |

---

## See Also

- `skills/prompt-engineering.md`: prompt structure, injection defense, token efficiency
- `subagents/accounting-agent.md`: session-level cost monitoring agent
