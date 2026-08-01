#!/usr/bin/env bash
# stop-check.sh — deterministic "are we actually done?" gate.
#
# Exit 0 = done_when is satisfied (it's safe to stop).
# Exit non-zero = not done (keep looping). This is the tool-using checker you
# reach for when /goal's evaluator can't see the proof: wire it as a Claude Code
# Stop hook, or pass it to ralph-loop.sh via -v "/path/to/stop-check.sh".
#
# It runs three kinds of objective checks, all optional, all must pass:
#   1. A command that must exit 0        (-r "CMD", repeatable)
#   2. A string that must be ABSENT      (-a "REGEX[:PATH]", repeatable)
#   3. A path that must EXIST            (-e "PATH", repeatable)
#
# USAGE:
#   stop-check.sh -r "npm test" -r "npm run lint" \
#                 -a "from './legacy-api':src" \
#                 -e dist/index.js
#
# Customise the defaults below for your project, or pass flags. Keep checks
# OBJECTIVE — a command/exit-code/grep, never a judgement call. And remember the
# guard conditions: pair each narrowing check with what must not regress (e.g.
# require the test command to pass alongside the lint command), or the loop will
# satisfy the letter (lint clean) by violating the intent (deleting code).

set -uo pipefail

declare -a RUN=()       # commands that must exit 0
declare -a ABSENT=()    # "regex" or "regex:path" that must NOT be found
declare -a EXISTS=()    # paths that must exist

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) RUN+=("$2"); shift 2 ;;
    -a) ABSENT+=("$2"); shift 2 ;;
    -e) EXISTS+=("$2"); shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---- project defaults (edit these, or rely on flags) -----------------------
if [[ ${#RUN[@]} -eq 0 && ${#ABSENT[@]} -eq 0 && ${#EXISTS[@]} -eq 0 ]]; then
  # Example defaults — replace with your real done_when checks:
  RUN+=("echo 'no checks configured — edit stop-check.sh' ; false")
fi
# ----------------------------------------------------------------------------

fail=0

for cmd in "${RUN[@]}"; do
  echo "▶ run: $cmd"
  if bash -c "$cmd"; then echo "  ✅ exit 0"; else echo "  ❌ non-zero exit"; fail=1; fi
done

for pat in "${ABSENT[@]}"; do
  regex="${pat%%:*}"; path="."
  [[ "$pat" == *:* ]] && path="${pat#*:}"
  echo "▶ must be absent: /$regex/ in $path"
  if grep -RInE --binary-files=without-match "$regex" "$path" >/dev/null 2>&1; then
    echo "  ❌ found (still present)"; fail=1
  else
    echo "  ✅ none found"
  fi
done

for p in "${EXISTS[@]}"; do
  echo "▶ must exist: $p"
  if [[ -e "$p" ]]; then echo "  ✅ exists"; else echo "  ❌ missing"; fail=1; fi
done

if [[ "$fail" -eq 0 ]]; then
  echo "DONE — all checks passed."
  exit 0
else
  echo "NOT DONE — at least one check failed. Keep looping."
  exit 1
fi
