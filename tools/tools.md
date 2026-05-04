# Tools Reference

This directory contains **deterministic code tools** for Python agents: ready-to-use
functions and patterns where the same inputs always produce the same outputs. No LLM
calls, no network I/O, no non-deterministic state.

Use these when a task calls for precision over inference — parsing, formatting,
transforming, hashing, sorting, or computing known quantities.

---

## What Is a Tool (vs. a Skill)?

| Dimension | Skill (`skills/`) | Tool (`tools/`) |
|-----------|-------------------|-----------------|
| Purpose | Guidance + patterns | Copy-pasteable code |
| Output | Recommended approach | Deterministic function |
| State | Stateless protocol | Pure / side-effect-free |
| Testing | Shows test patterns | Includes inline examples |

---

## Tool File Index

| Topic | File | Use when you need to… |
|-------|------|-----------------------|
| Collections | [`collections.md`](collections.md) | Count, group, deduplicate, or structure data |
| Date & Time | [`datetime.md`](datetime.md) | Parse, format, or compute dates and durations |
| File I/O | [`file-io.md`](file-io.md) | Read, write, or traverse files and directories |
| Serialization | [`serialization.md`](serialization.md) | Parse or emit JSON, CSV, or TOML |
| String Processing | [`string-processing.md`](string-processing.md) | Clean, match, extract, or transform text |
| Itertools & Functools | [`itertools-functools.md`](itertools-functools.md) | Compose, chunk, flatten, or memoize iterables |
| Math & Statistics | [`math-statistics.md`](math-statistics.md) | Aggregate, round, clamp, or compute distributions |
| Hashing & Encoding | [`hashing-encoding.md`](hashing-encoding.md) | Hash (SHA-256/HMAC), encode, decode, or generate identifiers |

---

## Usage Protocol

1. **Locate** the topic file that covers your need.
2. **Copy** the relevant function(s) verbatim into your module.
3. **Import** only what you use — no tool file should be imported as a module.
4. **Test** the copied function against the examples in its docstring.
5. **Adapt** only the parameters, never the algorithm, unless you verify correctness.

---

## Quality Guarantees

Every function in this directory:

- Has full type annotations on all parameters and return values.
- Has a Google-style docstring with at least one `Example::` block.
- Is pure (no global mutation, no I/O) or clearly annotates its side effects.
- Has been verified against the examples in its docstring.
- Uses only Python standard library unless a dependency is explicitly noted.

---

## Adding a New Tool

1. Place it in the appropriate topic file (or create a new one following the template below).
2. Ensure it meets all quality guarantees above.
3. Add a row to the index table in this file.

### New topic file template

```markdown
# Tools: <Topic>

One sentence describing what category of problems these tools solve.

---

## <Function Name>

Brief description.

\```python
def function_name(param: type) -> return_type:
    """One-line summary.

    Args:
        param: Description.

    Returns:
        Description.

    Example::

        >>> function_name(value)
        expected_output
    """
    ...
\```

---

## See Also

- [`tools/<related>.md`](<related>.md)
- [`skills/<related>.md`](../skills/<related>.md)
```

---

## See Also

- [`skills/skills.md`](../skills/skills.md) — skill registry and invocation protocol
- [`RULES.md`](../RULES.md) — coding standards all generated code must meet
- [`subagents/testing-agent.md`](../subagents/testing-agent.md) — writing tests for tool functions
