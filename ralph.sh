#!/usr/bin/env bash
# ralph.sh — Agent loop: run a Claude task repeatedly until success.
# Pattern: https://ghuntley.com/loop/
#
# Usage (general):
#   ./ralph.sh "task description"
#   ./ralph.sh --goal goal.md
#   ./ralph.sh --max 10 --pause "refactor src/pipeline.py"
#
# Usage (PRD-driven):
#   ./ralph.sh --prd plans/prd.json
#   ./ralph.sh --prd plans/my-project-prd.json --max 5
#
# Env vars:
#   RALPH_TOOLS   Comma-separated Claude allowed tools (default below; unused in --prd mode)
#   RALPH_MODEL   Claude model override

set -uo pipefail

# ── defaults ──────────────────────────────────────────────────────────────────
TOOLS="${RALPH_TOOLS:-Read,Edit,Write,Bash}"
MODEL="${RALPH_MODEL:-claude-sonnet-4-6}"
MAX_ITERATIONS=0   # 0 = unlimited (general mode); overridden to 20 in --prd mode
PAUSE_ON_FAIL=false
GOAL_FILE=""
PRD_FILE=""
TASK=""
LOG_DIR="$(dirname "$0")/_SOLUTIONS"
WIKI_LOG="$(dirname "$0")/log.md"

# ── arg parsing ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max)    MAX_ITERATIONS="$2"; shift 2 ;;
        --pause)  PAUSE_ON_FAIL=true;  shift   ;;
        --goal)   GOAL_FILE="$2";      shift 2 ;;
        --prd)    PRD_FILE="$2";       shift 2 ;;
        --tools)  TOOLS="$2";          shift 2 ;;
        --model)  MODEL="$2";          shift 2 ;;
        --help|-h)
            sed -n '2,14p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) TASK="$1"; shift ;;
    esac
done

# ── resolve task source ───────────────────────────────────────────────────────
if [[ -n "$PRD_FILE" ]]; then
    [[ -f "$PRD_FILE" ]] || { echo "PRD file not found: $PRD_FILE" >&2; exit 1; }
    [[ "$MAX_ITERATIONS" -eq 0 ]] && MAX_ITERATIONS=20
elif [[ -n "$GOAL_FILE" ]]; then
    [[ -f "$GOAL_FILE" ]] || { echo "Goal file not found: $GOAL_FILE" >&2; exit 1; }
    TASK="$(cat "$GOAL_FILE")"
fi

if [[ -z "$PRD_FILE" && -z "$TASK" ]]; then
    echo "Error: no task provided. Use a quoted string, --goal <file>, or --prd <file>." >&2
    exit 1
fi

# ── setup ─────────────────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR"
touch "$WIKI_LOG"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d)-ralph-loop.log"
START_TIME="$(date +%Y-%m-%dT%H:%M:%S)"
TASK_SLUG="$(echo "$TASK" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/-\+/-/g; s/^-//; s/-$//' | cut -c1-40)"

log() { echo "$@" | tee -a "$LOG_FILE"; }

log "═══════════════════════════════════════════"
log "ralph loop started: $START_TIME"
if [[ -n "$PRD_FILE" ]]; then
    log "mode: PRD  file: $PRD_FILE"
else
    log "task: $TASK"
    log "tools: $TOOLS"
fi
log "wiki log: $WIKI_LOG"
log "model: $MODEL"
[[ "$MAX_ITERATIONS" -gt 0 ]] && log "max iterations: $MAX_ITERATIONS"
log "log: $LOG_FILE"
log "═══════════════════════════════════════════"

# ── signal handling ───────────────────────────────────────────────────────────
interrupted=false
trap 'interrupted=true' INT

# ── loop ──────────────────────────────────────────────────────────────────────
iteration=0

while true; do
    ((iteration++)) || true
    ts="$(date +%H:%M:%S)"
    log ""
    log "── iteration $iteration ($ts) ──────────────────────"

    if [[ -n "$PRD_FILE" ]]; then
        # PRD mode: capture output to detect COMPLETE signal; use acceptEdits
        result=$(claude \
            --model "$MODEL" \
            --permission-mode acceptEdits \
            -p "@${PRD_FILE} @${WIKI_LOG} @RULES.md
TASK:
1. Read ${PRD_FILE}. Find the task with done:false and the lowest priority number.
   If all tasks have done:true, output <promise>COMPLETE</promise> and stop.
2. Read only the files listed in that task's files_affected field.
3. Complete the task following its steps in order.
4. Verify every item in acceptance_criteria is satisfied. Fix any failures before continuing.
5. For shell scripts: bash -n <script>. For Python files changed: ruff format <f> && ruff check --fix <f> && mypy src/ && python3 -m pytest -x
6. Set done:true for the completed task in ${PRD_FILE}.
7. Append one line to ${WIKI_LOG} under '## Entries', following its documented schema:
   [\$(date -u +%Y-%m-%dT%H:%M:%SZ)] [<task-id>] [done] [<count of prior 'blocked' entries for this task-id in ${WIKI_LOG}>] <what changed>
8. Commit using Conventional Commits format matching the task's final step.
CONSTRAINTS: one task per iteration; modify only files_affected plus ${WIKI_LOG}; no agent attribution in commits (RULES.md §6)." \
            2>&1)
        rc=$?
        echo "$result" | tee -a "$LOG_FILE"

        if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
            log ""
            log "✓ All PRD tasks complete after $iteration iteration(s)."
            exit 0
        fi

        if [[ "$rc" -ne 0 ]]; then
            log "✗ failed (exit $rc)"
        fi
    else
        # General mode: stream output in real time
        if claude -p "$TASK" \
            --model "$MODEL" \
            --allowedTools "$TOOLS" \
            2>&1 | tee -a "$LOG_FILE"; then

            elapsed=$(( $(date +%s) - $(date -j -f '%Y-%m-%dT%H:%M:%S' "$START_TIME" +%s 2>/dev/null || date -d "$START_TIME" +%s) ))
            log ""
            log "✓ success — iteration $iteration  elapsed: ${elapsed}s"
            printf '[%s] [%s] [done] [%d] %s\n' \
                "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TASK_SLUG" "$((iteration - 1))" "${TASK:0:80}" >> "$WIKI_LOG"
            exit 0
        fi
        log "✗ failed (exit ${PIPESTATUS[0]})"
        printf '[%s] [%s] [blocked] [%d] %s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TASK_SLUG" "$iteration" "${TASK:0:80}" >> "$WIKI_LOG"
    fi

    if $interrupted; then
        log "Interrupted by user."
        read -r -p "  [r]etry / [a]bort? " choice </dev/tty
        case "$choice" in
            r|R) interrupted=false; log "Resuming..." ;;
            *)   log "Aborted at iteration $iteration."; exit 130 ;;
        esac
    elif $PAUSE_ON_FAIL; then
        read -r -p "  Failed. [Enter] to retry, Ctrl+C to abort: " </dev/tty
    fi

    if [[ "$MAX_ITERATIONS" -gt 0 && "$iteration" -ge "$MAX_ITERATIONS" ]]; then
        log "Max iterations ($MAX_ITERATIONS) reached without success."
        if [[ -z "$PRD_FILE" ]]; then
            printf '[%s] [%s] [failed] [%d] %s (max iterations reached)\n' \
                "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TASK_SLUG" "$iteration" "${TASK:0:80}" >> "$WIKI_LOG"
        fi
        exit 1
    fi
done
