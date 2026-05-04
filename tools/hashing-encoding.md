# Tools: Hashing & Encoding

Deterministic functions for producing content hashes, encoding and decoding
data, and generating unique identifiers. Uses only the standard library:
`hashlib`, `base64`, `uuid`, `hmac`, and `secrets`.

Note: UUID4 uses random bits and is non-deterministic by design. All other
functions here are pure given the same input.

---

## sha256 — hex digest of a string or bytes

```python
import hashlib


def sha256(data: str | bytes, encoding: str = "utf-8") -> str:
    """Compute the SHA-256 hex digest of a string or bytes object.

    Args:
        data: Input to hash. Strings are encoded using `encoding`.
        encoding: Character encoding for string input.

    Returns:
        64-character lowercase hex string.

    Example::

        >>> sha256("hello")
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824'
    """
    raw = data.encode(encoding) if isinstance(data, str) else data
    return hashlib.sha256(raw).hexdigest()
```


---

## hmac_sha256 — keyed message authentication code

```python
import hashlib
import hmac


def hmac_sha256(key: str | bytes, message: str | bytes, encoding: str = "utf-8") -> str:
    """Compute an HMAC-SHA256 authentication code.

    Use this to verify data integrity and authenticity when both sender
    and receiver share a secret key (e.g., webhook payload verification).

    Args:
        key: Secret key. Strings are encoded using `encoding`.
        message: Message to authenticate.
        encoding: Encoding for string inputs.

    Returns:
        64-character lowercase hex string.

    Example::

        >>> hmac_sha256("secret", "payload")
        'b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7'
    """
    raw_key = key.encode(encoding) if isinstance(key, str) else key
    raw_msg = message.encode(encoding) if isinstance(message, str) else message
    return hmac.new(raw_key, raw_msg, hashlib.sha256).hexdigest()
```

---

## base64_encode / base64_decode — standard Base64

```python
import base64


def base64_encode(data: str | bytes, encoding: str = "utf-8") -> str:
    """Encode data as standard Base64 (RFC 4648).

    Args:
        data: Input string or bytes.
        encoding: Encoding for string input.

    Returns:
        Base64-encoded string (ASCII, no padding stripped).

    Example::

        >>> base64_encode("hello world")
        'aGVsbG8gd29ybGQ='
    """
    raw = data.encode(encoding) if isinstance(data, str) else data
    return base64.b64encode(raw).decode("ascii")


def base64_decode(encoded: str, encoding: str = "utf-8") -> str:
    """Decode a standard Base64 string back to text.

    Args:
        encoded: Base64-encoded ASCII string.
        encoding: Encoding to use when decoding the resulting bytes to str.

    Returns:
        Decoded string.

    Raises:
        ValueError: If `encoded` is not valid Base64.

    Example::

        >>> base64_decode("aGVsbG8gd29ybGQ=")
        'hello world'
    """
    try:
        return base64.b64decode(encoded).decode(encoding)
    except Exception as exc:
        raise ValueError(f"Invalid Base64 input: {exc}") from exc
```

---

## urlsafe_base64_encode / decode — URL-safe Base64

```python
import base64


def urlsafe_base64_encode(data: str | bytes, encoding: str = "utf-8") -> str:
    """Encode data as URL-safe Base64 (RFC 4648 §5), without padding.

    Safe for use in URLs, filenames, and JWT components.

    Args:
        data: Input string or bytes.
        encoding: Encoding for string input.

    Returns:
        URL-safe Base64 string with padding stripped.

    Example::

        >>> urlsafe_base64_encode("hello+world")
        'aGVsbG8rd29ybGQ'
    """
    raw = data.encode(encoding) if isinstance(data, str) else data
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def urlsafe_base64_decode(encoded: str, encoding: str = "utf-8") -> str:
    """Decode a URL-safe Base64 string (padding is added automatically).

    Args:
        encoded: URL-safe Base64 string, with or without trailing '=' padding.
        encoding: Encoding for decoding the result to str.

    Returns:
        Decoded string.

    Raises:
        ValueError: If the input is malformed.

    Example::

        >>> urlsafe_base64_decode("aGVsbG8rd29ybGQ")
        'hello+world'
    """
    padded = encoded + "=" * (-len(encoded) % 4)
    try:
        return base64.urlsafe_b64decode(padded).decode(encoding)
    except Exception as exc:
        raise ValueError(f"Invalid URL-safe Base64 input: {exc}") from exc
```

---

## uuid4 — random UUID string

```python
import uuid


def uuid4() -> str:
    """Generate a random UUID4 as a lowercase hyphenated string.

    Non-deterministic — each call returns a unique value.

    Returns:
        UUID4 string, e.g. "550e8400-e29b-41d4-a716-446655440000".

    Example::

        >>> u = uuid4()
        >>> len(u)
        36
        >>> u[14]  # version digit
        '4'
    """
    return str(uuid.uuid4())
```

---

## uuid5 — deterministic namespace UUID

```python
import uuid


def uuid5(namespace: str, name: str) -> str:
    """Generate a deterministic UUID5 from a namespace URL and a name.

    Same namespace + name always produce the same UUID. Useful for creating
    stable identifiers from known data (e.g., record deduplication).

    Args:
        namespace: A URL string used as the UUID namespace.
        name: The name string to hash within the namespace.

    Returns:
        UUID5 string.

    Example::

        >>> uuid5("https://example.com", "user-42")
        'da6fd9da-9fde-5f90-9af2-9a0c59dd3a53'
    """
    ns = uuid.uuid5(uuid.NAMESPACE_URL, namespace)
    return str(uuid.uuid5(ns, name))
```

---

## secure_token — URL-safe random token

```python
import secrets


def secure_token(nbytes: int = 32) -> str:
    """Generate a cryptographically secure random URL-safe token.

    Non-deterministic — uses `secrets.token_urlsafe` which draws from the
    OS CSPRNG.

    Args:
        nbytes: Number of random bytes. The output string will be longer
            due to Base64 encoding (~4/3 of nbytes, rounded up).

    Returns:
        URL-safe Base64 string.

    Example::

        >>> t = secure_token()
        >>> len(t) >= 32
        True
    """
    return secrets.token_urlsafe(nbytes)
```

---

## constant_time_compare — timing-safe string comparison

```python
import hmac


def constant_time_compare(a: str, b: str, encoding: str = "utf-8") -> bool:
    """Compare two strings in constant time to prevent timing attacks.

    Use this when comparing secrets, tokens, or MACs. Python's `==` operator
    short-circuits and can leak information via timing differences.

    Args:
        a: First string.
        b: Second string.
        encoding: Encoding for converting strings to bytes.

    Returns:
        True if the strings are equal, False otherwise.

    Example::

        >>> constant_time_compare("super-secret-token", "super-secret-token")
        True
        >>> constant_time_compare("abc", "xyz")
        False
    """
    return hmac.compare_digest(a.encode(encoding), b.encode(encoding))
```

---

## See Also

- [`tools/file-io.md`](file-io.md) — `file_checksum` for hashing file contents
- [`tools/string-processing.md`](string-processing.md) — normalize strings before hashing
- [`skills/security-agent.md`](../subagents/security-agent.md) — security guidelines for key management
