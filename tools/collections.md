# Tools: Collections

Deterministic functions for counting, grouping, deduplicating, and restructuring
Python data structures using `collections`, `heapq`, and `bisect`.

---

## Counter — frequency map from any iterable

```python
from collections import Counter


def frequency_map(items: list) -> dict:
    """Return a dict mapping each item to its occurrence count.

    Args:
        items: Any list of hashable values.

    Returns:
        Dict of {item: count}, sorted descending by count.

    Example::

        >>> frequency_map(["a", "b", "a", "c", "b", "a"])
        {'a': 3, 'b': 2, 'c': 1}
    """
    return dict(Counter(items).most_common())
```

---

## group_by — bucket items by a key function

```python
from collections import defaultdict
from typing import Callable, TypeVar

T = TypeVar("T")
K = TypeVar("K")


def group_by(items: list[T], key: Callable[[T], K]) -> dict[K, list[T]]:
    """Group items into lists by a computed key.

    Args:
        items: Source list.
        key: Function that maps each item to its group key.

    Returns:
        Dict mapping each key to the list of items that produced it.
        Order within each group is preserved.

    Example::

        >>> group_by([1, 2, 3, 4, 5, 6], key=lambda n: n % 2)
        {1: [1, 3, 5], 0: [2, 4, 6]}
    """
    groups: dict[K, list[T]] = defaultdict(list)
    for item in items:
        groups[key(item)].append(item)
    return dict(groups)
```

---

## deduplicate — ordered unique elements

```python
from typing import TypeVar

T = TypeVar("T")


def deduplicate(items: list[T]) -> list[T]:
    """Remove duplicates from a list while preserving first-seen order.

    Args:
        items: List that may contain duplicates. Items must be hashable.

    Returns:
        New list with duplicates removed; original order maintained.

    Example::

        >>> deduplicate([3, 1, 4, 1, 5, 9, 2, 6, 5, 3])
        [3, 1, 4, 5, 9, 2, 6]
    """
    seen: set = set()
    result: list[T] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result
```

---

## flatten — nested list to flat list

```python
from collections.abc import Iterable
from typing import TypeVar

T = TypeVar("T")


def flatten(nested: Iterable, depth: int = 1) -> list:
    """Flatten a nested iterable up to `depth` levels.

    Args:
        nested: An iterable that may contain nested iterables.
        depth: How many levels deep to flatten. Use -1 for unlimited.

    Returns:
        Flat list of all leaf elements up to the specified depth.

    Example::

        >>> flatten([[1, 2], [3, [4, 5]], 6])
        [1, 2, 3, [4, 5], 6]

        >>> flatten([[1, 2], [3, [4, 5]], 6], depth=2)
        [1, 2, 3, 4, 5, 6]
    """
    result = []
    for item in nested:
        if isinstance(item, Iterable) and not isinstance(item, (str, bytes)) and depth != 0:
            result.extend(flatten(item, depth - 1))
        else:
            result.append(item)
    return result
```

---

## chunk — split list into fixed-size batches

```python
from typing import TypeVar

T = TypeVar("T")


def chunk(items: list[T], size: int) -> list[list[T]]:
    """Split a list into consecutive sublists of at most `size` elements.

    The last chunk may be smaller if the list does not divide evenly.

    Args:
        items: The source list.
        size: Maximum number of elements per chunk. Must be >= 1.

    Returns:
        List of sublists.

    Raises:
        ValueError: If `size` is less than 1.

    Example::

        >>> chunk([1, 2, 3, 4, 5], 2)
        [[1, 2], [3, 4], [5]]
    """
    if size < 1:
        raise ValueError(f"size must be >= 1, got {size}")
    return [items[i : i + size] for i in range(0, len(items), size)]
```

---

## top_n — k largest or smallest values

```python
import heapq
from typing import TypeVar

T = TypeVar("T")


def top_n(items: list[T], n: int, *, largest: bool = True) -> list[T]:
    """Return the n largest (or smallest) values from a list.

    Uses `heapq` for O(k log n) performance — faster than full sort for small k.

    Args:
        items: Source list of comparable values.
        n: Number of results to return.
        largest: If True (default), return largest values; False returns smallest.

    Returns:
        Sorted list of at most `n` values.

    Example::

        >>> top_n([3, 1, 4, 1, 5, 9, 2, 6], n=3)
        [9, 6, 5]

        >>> top_n([3, 1, 4, 1, 5, 9, 2, 6], n=3, largest=False)
        [1, 1, 2]
    """
    fn = heapq.nlargest if largest else heapq.nsmallest
    return fn(n, items)
```

---

## bisect_insert_index — sorted insertion point

```python
import bisect


def bisect_insert_index(sorted_list: list[int | float], value: int | float) -> int:
    """Return the index at which `value` should be inserted to keep the list sorted.

    Uses binary search — O(log n). Does not modify the list.

    Args:
        sorted_list: A list already sorted in ascending order.
        value: The value to locate.

    Returns:
        Insertion index (0-based). Equal values are inserted to the right.

    Example::

        >>> bisect_insert_index([1, 3, 5, 7], 4)
        2
        >>> bisect_insert_index([1, 3, 5, 7], 5)
        3
    """
    return bisect.bisect_right(sorted_list, value)
```

---

## invert_dict — swap keys and values

```python
def invert_dict(mapping: dict) -> dict:
    """Swap keys and values in a dictionary.

    Args:
        mapping: Dict with hashable values.

    Returns:
        New dict with values as keys and keys as values.

    Raises:
        ValueError: If any values are duplicated (would silently overwrite).

    Example::

        >>> invert_dict({"a": 1, "b": 2, "c": 3})
        {1: 'a', 2: 'b', 3: 'c'}
    """
    values = list(mapping.values())
    if len(values) != len(set(values)):
        raise ValueError("Cannot invert dict with duplicate values")
    return {v: k for k, v in mapping.items()}
```

---

## See Also

- [`tools/itertools-functools.md`](itertools-functools.md) — combinatorial iteration tools
- [`tools/math-statistics.md`](math-statistics.md) — aggregation and numeric summaries
- [`skills/error-handling.md`](../skills/error-handling.md) — handling ValueError from validation
