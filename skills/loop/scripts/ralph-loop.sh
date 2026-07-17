#!/usr/bin/env bash
# ralph-loop.sh — portable "drive to done" loop for any agent CLI.
#
# Runs an agent on the SAME prompt repeatedly, each pass in a FRESH context
# window, until the agent prints a completion promise AND (optionally) a
# verification command passes — or a hard iteration cap is hit. Progress is
# carried between passes by the filesystem + git (have your prompt read/write
# LOOP-STATE.md), NOT by a growing context. This is the fallback for when
# /goal's no-tools evaluator or context growth would break a long run.
#
# Why fresh context each pass: a single ever-growing session costs more and
# degrades; starting clean and re-reading LOOP-STATE.md + the repo keeps every
# pass sharp. The intelligence is in the files/git the previous pass left behind.
#
# USAGE:
#   ./ralph-loop.sh [-p PROMPT_FILE] [-n MAX_ITERS] [-c PROMISE]
#                   [-v "VERIFY_CMD"] [-l LOGFILE] [-s SLEEP_SECS] [-- AGENT...]
#
#   -p  prompt file fed each pass            (default: PROMPT.md)
#   -n  max iterations — the hard cap        (default: 20)   <-- always set one
#   -c  completion promise to look for       (default: DONE)
#   -v  verification command; must exit 0 before the promise is accepted
#       (e.g. -v "npm test && npm run lint"). Optional but strongly recommended:
#       it stops the agent from faking the finish.
#   -l  log file (all output is tee'd here)  (default: ralph-run.log)
#   -s  seconds to sleep between passes      (default: 2)
#   --  everything after is the agent command (default: claude -p)
#       Confirm your CLI's non-interactive flag; e.g. `codex exec` for Codex.
#
# EXAMPLE:
#   ./ralph-loop.sh -n 15 -c DONE -v "npm test && npm run lint" -p PROMPT.md
#
# SAFETY: this runs an agent unattended. Use a worktree / claude/ branch, keep
# destructive+production+external actions gated (the agent should pause for
# those, not do them), set a budget at the account level, and WATCH the first
# few passes. See references/guardrails.md.

set -euo pipefail

PROMPT_FILE="PROMPT.md"
MAX_ITERS=20
PROMISE="DONE"
VERIFY_CMD=""
LOGFILE="ralph-run.log"
SLEEP_SECS=2
AGENT=(claude -p)

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p) PROMPT_FILE="$2"; shift 2 ;;
    -n) MAX_ITERS="$2"; shift 2 ;;
    -c) PROMISE="$2"; shift 2 ;;
    -v) VERIFY_CMD="$2"; shift 2 ;;
    -l) LOGFILE="$2"; shift 2 ;;
    -s) SLEEP_SECS="$2"; shift 2 ;;
    --) shift; AGENT=("$@"); break ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -f "$PROMPT_FILE" ]] || { echo "Prompt file not found: $PROMPT_FILE" >&2; exit 2; }
[[ "$MAX_ITERS" =~ ^[0-9]+$ && "$MAX_ITERS" -gt 0 ]] || { echo "MAX_ITERS must be a positive integer" >&2; exit 2; }

trap 'echo; echo "[ralph] interrupted — stopping."; exit 130' INT

echo "[ralph] prompt=$PROMPT_FILE  max_iters=$MAX_ITERS  promise=\"$PROMISE\"  verify=${VERIFY_CMD:-<none>}" | tee "$LOGFILE"
echo "[ralph] agent: ${AGENT[*]}" | tee -a "$LOGFILE"

last_hash=""
nochange_streak=0

for ((i=1; i<=MAX_ITERS; i++)); do
  echo "" | tee -a "$LOGFILE"
  echo "===== pass $i / $MAX_ITERS  $(date -u +%FT%TZ) =====" | tee -a "$LOGFILE"

  # Fresh context each pass: pipe the prompt into a new agent invocation.
  out="$("${AGENT[@]}" < "$PROMPT_FILE" 2>&1 | tee -a "$LOGFILE")"

  # No-progress guard: if the working tree hasn't changed for 3 passes, stop.
  if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    cur_hash="$(git status --porcelain=v1 2>/dev/null | sha1sum | cut -d' ' -f1)"
    if [[ "$cur_hash" == "$last_hash" ]]; then
      nochange_streak=$((nochange_streak + 1))
    else
      nochange_streak=0
    fi
    last_hash="$cur_hash"
    if [[ "$nochange_streak" -ge 3 ]]; then
      echo "[ralph] STALLED — no working-tree change for 3 passes. Stopping." | tee -a "$LOGFILE"
      exit 3
    fi
  fi

  # Did the agent claim completion this pass?
  if grep -qF "$PROMISE" <<<"$out"; then
    if [[ -n "$VERIFY_CMD" ]]; then
      echo "[ralph] promise seen — running verification: $VERIFY_CMD" | tee -a "$LOGFILE"
      if bash -c "$VERIFY_CMD" >>"$LOGFILE" 2>&1; then
        echo "[ralph] DONE — promise + verification passed on pass $i." | tee -a "$LOGFILE"
        exit 0
      else
        echo "[ralph] promise was premature — verification FAILED. Continuing." | tee -a "$LOGFILE"
      fi
    else
      echo "[ralph] DONE — promise seen on pass $i (no verify command set)." | tee -a "$LOGFILE"
      exit 0
    fi
  fi

  sleep "$SLEEP_SECS"
done

echo "[ralph] EXHAUSTED — hit max iterations ($MAX_ITERS) without completion." | tee -a "$LOGFILE"
exit 4
