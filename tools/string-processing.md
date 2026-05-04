# Tools: String Processing

Deterministic functions for normalizing, matching, extracting, and transforming
text. Uses only the standard library: `re`, `unicodedata`, `textwrap`, and
`string`.

---

## normalize_whitespace — collapse runs of whitespace

```python
import re


def normalize_whitespace(text: str) -> str:
    """Replace all runs of whitespace (including newlines, tabs) with a single space.

    Args:
        text: Input string.

    Returns:
        Stripped string with all internal whitespace collapsed to one space.

    Example::

        >>> normalize_whitespace("  hello\\n  world  ")
        'hello world'
    """
    return re.sub(r"\s+", " ", text).strip()
```

---

## slugify — URL/filename-safe slug

```python
import re
import unicodedata


def slugify(text: str, separator: str = "-") -> str:
    """Convert arbitrary text to a URL and filename-safe slug.

    Converts to ASCII, lowercases, replaces spaces and punctuation with
    `separator`, and strips leading/trailing separators.

    Args:
        text: Input string.
        separator: Character used between words. Defaults to "-".

    Returns:
        ASCII slug string.

    Example::

        >>> slugify("Hello, World! 2024")
        'hello-world-2024'
        >>> slugify("Héllo Wörld", separator="_")
        'hello_world'
    """
    # Normalize unicode to closest ASCII representation
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    lower = ascii_text.lower()
    slug = re.sub(r"[^\w\s-]", "", lower)
    slug = re.sub(r"[\s_-]+", separator, slug)
    return slug.strip(separator)
```

---

## truncate — clip string with ellipsis

```python
def truncate(text: str, max_length: int, suffix: str = "…") -> str:
    """Clip `text` to at most `max_length` characters, appending `suffix` if clipped.

    The total length of the result (including suffix) never exceeds `max_length`.

    Args:
        text: Input string.
        max_length: Maximum character length of the output.
        suffix: String appended when truncation occurs. Defaults to "…".

    Returns:
        Original string if short enough, otherwise truncated string + suffix.

    Raises:
        ValueError: If `max_length` is less than `len(suffix)`.

    Example::

        >>> truncate("Hello, World!", 8)
        'Hello, …'
        >>> truncate("Hi", 8)
        'Hi'
    """
    if max_length < len(suffix):
        raise ValueError(f"max_length ({max_length}) must be >= len(suffix) ({len(suffix)})")
    if len(text) <= max_length:
        return text
    return text[: max_length - len(suffix)] + suffix
```

---

## extract_emails — find all email addresses in text

```python
import re

_EMAIL_RE = re.compile(r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}")


def extract_emails(text: str) -> list[str]:
    """Find all email-like addresses in a string.

    Uses a conservative RFC 5322 subset pattern. Does not validate
    domain existence or MX records.

    Args:
        text: Source text to search.

    Returns:
        List of matched email strings in order of appearance.
        Duplicates are preserved.

    Example::

        >>> extract_emails("Contact alice@example.com or bob@test.org for help.")
        ['alice@example.com', 'bob@test.org']
    """
    return _EMAIL_RE.findall(text)
```

---

## extract_urls — find all http/https URLs in text

```python
import re

_URL_RE = re.compile(
    r"https?://"
    r"(?:[a-zA-Z0-9\-._~:/?#\[\]@!$&'()*+,;=%]+"
    r")"
)


def extract_urls(text: str) -> list[str]:
    """Find all http:// and https:// URLs in a string.

    Args:
        text: Source text to search.

    Returns:
        List of URL strings in order of appearance. Duplicates preserved.

    Example::

        >>> extract_urls("See https://example.com and http://test.org/path?q=1")
        ['https://example.com', 'http://test.org/path?q=1']
    """
    return _URL_RE.findall(text)
```

---

## camel_to_snake — convert camelCase to snake_case

```python
import re


def camel_to_snake(name: str) -> str:
    """Convert a camelCase or PascalCase identifier to snake_case.

    Args:
        name: Camel-cased or Pascal-cased string.

    Returns:
        snake_case version.

    Example::

        >>> camel_to_snake("MyClassName")
        'my_class_name'
        >>> camel_to_snake("getHTTPResponse")
        'get_http_response'
    """
    # Insert underscore before sequences of uppercase followed by lowercase
    s1 = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s1).lower()
```

---

## snake_to_camel — convert snake_case to camelCase

```python
def snake_to_camel(name: str, *, upper_first: bool = False) -> str:
    """Convert a snake_case identifier to camelCase or PascalCase.

    Args:
        name: snake_case string.
        upper_first: If True, capitalize the first component (PascalCase).

    Returns:
        camelCase or PascalCase string.

    Example::

        >>> snake_to_camel("my_variable_name")
        'myVariableName'
        >>> snake_to_camel("my_variable_name", upper_first=True)
        'MyVariableName'
    """
    parts = name.split("_")
    if not parts:
        return name
    if upper_first:
        return "".join(p.capitalize() for p in parts)
    return parts[0] + "".join(p.capitalize() for p in parts[1:])
```

---

## wrap_text — word-wrap to a fixed width

```python
import textwrap


def wrap_text(text: str, width: int = 79, *, indent: str = "") -> str:
    """Word-wrap `text` to at most `width` characters per line.

    Args:
        text: Input text. May contain existing newlines (paragraphs preserved).
        width: Maximum line width in characters.
        indent: String prepended to every output line.

    Returns:
        Wrapped string.

    Example::

        >>> print(wrap_text("The quick brown fox jumped over the lazy dog.", width=20))
        The quick brown fox
        jumped over the
        lazy dog.
    """
    return textwrap.fill(text, width=width, initial_indent=indent, subsequent_indent=indent)
```

---

## strip_ansi — remove ANSI escape sequences from terminal output

```python
import re

_ANSI_RE = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")


def strip_ansi(text: str) -> str:
    """Remove ANSI/VT100 escape sequences from a string.

    Useful for cleaning up terminal output before further text processing.

    Args:
        text: String that may contain ANSI escape codes.

    Returns:
        Plain text with all escape sequences removed.

    Example::

        >>> strip_ansi("\\x1b[32mGreen text\\x1b[0m")
        'Green text'
    """
    return _ANSI_RE.sub("", text)
```

---

## count_words — token count for plain text

```python
import re


def count_words(text: str) -> int:
    """Count the number of whitespace-separated tokens in a string.

    Args:
        text: Input string.

    Returns:
        Number of word tokens (0 for empty or whitespace-only strings).

    Example::

        >>> count_words("The quick brown fox")
        4
        >>> count_words("  ")
        0
    """
    return len(re.findall(r"\S+", text))
```

---

## See Also

- [`tools/collections.md`](collections.md) — frequency counts on tokenized text
- [`tools/serialization.md`](serialization.md) — parse structured text as JSON/CSV
- [`skills/nlp-processing.md`](../skills/nlp-processing.md) — LLM-powered text analysis
