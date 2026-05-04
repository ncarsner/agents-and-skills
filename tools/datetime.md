# Tools: Date & Time

Deterministic functions for parsing, formatting, comparing, and computing with
dates and times. Uses only the standard library: `datetime`, `zoneinfo`, and
`calendar`.

All functions with a `tz` parameter default to UTC. Naive datetimes are never
created — callers should always pass or receive timezone-aware values.

---

## parse_iso — parse ISO 8601 string to aware datetime

```python
from datetime import datetime, timezone


def parse_iso(timestamp: str) -> datetime:
    """Parse an ISO 8601 string into a timezone-aware datetime.

    Accepts strings with or without a timezone offset. Strings without an
    offset are assumed to be UTC.

    Args:
        timestamp: ISO 8601 string, e.g. "2024-03-15T14:30:00Z" or
            "2024-03-15T14:30:00+05:00" or "2024-03-15".

    Returns:
        Timezone-aware datetime in the offset specified (or UTC if absent).

    Raises:
        ValueError: If the string cannot be parsed.

    Example::

        >>> parse_iso("2024-03-15T14:30:00Z")
        datetime.datetime(2024, 3, 15, 14, 30, tzinfo=datetime.timezone.utc)
    """
    # fromisoformat handles the common formats; normalize trailing Z
    normalized = timestamp.rstrip("Z") + "+00:00" if timestamp.endswith("Z") else timestamp
    try:
        dt = datetime.fromisoformat(normalized)
    except ValueError:
        # Try bare date ("2024-03-15")
        dt = datetime.fromisoformat(timestamp + "T00:00:00+00:00")
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt
```

---

## format_iso — format aware datetime to ISO 8601

```python
from datetime import datetime


def format_iso(dt: datetime, *, timespec: str = "seconds") -> str:
    """Format a timezone-aware datetime as an ISO 8601 string.

    Args:
        dt: A timezone-aware datetime.
        timespec: Precision level — "seconds", "milliseconds", "microseconds".

    Returns:
        ISO 8601 string with timezone offset, e.g. "2024-03-15T14:30:00+00:00".

    Raises:
        ValueError: If `dt` is naive (no timezone info).

    Example::

        >>> from datetime import timezone
        >>> dt = datetime(2024, 3, 15, 14, 30, 0, tzinfo=timezone.utc)
        >>> format_iso(dt)
        '2024-03-15T14:30:00+00:00'
    """
    if dt.tzinfo is None:
        raise ValueError("datetime must be timezone-aware; got naive datetime")
    return dt.isoformat(timespec=timespec)
```

---

## date_range — generate list of dates between two boundaries

```python
from datetime import date, timedelta


def date_range(start: date, end: date, *, inclusive: bool = True) -> list[date]:
    """Generate a list of consecutive calendar dates from start to end.

    Args:
        start: First date in the range.
        end: Last date in the range (inclusive by default).
        inclusive: If True (default), include `end`; if False, exclude it.

    Returns:
        Ordered list of date objects.

    Raises:
        ValueError: If `end` is before `start`.

    Example::

        >>> from datetime import date
        >>> date_range(date(2024, 1, 1), date(2024, 1, 3))
        [datetime.date(2024, 1, 1), datetime.date(2024, 1, 2), datetime.date(2024, 1, 3)]
    """
    if end < start:
        raise ValueError(f"end ({end}) must be >= start ({start})")
    stop = end + timedelta(days=1) if inclusive else end
    days = (stop - start).days
    return [start + timedelta(days=i) for i in range(days)]
```

---

## days_between — integer number of days between two dates

```python
from datetime import date


def days_between(a: date, b: date) -> int:
    """Return the signed number of calendar days between two dates.

    Args:
        a: Start date.
        b: End date.

    Returns:
        Positive if b > a, negative if b < a, zero if equal.

    Example::

        >>> from datetime import date
        >>> days_between(date(2024, 1, 1), date(2024, 1, 15))
        14
        >>> days_between(date(2024, 1, 15), date(2024, 1, 1))
        -14
    """
    return (b - a).days
```

---

## start_of_week / end_of_week — week boundaries

```python
from datetime import date, timedelta


def start_of_week(d: date) -> date:
    """Return the Monday of the ISO week containing `d`.

    Args:
        d: Any calendar date.

    Returns:
        The Monday on or before `d`.

    Example::

        >>> from datetime import date
        >>> start_of_week(date(2024, 3, 15))  # Friday
        datetime.date(2024, 3, 11)
    """
    return d - timedelta(days=d.weekday())


def end_of_week(d: date) -> date:
    """Return the Sunday of the ISO week containing `d`.

    Args:
        d: Any calendar date.

    Returns:
        The Sunday on or after `d`.

    Example::

        >>> from datetime import date
        >>> end_of_week(date(2024, 3, 15))  # Friday
        datetime.date(2024, 3, 17)
    """
    return d + timedelta(days=6 - d.weekday())
```

---

## month_boundaries — first and last day of a month

```python
import calendar
from datetime import date


def month_boundaries(year: int, month: int) -> tuple[date, date]:
    """Return the first and last calendar date of a given month.

    Args:
        year: Four-digit year.
        month: Month number (1–12).

    Returns:
        Tuple of (first_day, last_day).

    Raises:
        ValueError: If month is outside 1–12.

    Example::

        >>> month_boundaries(2024, 2)
        (datetime.date(2024, 2, 1), datetime.date(2024, 2, 29))
    """
    _, last = calendar.monthrange(year, month)
    return date(year, month, 1), date(year, month, last)
```

---

## convert_tz — convert aware datetime to a target timezone

```python
from datetime import datetime
from zoneinfo import ZoneInfo


def convert_tz(dt: datetime, target_tz: str) -> datetime:
    """Convert a timezone-aware datetime to a different timezone.

    Args:
        dt: A timezone-aware datetime.
        target_tz: IANA timezone name, e.g. "America/New_York" or "UTC".

    Returns:
        Equivalent datetime expressed in `target_tz`.

    Raises:
        ValueError: If `dt` is naive.
        ZoneInfoNotFoundError: If `target_tz` is not a valid IANA name.

    Example::

        >>> from datetime import datetime, timezone
        >>> utc_dt = datetime(2024, 6, 1, 12, 0, tzinfo=timezone.utc)
        >>> convert_tz(utc_dt, "America/New_York")
        datetime.datetime(2024, 6, 1, 8, 0, tzinfo=zoneinfo.ZoneInfo(key='America/New_York'))
    """
    if dt.tzinfo is None:
        raise ValueError("datetime must be timezone-aware; got naive datetime")
    return dt.astimezone(ZoneInfo(target_tz))
```

---

## humanize_duration — seconds to human-readable string

```python
def humanize_duration(seconds: int | float) -> str:
    """Convert a duration in seconds to a compact human-readable string.

    Args:
        seconds: Non-negative duration in seconds (floats are truncated).

    Returns:
        String like "2d 3h 4m 5s". Components with value 0 are omitted,
        except when the total is 0 (returns "0s").

    Raises:
        ValueError: If `seconds` is negative.

    Example::

        >>> humanize_duration(90061)
        '1d 1h 1m 1s'
        >>> humanize_duration(45)
        '45s'
        >>> humanize_duration(0)
        '0s'
    """
    total = int(seconds)
    if total < 0:
        raise ValueError(f"seconds must be non-negative, got {seconds}")
    if total == 0:
        return "0s"
    days, remainder = divmod(total, 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, secs = divmod(remainder, 60)
    parts = []
    if days:
        parts.append(f"{days}d")
    if hours:
        parts.append(f"{hours}h")
    if minutes:
        parts.append(f"{minutes}m")
    if secs:
        parts.append(f"{secs}s")
    return " ".join(parts)
```

---

## See Also

- [`tools/string-processing.md`](string-processing.md) — regex-based date extraction from text
- [`tools/serialization.md`](serialization.md) — serialize datetimes to/from JSON
- [`skills/configuration-management.md`](../skills/configuration-management.md) — timezone config from env
