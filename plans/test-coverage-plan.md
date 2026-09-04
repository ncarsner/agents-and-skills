# Test Coverage Plan

This file lists every module and script in the repository that requires test
coverage. The test-coverage Ralph loop reads this file on every iteration to
decide what to test next.

---

## Status

Coverage baseline: NONE, no tests exist yet for this repository.
Target: 100% statement coverage on all Python modules; syntax-validity checks
on all shell scripts.

---

## Shell Scripts

Test with `bats` (Bash Automated Testing System) or inline assertions.
Each script must be verified with `bash -n <script>` at minimum.

### ralph.sh (repo root)
File: `ralph.sh`
Tests needed:
- Exits 1 with usage message when no argument provided
- Exits 0 on success when `claude -p` returns exit 0
- Detects `<promise>COMPLETE</promise>` in output and exits 0
- Respects `--max N` flag: stops after N iterations on repeated failure
- `--pause` flag: prompts user on failure (integration test, skip in CI)
- `--goal <file>` flag: reads task from file correctly
- CTRL+C (SIGINT) during run: prompts retry/abort instead of hard exit

### plans/test-coverage-ralph.sh
File: `plans/test-coverage-ralph.sh`
Tests needed:
- Exits 1 with usage message when iteration count not provided
- Detects `<promise>COMPLETE</promise>` and exits 0 before exhausting iterations
- Iterates correct number of times without early exit when no completion signal

---

## Python Modules

<!-- ============================================================
     BOILERPLATE SECTION, READ BEFORE EDITING
     ============================================================
     When Python source files are added to this repository under src/,
     register them here. Each entry follows this template:

     ### <module-name>
     File: `src/<module>.py`
     Test file: `tests/test_<module>.py`
     Coverage target: 100%
     Tests needed:
     - <describe the user-facing behavior to test, not implementation details>
     - <error case: what happens when X is missing/invalid>
     - <edge case: what happens at the boundary>

     The test-coverage Ralph loop uses this section to find untested modules.
     When a module reaches 100% coverage, mark it:
       Coverage status: COMPLETE

     Agent instructions:
     - Write one test per iteration (see test-coverage-ralph.sh).
     - Tests go in tests/test_<module>.py.
     - Use pytest fixtures for shared setup; pytest.mark.parametrize for data-driven cases.
     - Mock all external I/O (network, filesystem, DB) with unittest.mock or pytest-mock.
     - Run: python3 -m pytest --cov=src --cov-fail-under=100 after each test.
     - Run: ruff format <test-file> && ruff check --fix <test-file> after each test.
     - Commit: test(<module>): <describe the user behavior being tested>
     ============================================================ -->

No Python modules exist yet. When src/ is created, register modules above.

---

## Coverage Commands

```bash
# Run full suite with coverage report
python3 -m pytest --cov=src --cov-fail-under=100 --cov-report=term-missing

# Run single test file
python3 -m pytest tests/test_<module>.py -v

# Check shell script syntax
bash -n ralph.sh
bash -n plans/test-coverage-ralph.sh

# Install bats for shell testing (if testing .sh files beyond syntax)
# brew install bats-core
```

---

## Completion Criteria

The test-coverage Ralph loop outputs `<promise>COMPLETE</promise>` when:
1. All Python modules listed above show "Coverage status: COMPLETE"
2. `python3 -m pytest --cov=src --cov-fail-under=100` exits 0
3. `bash -n ralph.sh && bash -n plans/test-coverage-ralph.sh` both exit 0
4. `mypy src/` exits 0
