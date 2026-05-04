# Tools: File I/O

Deterministic functions for reading, writing, and traversing files and
directories using `pathlib.Path`. All functions use `pathlib` exclusively —
never `os.path` string manipulation.

Side effects are clearly annotated in each docstring.

---

## read_text — safe text file reader

```python
from pathlib import Path


def read_text(path: Path, encoding: str = "utf-8") -> str:
    """Read the full text contents of a file.

    Args:
        path: Path to the file.
        encoding: Character encoding. Defaults to UTF-8.

    Returns:
        File contents as a string.

    Raises:
        FileNotFoundError: If the file does not exist.
        PermissionError: If read access is denied.
        UnicodeDecodeError: If the file is not valid in `encoding`.

    Side effects:
        Reads from the filesystem.

    Example::

        >>> content = read_text(Path("pyproject.toml"))
        >>> content[:7]
        '[build-'
    """
    return path.read_text(encoding=encoding)
```

---

## write_text — atomic text file writer

```python
from pathlib import Path


def write_text(path: Path, content: str, encoding: str = "utf-8") -> None:
    """Write text content to a file, creating parent directories as needed.

    Overwrites the file if it already exists.

    Args:
        path: Destination path.
        content: Text to write.
        encoding: Character encoding. Defaults to UTF-8.

    Side effects:
        Creates parent directories and writes to the filesystem.

    Example::

        >>> write_text(Path("/tmp/out.txt"), "hello world")
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding=encoding)
```

---

## read_lines — file as a list of stripped lines

```python
from pathlib import Path


def read_lines(path: Path, *, skip_blank: bool = True, comment_prefix: str = "") -> list[str]:
    """Read a text file and return its lines as a list.

    Args:
        path: Path to the file.
        skip_blank: If True (default), exclude empty or whitespace-only lines.
        comment_prefix: If non-empty, skip lines starting with this prefix
            (after stripping). Useful for INI-style comment lines.

    Returns:
        List of stripped line strings.

    Side effects:
        Reads from the filesystem.

    Example::

        >>> lines = read_lines(Path("requirements.txt"), comment_prefix="#")
        >>> lines[0]
        'httpx>=0.27'
    """
    lines = path.read_text(encoding="utf-8").splitlines()
    result = []
    for line in lines:
        stripped = line.strip()
        if skip_blank and not stripped:
            continue
        if comment_prefix and stripped.startswith(comment_prefix):
            continue
        result.append(stripped)
    return result
```

---

## find_files — recursive glob with extension filter

```python
from pathlib import Path


def find_files(
    root: Path,
    pattern: str = "**/*",
    extensions: list[str] | None = None,
) -> list[Path]:
    """Recursively find files under `root` matching a glob pattern.

    Args:
        root: Directory to search.
        pattern: Glob pattern relative to `root`. Default "**/*" matches all files.
        extensions: Optional allowlist of file extensions including the dot,
            e.g. [".py", ".toml"]. If omitted, all files are returned.

    Returns:
        Sorted list of matching Path objects (files only, no directories).

    Side effects:
        Reads directory listings from the filesystem.

    Example::

        >>> py_files = find_files(Path("src"), extensions=[".py"])
    """
    matches = [p for p in root.glob(pattern) if p.is_file()]
    if extensions:
        ext_set = {e.lower() for e in extensions}
        matches = [p for p in matches if p.suffix.lower() in ext_set]
    return sorted(matches)
```

---

## ensure_dir — idempotent directory creation

```python
from pathlib import Path


def ensure_dir(path: Path) -> Path:
    """Create `path` as a directory (including parents) if it does not exist.

    Args:
        path: Directory path to create.

    Returns:
        The same `path`, whether created or already existing.

    Side effects:
        Creates directories on the filesystem.

    Example::

        >>> d = ensure_dir(Path("/tmp/my/nested/dir"))
        >>> d.is_dir()
        True
    """
    path.mkdir(parents=True, exist_ok=True)
    return path
```

---

## copy_file — copy with parent directory creation

```python
import shutil
from pathlib import Path


def copy_file(src: Path, dst: Path, *, overwrite: bool = False) -> Path:
    """Copy `src` to `dst`, creating parent directories as needed.

    Args:
        src: Source file path.
        dst: Destination file path (not a directory).
        overwrite: If False (default), raise if `dst` already exists.

    Returns:
        The destination Path.

    Raises:
        FileNotFoundError: If `src` does not exist.
        FileExistsError: If `dst` exists and `overwrite` is False.

    Side effects:
        Reads and writes the filesystem.

    Example::

        >>> copy_file(Path("config.toml"), Path("backup/config.toml"))
    """
    if not src.exists():
        raise FileNotFoundError(f"Source not found: {src}")
    if dst.exists() and not overwrite:
        raise FileExistsError(f"Destination already exists: {dst}")
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return dst
```

---

## file_checksum — SHA-256 hash of a file

```python
import hashlib
from pathlib import Path


def file_checksum(path: Path, algorithm: str = "sha256") -> str:
    """Compute the hex digest of a file using the given hash algorithm.

    Reads the file in chunks to support large files without loading into memory.

    Args:
        path: File to hash.
        algorithm: Hash algorithm name accepted by `hashlib` (e.g. "sha256", "md5").

    Returns:
        Lowercase hex string of the file's digest.

    Side effects:
        Reads from the filesystem.

    Example::

        >>> checksum = file_checksum(Path("pyproject.toml"))
        >>> len(checksum)
        64
    """
    h = hashlib.new(algorithm)
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()
```

---

## atomic_write — write via temp file, then rename

```python
import tempfile
from pathlib import Path


def atomic_write(path: Path, content: str, encoding: str = "utf-8") -> None:
    """Write content to `path` atomically using a temp-file-then-rename strategy.

    Guarantees that `path` is never left in a partially-written state. If the
    process is interrupted, the original file (if any) is preserved.

    Args:
        path: Destination path.
        content: Text to write.
        encoding: Character encoding.

    Side effects:
        Creates a temporary file in the same directory, then renames it.

    Example::

        >>> atomic_write(Path("/tmp/important.json"), '{"status": "ok"}')
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_path_str = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    tmp_path = Path(tmp_path_str)
    try:
        with open(fd, "w", encoding=encoding) as f:
            f.write(content)
        tmp_path.replace(path)
    except Exception:
        tmp_path.unlink(missing_ok=True)
        raise
```

---

## See Also

- [`tools/serialization.md`](serialization.md) — parse file contents as JSON, CSV, or TOML
- [`tools/hashing-encoding.md`](hashing-encoding.md) — hash strings (not files)
- [`skills/logging-observability.md`](../skills/logging-observability.md) — log file operations
