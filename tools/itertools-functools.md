# Tools: Itertools & Functools

Deterministic tools for composing, combining, and transforming iterables using
`itertools` and `functools`. All functions are pure — no side effects.

---

## sliding_window — overlapping n-element windows

```python
from collections import deque
from collections.abc import Iterable, Iterator
from typing import TypeVar

T = TypeVar("T")


def sliding_window(iterable: Iterable[T], n: int) -> Iterator[tuple[T, ...]]:
    """Yield consecutive overlapping tuples of length `n`.

    Args:
        iterable: Any iterable.
        n: Window size. Must be >= 1.

    Yields:
        Tuples of length `n`. If the iterable has fewer than `n` elements,
        no tuples are yielded.

    Raises:
        ValueError: If `n` is less than 1.

    Example::

        >>> list(sliding_window([1, 2, 3, 4, 5], 3))
        [(1, 2, 3), (2, 3, 4), (3, 4, 5)]
    """
    if n < 1:
        raise ValueError(f"n must be >= 1, got {n}")
    window: deque[T] = deque(maxlen=n)
    for item in iterable:
        window.append(item)
        if len(window) == n:
            yield tuple(window)
```

---

## pairwise — consecutive pairs (builtin polyfill for < 3.10)

```python
from collections.abc import Iterable, Iterator
from typing import TypeVar

T = TypeVar("T")


def pairwise(iterable: Iterable[T]) -> Iterator[tuple[T, T]]:
    """Yield consecutive overlapping pairs from an iterable.

    Equivalent to `itertools.pairwise` (Python 3.10+), provided here as a
    standalone function for compatibility.

    Args:
        iterable: Any iterable with at least 2 elements.

    Yields:
        Pairs (a, b) where b immediately follows a in the source.

    Example::

        >>> list(pairwise([1, 2, 3, 4]))
        [(1, 2), (2, 3), (3, 4)]
    """
    it = iter(iterable)
    try:
        prev = next(it)
    except StopIteration:
        return
    for item in it:
        yield prev, item
        prev = item
```

---

## roundrobin — interleave multiple iterables

```python
import itertools
from collections.abc import Iterable
from typing import TypeVar

T = TypeVar("T")


def roundrobin(*iterables: Iterable[T]) -> list[T]:
    """Interleave elements from multiple iterables in round-robin order.

    Exhausted iterables are skipped; remaining iterables continue.

    Args:
        *iterables: Any number of iterables.

    Returns:
        Flat list with elements interleaved.

    Example::

        >>> roundrobin([1, 2, 3], ["a", "b"], [True])
        [1, 'a', True, 2, 'b', 3]
    """
    sentinel = object()
    nexts = [iter(it) for it in iterables]
    result = []
    while nexts:
        still_active = []
        for it in nexts:
            val = next(it, sentinel)
            if val is not sentinel:
                result.append(val)
                still_active.append(it)
        nexts = still_active
    return result
```

---

## partition — split iterable into two lists by predicate

```python
from collections.abc import Callable, Iterable
from typing import TypeVar

T = TypeVar("T")


def partition(
    predicate: Callable[[T], bool],
    iterable: Iterable[T],
) -> tuple[list[T], list[T]]:
    """Split an iterable into two lists based on a boolean predicate.

    Args:
        predicate: Function returning True for items to include in the
            first list, False for the second.
        iterable: Source iterable.

    Returns:
        Tuple of (true_list, false_list).

    Example::

        >>> evens, odds = partition(lambda n: n % 2 == 0, range(6))
        >>> evens
        [0, 2, 4]
        >>> odds
        [1, 3, 5]
    """
    true_items: list[T] = []
    false_items: list[T] = []
    for item in iterable:
        if predicate(item):
            true_items.append(item)
        else:
            false_items.append(item)
    return true_items, false_items
```

---

## unique_everseen — deduplicate preserving order, with key support

```python
from collections.abc import Callable, Iterable, Iterator
from typing import TypeVar

T = TypeVar("T")
K = TypeVar("K")


def unique_everseen(
    iterable: Iterable[T],
    key: Callable[[T], K] | None = None,
) -> Iterator[T]:
    """Yield each item that has not been seen before, using an optional key function.

    Args:
        iterable: Source iterable.
        key: Optional function to derive the uniqueness key from each element.
            If None, the element itself is used.

    Yields:
        First occurrence of each unique element (by key).

    Example::

        >>> list(unique_everseen([1, 2, 1, 3, 2]))
        [1, 2, 3]

        >>> list(unique_everseen(["foo", "FOO", "bar"], key=str.lower))
        ['foo', 'bar']
    """
    seen: set = set()
    for item in iterable:
        k = key(item) if key else item
        if k not in seen:
            seen.add(k)
            yield item
```

---

## first_true — find first element matching a predicate

```python
from collections.abc import Callable, Iterable
from typing import TypeVar

T = TypeVar("T")


def first_true(
    iterable: Iterable[T],
    predicate: Callable[[T], bool],
    default: T | None = None,
) -> T | None:
    """Return the first element for which `predicate` returns True.

    Args:
        iterable: Source iterable.
        predicate: Boolean test function.
        default: Value to return if no element matches. Defaults to None.

    Returns:
        First matching element, or `default`.

    Example::

        >>> first_true([1, 3, 4, 6, 7], lambda n: n % 2 == 0)
        4
        >>> first_true([1, 3, 5], lambda n: n % 2 == 0)
        # returns None
    """
    return next((item for item in iterable if predicate(item)), default)
```

---

## memoize — cache function results by argument signature

```python
import functools
from collections.abc import Callable
from typing import TypeVar

T = TypeVar("T")


def memoize(fn: Callable[..., T]) -> Callable[..., T]:
    """Decorator: cache results of a pure function by its arguments.

    Uses `functools.lru_cache` with no size limit. Suitable for pure
    functions with hashable arguments.

    Args:
        fn: The function to wrap.

    Returns:
        Wrapped function that caches its results.

    Example::

        >>> @memoize
        ... def fib(n: int) -> int:
        ...     return n if n < 2 else fib(n - 1) + fib(n - 2)
        >>> fib(30)
        832040
    """
    return functools.lru_cache(maxsize=None)(fn)
```

---

## take / drop — head and tail of an iterable

```python
import itertools
from collections.abc import Iterable
from typing import TypeVar

T = TypeVar("T")


def take(n: int, iterable: Iterable[T]) -> list[T]:
    """Return the first `n` elements of an iterable as a list.

    Args:
        n: Number of elements to take. If the iterable is shorter, all
            elements are returned.
        iterable: Source iterable.

    Returns:
        List of at most `n` elements.

    Example::

        >>> take(3, range(10))
        [0, 1, 2]
    """
    return list(itertools.islice(iterable, n))


def drop(n: int, iterable: Iterable[T]) -> list[T]:
    """Skip the first `n` elements of an iterable and return the rest.

    Args:
        n: Number of elements to skip.
        iterable: Source iterable.

    Returns:
        List of remaining elements after skipping `n`.

    Example::

        >>> drop(3, range(6))
        [3, 4, 5]
    """
    return list(itertools.islice(iterable, n, None))
```

---

## See Also

- [`tools/collections.md`](collections.md) — chunk, group_by, top_n
- [`tools/math-statistics.md`](math-statistics.md) — reductions and aggregations
- [`skills/python-testing.md`](../skills/python-testing.md) — parametrize itertools tests
