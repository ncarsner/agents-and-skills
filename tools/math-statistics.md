# Tools: Math & Statistics

Deterministic functions for numeric aggregation, rounding, clamping, and
distribution analysis using the standard library: `math`, `statistics`,
`decimal`, and `fractions`.

All functions are pure — no side effects, same input always produces same output.

---

## clamp — constrain a value within a range

```python
from typing import TypeVar

T = TypeVar("T", int, float)


def clamp(value: T, lo: T, hi: T) -> T:
    """Constrain `value` to the closed interval [lo, hi].

    Args:
        value: The value to constrain.
        lo: Lower bound (inclusive).
        hi: Upper bound (inclusive).

    Returns:
        `lo` if value < lo, `hi` if value > hi, otherwise `value`.

    Raises:
        ValueError: If `lo` > `hi`.

    Example::

        >>> clamp(15, 0, 10)
        10
        >>> clamp(-3, 0, 10)
        0
        >>> clamp(5, 0, 10)
        5
    """
    if lo > hi:
        raise ValueError(f"lo ({lo}) must be <= hi ({hi})")
    return max(lo, min(value, hi))
```

---

## round_half_up — explicit ROUND_HALF_UP (avoids banker's rounding)

```python
from decimal import ROUND_HALF_UP, Decimal


def round_half_up(value: float | Decimal, decimals: int = 0) -> float:
    """Round a number using ROUND_HALF_UP (0.5 always rounds away from zero).

    Python's built-in `round()` uses banker's rounding (ROUND_HALF_EVEN).
    Use this when you need predictable half-rounding (e.g., currency, reports).

    Args:
        value: Number to round.
        decimals: Number of decimal places. 0 returns an integer-valued float.

    Returns:
        Rounded float.

    Example::

        >>> round_half_up(2.5)
        3.0
        >>> round_half_up(2.5, 0)
        3.0
        >>> round_half_up(1.005, 2)
        1.01
    """
    quantizer = Decimal(10) ** -decimals
    return float(Decimal(str(value)).quantize(quantizer, rounding=ROUND_HALF_UP))
```

---

## percent_change — relative change between two values

```python
def percent_change(old: float, new: float, decimals: int = 2) -> float:
    """Compute the percentage change from `old` to `new`.

    Args:
        old: The baseline value.
        new: The new value.
        decimals: Decimal places to round the result.

    Returns:
        Signed percentage change, rounded to `decimals` places.

    Raises:
        ZeroDivisionError: If `old` is zero.

    Example::

        >>> percent_change(100, 125)
        25.0
        >>> percent_change(100, 80)
        -20.0
    """
    if old == 0:
        raise ZeroDivisionError("Cannot compute percent change when old value is zero")
    return round((new - old) / abs(old) * 100, decimals)
```

---

## safe_divide — division with a configurable fallback

```python
def safe_divide(numerator: float, denominator: float, default: float = 0.0) -> float:
    """Divide numerator by denominator, returning `default` on zero division.

    Args:
        numerator: Dividend.
        denominator: Divisor.
        default: Value to return when denominator is 0. Defaults to 0.0.

    Returns:
        Quotient, or `default` if denominator is zero.

    Example::

        >>> safe_divide(10, 4)
        2.5
        >>> safe_divide(10, 0)
        0.0
        >>> safe_divide(10, 0, default=float("inf"))
        inf
    """
    return numerator / denominator if denominator != 0 else default
```

---

## summary_stats — mean, median, stdev, min, max

```python
import statistics


def summary_stats(values: list[float | int]) -> dict[str, float]:
    """Compute common descriptive statistics for a list of numeric values.

    Args:
        values: Non-empty list of numbers.

    Returns:
        Dict with keys: "mean", "median", "stdev", "min", "max", "count".
        "stdev" is population stdev for n=1 (returns 0.0).

    Raises:
        ValueError: If `values` is empty.

    Example::

        >>> summary_stats([2, 4, 4, 4, 5, 5, 7, 9])
        {'mean': 5.0, 'median': 4.5, 'stdev': 2.0, 'min': 2, 'max': 9, 'count': 8}
    """
    if not values:
        raise ValueError("values must not be empty")
    return {
        "mean": statistics.mean(values),
        "median": statistics.median(values),
        "stdev": statistics.stdev(values) if len(values) > 1 else 0.0,
        "min": min(values),
        "max": max(values),
        "count": len(values),
    }
```

---

## percentile — value at a given percentile rank

```python
import math


def percentile(values: list[float | int], p: float) -> float:
    """Return the value at percentile `p` using linear interpolation.

    Args:
        values: Non-empty list of numeric values. Need not be sorted.
        p: Percentile in the range [0, 100].

    Returns:
        Interpolated value at the given percentile.

    Raises:
        ValueError: If `values` is empty or `p` is outside [0, 100].

    Example::

        >>> percentile([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 90)
        9.1
    """
    if not values:
        raise ValueError("values must not be empty")
    if not 0 <= p <= 100:
        raise ValueError(f"p must be in [0, 100], got {p}")
    sorted_vals = sorted(values)
    n = len(sorted_vals)
    index = (p / 100) * (n - 1)
    lo = math.floor(index)
    hi = math.ceil(index)
    if lo == hi:
        return float(sorted_vals[lo])
    frac = index - lo
    return sorted_vals[lo] * (1 - frac) + sorted_vals[hi] * frac
```

---

## moving_average — simple moving average over a window

```python
from collections import deque


def moving_average(values: list[float | int], window: int) -> list[float]:
    """Compute a simple moving average with a fixed-size window.

    Args:
        values: Time-ordered list of numeric values.
        window: Number of periods to average. Must be >= 1.

    Returns:
        List of moving averages. Length is `len(values) - window + 1`.
        Returns an empty list if `len(values) < window`.

    Raises:
        ValueError: If `window` is less than 1.

    Example::

        >>> moving_average([1, 2, 3, 4, 5], window=3)
        [2.0, 3.0, 4.0]
    """
    if window < 1:
        raise ValueError(f"window must be >= 1, got {window}")
    if len(values) < window:
        return []
    buf: deque[float | int] = deque(values[:window], maxlen=window)
    result = [sum(buf) / window]
    for val in values[window:]:
        buf.append(val)
        result.append(sum(buf) / window)
    return result
```

---

## normalize_to_range — rescale values to [0, 1] or [a, b]

```python
def normalize_to_range(
    values: list[float | int],
    new_min: float = 0.0,
    new_max: float = 1.0,
) -> list[float]:
    """Min-max normalize a list of values into the range [new_min, new_max].

    Args:
        values: Non-empty list of numeric values.
        new_min: Lower bound of the output range. Defaults to 0.0.
        new_max: Upper bound of the output range. Defaults to 1.0.

    Returns:
        List of rescaled floats. If all values are equal, returns a list of
        `new_min` values (avoids division by zero).

    Raises:
        ValueError: If `values` is empty or `new_min` >= `new_max`.

    Example::

        >>> normalize_to_range([0, 5, 10])
        [0.0, 0.5, 1.0]
        >>> normalize_to_range([0, 5, 10], new_min=0, new_max=100)
        [0.0, 50.0, 100.0]
    """
    if not values:
        raise ValueError("values must not be empty")
    if new_min >= new_max:
        raise ValueError(f"new_min ({new_min}) must be < new_max ({new_max})")
    lo, hi = min(values), max(values)
    span = hi - lo
    if span == 0:
        return [new_min] * len(values)
    return [new_min + (v - lo) / span * (new_max - new_min) for v in values]
```

---

## gcd / lcm — greatest common divisor and least common multiple

```python
import math


def gcd(a: int, b: int) -> int:
    """Return the greatest common divisor of two non-negative integers.

    Args:
        a: First integer.
        b: Second integer.

    Returns:
        GCD of a and b. Returns 0 if both are 0.

    Example::

        >>> gcd(48, 18)
        6
    """
    return math.gcd(a, b)


def lcm(a: int, b: int) -> int:
    """Return the least common multiple of two non-negative integers.

    Args:
        a: First integer.
        b: Second integer.

    Returns:
        LCM of a and b.

    Raises:
        ValueError: If either argument is negative.

    Example::

        >>> lcm(4, 6)
        12
    """
    if a < 0 or b < 0:
        raise ValueError("Arguments must be non-negative")
    return math.lcm(a, b)
```

---

## See Also

- [`tools/collections.md`](collections.md) — top_n, frequency_map
- [`tools/itertools-functools.md`](itertools-functools.md) — reduce, accumulate
- [`skills/dashboarding-reporting.md`](../skills/dashboarding-reporting.md) — aggregation in reports
