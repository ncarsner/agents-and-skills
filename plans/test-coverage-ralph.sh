#!/usr/bin/env bash
# plans/test-coverage-ralph.sh — Test coverage Ralph loop for this repo.
#
# Each iteration: Claude reads test-coverage-plan.md, identifies the most
# important untested user-facing behavior, writes ONE test, verifies it
# passes, appends progress, and commits. Loop exits when 100% coverage is
# reached or iterations are exhausted.
#
# Usage:
#   ./plans/test-coverage-ralph.sh <iterations>
#   ./plans/test-coverage-ralph.sh 20
#
# Prerequisites:
#   uv sync                          # install all deps including dev
#   uv add --dev pytest pytest-cov   # if not already in pyproject.toml
#
# Env vars:
#   RALPH_MODEL   Claude model (default: claude-sonnet-4-6)

set -euo pipefail

ITERATIONS="${1:-}"
MODEL="${RALPH_MODEL:-claude-sonnet-4-6}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -z "$ITERATIONS" ]]; then
    echo "Usage: $0 <iterations>" >&2
    exit 1
fi

cd "$REPO_ROOT"

# ── pre-flight: verify test toolchain exists ──────────────────────────────────
if ! python3 -m pytest --version >/dev/null 2>&1; then
    echo "Error: pytest not found. Run: uv add --dev pytest pytest-cov" >&2
    exit 1
fi

for ((i=1; i<=ITERATIONS; i++)); do
    echo ""
    echo "══ test-coverage iteration $i / $ITERATIONS ══════════════════════"

    result=$(claude \
        --model "$MODEL" \
        --permission-mode acceptEdits \
        -p "@plans/test-coverage-plan.md @log.md @RULES.md
PROCESS — follow exactly, one step at a time:

1. ASSESS coverage.
   Run: python3 -m pytest --cov=src --cov-report=term-missing -q 2>&1 || true
   Also run: bash -n ralph.sh && bash -n plans/test-coverage-ralph.sh
   If ALL of the following are true, output <promise>COMPLETE</promise> and stop:
     - pytest --cov=src --cov-fail-under=100 exits 0
     - bash -n on all .sh files exits 0
     - mypy src/ exits 0 (if src/ exists)

2. IDENTIFY the target.
   Read plans/test-coverage-plan.md. Find the most important USER-FACING
   BEHAVIOR that has no test yet. Prefer behaviors that affect correctness
   over edge cases. Pick exactly one behavior.

3. WRITE one test.
   - File: tests/test_<module>.py (create if absent)
   - Function: test_<behavior_under_test> — name must describe the behavior
   - Use pytest fixtures for shared setup
   - Mock all external I/O (network, filesystem, subprocess) with unittest.mock
   - Follow RULES.md §7 testing conventions
   - Follow RULES.md §3 for type hints and docstrings on test functions

4. VERIFY the test passes.
   Run: python3 -m pytest tests/test_<module>.py -v
   If the test fails, fix it before continuing. Do not commit a failing test.

5. FORMAT and lint the test file.
   Run: ruff format tests/test_<module>.py && ruff check --fix tests/test_<module>.py
   Run: mypy src/ (if src/ exists)

6. CHECK coverage improved.
   Run: python3 -m pytest --cov=src --cov-report=term-missing -q
   Note the new coverage percentage.

7. UPDATE test-coverage-plan.md.
   If the tested module now has 100% coverage, mark it:
     Coverage status: COMPLETE

8. APPEND to log.md under '## Entries', following its documented schema:
   [\$(date -u +%Y-%m-%dT%H:%M:%SZ)] [test-coverage-iter-$i] [done] [0] tested: <behavior>, coverage: <N>%, file: <test-file>

9. COMMIT.
   git add tests/ plans/test-coverage-plan.md log.md
   git commit -m 'test(<module>): <describe the user behavior being tested>'

CONSTRAINTS:
- Write exactly ONE test per iteration.
- Test real user-facing behavior, not implementation internals.
- Never delete or comment out existing tests to make coverage pass.
- Never use # noqa or # type: ignore without a documented reason.
- No agent attribution in commits (RULES.md §6).
" 2>&1)

    echo "$result"

    if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
        echo ""
        echo "100% coverage reached after $i iteration(s)."
        exit 0
    fi
done

echo ""
echo "Reached $ITERATIONS iteration(s). Run again or check log.md."
exit 0
