#!/usr/bin/env bash
# ralph-loop.sh — charge's default loop harness: fresh context per pass, a JSON
# state file as the single authority, deterministic stall detection, honest exits.
#
# Runs an agent on the SAME prompt repeatedly, each pass a FRESH process (a new
# context window — context never accumulates; the intelligence is in the files
# and git history the previous pass left behind). Between passes the harness —
# this script, never the agent — checks progress and decides: go again, or stop
# at a named terminal state.
#
# STATE: a JSON file (default loop-state.json; template in
# ../assets/loop-state.template.json). The contract: agents may ONLY flip
# features[].passes false->true (plus .evidence), with real command output as
# evidence. Everything else — attempts, blocked, harness.* — is written by this
# script. A free-text loop-log.md may carry narrative; it is NEVER authority.
#
# TERMINAL STATES / EXIT CODES (never dress one as another):
#   0 DONE            zero features[].passes==false remain AND the -v verify
#                     command exits 0, output surfaced in the log
#   3 STALLED         -N consecutive empty-diff passes, identical verify-failure
#                     signatures, or identical agent result outputs
#                     (harness-detected), or the agent reported the stall
#   4 EXHAUSTED       the -n iteration cap hit. Harness-detected only — the
#                     agent cannot observe its own cap.
#   5 BLOCKED         agent needs a decision/access/tool, or every remaining
#                     feature is attempt-capped
#   6 NEEDS-APPROVAL  a gated action is staged and described; the human fires it
#
# SIGILS — the agent ends its result with at most one line (no sigil = run me
# again). Parsed from the result stream: stream-json results are extracted via
# jq 'select(.type=="result")'; plain output is read as-is.
#   SIGIL: DONE
#   SIGIL: BLOCKED <the missing decision/access/tool>
#   SIGIL: NEEDS-APPROVAL <the staged gated action — prepared, never executed>
#   SIGIL: STALLED <the repeating obstacle>
# A DONE sigil is a CLAIM, not a verdict: the harness accepts it only when jq
# shows zero passes:false in the state file AND the verify command exits 0.
# A premature DONE just keeps looping.
#
# USAGE:
#   ./ralph-loop.sh [-p PROMPT_FILE] [-f STATE_FILE] [-n MAX_ITERS]
#                   [-v "VERIFY_CMD"] [-N STALL_N] [-A ATTEMPT_CAP]
#                   [-l LOGFILE] [-s SLEEP_SECS] [-- AGENT...]
#
#   -p  prompt file fed each pass              (default: PROMPT.md)
#   -f  JSON state file                        (default: loop-state.json)
#   -n  max iterations — the hard cap          (default: 20)  <-- always set one
#   -v  verify command; gates DONE and feeds failure-signature stall detection
#       (e.g. -v "./stop-check.sh -r 'npm test' -r 'npm run lint'").
#       Strongly recommended: without it DONE rests on the state file alone.
#   -N  stall threshold: consecutive empty-diff passes, identical verify-failure
#       signatures, or identical agent result outputs before exiting STALLED
#                                              (default: 3)
#   -A  per-feature attempt cap: a feature at this many attempts with passes
#       still false and an empty diff is marked blocked and skipped (default: 5)
#   -l  log file (all output tee'd here)       (default: ralph-run.log)
#   -s  seconds between passes                 (default: 2)
#   --  agent command (default: claude -p). Confirm your CLI's non-interactive
#       flag (codex exec for Codex). Add --dangerously-skip-permissions ONLY
#       when the whole process runs inside isolation (container/VM/sandbox).
#
# SAFETY: this runs an agent unattended. Use a worktree / claude/ branch inside
# whole-process isolation, keep gated actions (deploy/send/money/delete/schema)
# behind NEEDS-APPROVAL, and WATCH the first few passes.
# See ../references/guardrails.md.

set -uo pipefail

PROMPT_FILE="PROMPT.md"
STATE_FILE="loop-state.json"
MAX_ITERS=20
VERIFY_CMD=""
STALL_N=3
ATTEMPT_CAP=5
LOGFILE="ralph-run.log"
SLEEP_SECS=2
AGENT=(claude -p)

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p) PROMPT_FILE="$2"; shift 2 ;;
    -f) STATE_FILE="$2"; shift 2 ;;
    -n) MAX_ITERS="$2"; shift 2 ;;
    -v) VERIFY_CMD="$2"; shift 2 ;;
    -N) STALL_N="$2"; shift 2 ;;
    -A) ATTEMPT_CAP="$2"; shift 2 ;;
    -l) LOGFILE="$2"; shift 2 ;;
    -s) SLEEP_SECS="$2"; shift 2 ;;
    --) shift; AGENT=("$@"); break ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "jq is required (state-file machinery)" >&2; exit 2; }
[[ -f "$PROMPT_FILE" ]] || { echo "Prompt file not found: $PROMPT_FILE" >&2; exit 2; }
[[ -f "$STATE_FILE" ]] || { echo "State file not found: $STATE_FILE — copy assets/loop-state.template.json and fill in goal + features[]" >&2; exit 2; }
jq -e '(.features | type == "array") and (.features | length > 0)' "$STATE_FILE" >/dev/null 2>&1 \
  || { echo "State file needs a non-empty features[] array (see assets/loop-state.template.json)" >&2; exit 2; }
[[ "$MAX_ITERS" =~ ^[0-9]+$ && "$MAX_ITERS" -gt 0 ]] || { echo "MAX_ITERS must be a positive integer" >&2; exit 2; }

HAVE_GIT=0
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then HAVE_GIT=1; fi
[[ "$HAVE_GIT" -eq 1 ]] || echo "[ralph] WARNING: not a git repo — empty-diff stall detection disabled" >&2

hash_str() { { if command -v sha1sum >/dev/null 2>&1; then sha1sum; else shasum -a 1; fi; } | cut -d' ' -f1; }

now() { date -u +%FT%TZ; }

jstate() { # jstate 'FILTER' [--arg k v ...] — in-place jq edit of the state file
  local filter="$1"; shift
  local tmp; tmp="$(mktemp)"
  if jq "$@" "$filter" "$STATE_FILE" > "$tmp" 2>>"$LOGFILE"; then mv "$tmp" "$STATE_FILE"; else rm -f "$tmp"; fi
}

failing_count() { jq '[.features[] | select(.passes == false)] | length' "$STATE_FILE"; }

pick_feature() { # the same deterministic rule the prompt gives the agent:
  jq -r '[.features[] | select(.passes == false and ((.blocked // false) | not))][0].id // empty' "$STATE_FILE"
}

change_sig() { # signature of "did anything real change": HEAD + status + diff, EXCLUDING
  # the files the harness/agent mutate every pass regardless of progress (the state
  # file, this log, the narrative log) — plus the features' passes/blocked values,
  # so a legitimate passes flip counts as progress even with no code diff.
  {
    git rev-parse HEAD 2>/dev/null
    git status --porcelain=v1 -- . ":(exclude)$STATE_FILE" ":(exclude)$LOGFILE" ":(exclude)loop-log.md" 2>/dev/null
    git diff HEAD -- . ":(exclude)$STATE_FILE" ":(exclude)$LOGFILE" ":(exclude)loop-log.md" 2>/dev/null
    jq -S '[.features[] | {id, passes, blocked}]' "$STATE_FILE" 2>/dev/null
  } | hash_str
}

extract_result() { # stdin: raw agent output -> stream-json result text if present, else raw
  local raw res
  raw="$(cat)"
  res="$(printf '%s\n' "$raw" | jq -Rr 'fromjson? | select(type == "object" and .type? == "result") | (.result // empty)' 2>/dev/null)" || res=""
  if [[ -n "$res" ]]; then printf '%s\n' "$res"; else printf '%s\n' "$raw"; fi
}

write_terminal() { # $1 = state, $2 = detail — the harness, not the agent, records how the run ended
  jstate '.harness.terminal = $t | .harness.terminal_detail = $d | .harness.updated = $u' \
    --arg t "$1" --arg d "$2" --arg u "$(now)"
  echo "[ralph] $1 — $2" | tee -a "$LOGFILE"
}

confirm_done() { # DONE = zero passes:false (checked via jq) AND verify exits 0, output surfaced
  local failing; failing="$(failing_count)"
  if [[ "$failing" -ne 0 ]]; then
    echo "[ralph] DONE rejected — $failing feature(s) still passes:false." | tee -a "$LOGFILE"
    return 1
  fi
  if [[ -n "$VERIFY_CMD" ]]; then
    echo "[ralph] verifying: $VERIFY_CMD" | tee -a "$LOGFILE"
    if bash -c "$VERIFY_CMD" 2>&1 | tee -a "$LOGFILE"; then
      return 0
    fi
    echo "[ralph] DONE rejected — verify command failed." | tee -a "$LOGFILE"
    return 1
  fi
  echo "[ralph] WARNING: no -v verify command — DONE rests on the state file alone." | tee -a "$LOGFILE"
  return 0
}

trap 'echo; echo "[ralph] interrupted — stopping."; exit 130' INT

# Resume detection state from disk — the harness itself may have been restarted.
last_change_sig="$(jq -r '.harness.last_change_sig // empty' "$STATE_FILE")"
last_failure_sig="$(jq -r '.harness.last_failure_sig // empty' "$STATE_FILE")"
last_result_sig="$(jq -r '.harness.last_result_sig // empty' "$STATE_FILE")"
empty_streak="$(jq -r '.harness.empty_diff_streak // 0' "$STATE_FILE")"
failure_streak="$(jq -r '.harness.failure_streak // 0' "$STATE_FILE")"
result_streak="$(jq -r '.harness.result_streak // 0' "$STATE_FILE")"

echo "[ralph] prompt=$PROMPT_FILE state=$STATE_FILE max_iters=$MAX_ITERS stall_n=$STALL_N attempt_cap=$ATTEMPT_CAP verify=${VERIFY_CMD:-<none>}" | tee -a "$LOGFILE"
echo "[ralph] agent: ${AGENT[*]}" | tee -a "$LOGFILE"

for ((i=1; i<=MAX_ITERS; i++)); do
  echo "" | tee -a "$LOGFILE"
  echo "===== pass $i / $MAX_ITERS  $(now) =====" | tee -a "$LOGFILE"

  # Pre-pass: don't pay for a pass the state file already proves unnecessary.
  if [[ "$(failing_count)" -eq 0 ]]; then
    if confirm_done; then write_terminal DONE "all features pass + verify green (pre-pass check, pass $i)"; exit 0; fi
    echo "[ralph] state says all pass but verify disagrees — continuing so a pass can reconcile them." | tee -a "$LOGFILE"
  fi

  # Which feature will this pass work on? (same first-failing-unblocked rule as the prompt)
  fid="$(pick_feature)"
  if [[ -z "$fid" && "$(failing_count)" -gt 0 ]]; then
    blocked_list="$(jq -r '[.features[] | select(.passes == false) | .id] | join(", ")' "$STATE_FILE")"
    write_terminal BLOCKED "every remaining feature is attempt-capped: $blocked_list — needs a human decision"
    exit 5
  fi

  # Fresh context: pipe the prompt into a brand-new agent process.
  out="$("${AGENT[@]}" < "$PROMPT_FILE" 2>&1 | tee -a "$LOGFILE")"
  agent_code=$?
  [[ "$agent_code" -eq 0 ]] || echo "[ralph] agent exited $agent_code — treating as a pass with no claim." | tee -a "$LOGFILE"
  result_text="$(printf '%s' "$out" | extract_result)"

  # Result-stream signature — an agent emitting the identical result every pass
  # (same error, same refusal, same empty output) is spinning even if git churns.
  result_sig="$(printf '%s' "$result_text" | hash_str)"
  if [[ -n "$last_result_sig" && "$result_sig" == "$last_result_sig" ]]; then
    result_streak=$((result_streak + 1))
  else
    result_streak=1
  fi
  last_result_sig="$result_sig"

  # (a) Empty-diff detection — did this pass change anything at all?
  empty_pass=0
  if [[ "$HAVE_GIT" -eq 1 ]]; then
    cur_sig="$(change_sig)"
    if [[ -n "$last_change_sig" && "$cur_sig" == "$last_change_sig" ]]; then
      empty_pass=1
      empty_streak=$((empty_streak + 1))
    else
      empty_streak=0
    fi
    last_change_sig="$cur_sig"
  fi

  # (b) Per-feature attempt accounting — harness-written; agents never touch these fields.
  if [[ -n "$fid" ]]; then
    jstate '.features |= map(if .id == $id then .attempts = ((.attempts // 0) + 1) else . end)' --arg id "$fid"
    still_failing="$(jq -r --arg id "$fid" '[.features[] | select(.id == $id)][0].passes == false' "$STATE_FILE")"
    attempts="$(jq -r --arg id "$fid" '[.features[] | select(.id == $id)][0].attempts // 0' "$STATE_FILE")"
    if [[ "$empty_pass" -eq 1 && "$still_failing" == "true" && "$attempts" -ge "$ATTEMPT_CAP" ]]; then
      jstate '.features |= map(if .id == $id then .blocked = true | .blocked_reason = $r else . end)' \
        --arg id "$fid" --arg r "no diff after $attempts attempts (cap $ATTEMPT_CAP), pass $i"
      echo "[ralph] feature '$fid' blocked after $attempts attempts with no progress — will be skipped, not re-picked." | tee -a "$LOGFILE"
    fi
  fi

  # (c) Sigil parsing from the result stream.
  sigil="$(printf '%s\n' "$result_text" | grep -E '^SIGIL: (DONE|BLOCKED|NEEDS-APPROVAL|STALLED)' | tail -n 1)" || sigil=""
  case "$sigil" in
    "SIGIL: DONE"*)
      if confirm_done; then write_terminal DONE "sigil confirmed on pass $i — zero passes:false + verify green"; exit 0; fi
      echo "[ralph] premature DONE sigil — continuing." | tee -a "$LOGFILE" ;;
    "SIGIL: BLOCKED"*)
      write_terminal BLOCKED "${sigil#SIGIL: BLOCKED }"; exit 5 ;;
    "SIGIL: NEEDS-APPROVAL"*)
      write_terminal NEEDS-APPROVAL "${sigil#SIGIL: NEEDS-APPROVAL }"
      echo "[ralph] the loop prepared the action but did NOT execute it — review it, fire it yourself, then re-run." | tee -a "$LOGFILE"
      exit 6 ;;
    "SIGIL: STALLED"*)
      write_terminal STALLED "agent-reported: ${sigil#SIGIL: STALLED }"; exit 3 ;;
  esac

  # (d) Verify + failure-signature detection (deterministic — a hash, never a judgement).
  if [[ -n "$VERIFY_CMD" ]]; then
    vout="$(bash -c "$VERIFY_CMD" 2>&1)"
    vcode=$?
    printf '%s\n' "$vout" >> "$LOGFILE"
    if [[ "$vcode" -eq 0 && "$(failing_count)" -eq 0 ]]; then
      write_terminal DONE "verify green + zero passes:false on pass $i"
      exit 0
    fi
    if [[ "$vcode" -ne 0 ]]; then
      cur_fsig="$(printf '%s' "$vout" | hash_str)"
      if [[ -n "$last_failure_sig" && "$cur_fsig" == "$last_failure_sig" ]]; then
        failure_streak=$((failure_streak + 1))
      else
        failure_streak=1
      fi
      last_failure_sig="$cur_fsig"
    else
      failure_streak=0
      last_failure_sig=""
    fi
  fi

  # (e) Persist detection state so a restarted harness resumes, not restarts.
  jstate '.harness.iteration = ($i | tonumber)
        | .harness.empty_diff_streak = ($es | tonumber)
        | .harness.failure_streak = ($fs | tonumber)
        | .harness.result_streak = ($rs | tonumber)
        | .harness.last_change_sig = (if $cs == "" then null else $cs end)
        | .harness.last_failure_sig = (if $fsig == "" then null else $fsig end)
        | .harness.last_result_sig = (if $rsig == "" then null else $rsig end)
        | .harness.updated = $u' \
    --arg i "$i" --arg es "$empty_streak" --arg fs "$failure_streak" --arg rs "$result_streak" \
    --arg cs "${last_change_sig:-}" --arg fsig "${last_failure_sig:-}" \
    --arg rsig "${last_result_sig:-}" --arg u "$(now)"

  # (f) Stall exits — the cheap third exit that fires before the cap burns out.
  if [[ "$HAVE_GIT" -eq 1 && "$empty_streak" -ge "$STALL_N" ]]; then
    write_terminal STALLED "no working-tree or commit change for $empty_streak consecutive passes"
    exit 3
  fi
  if [[ -n "$VERIFY_CMD" && "$failure_streak" -ge "$STALL_N" ]]; then
    write_terminal STALLED "identical verify-failure signature for $failure_streak consecutive passes"
    exit 3
  fi
  if [[ "$result_streak" -ge "$STALL_N" ]]; then
    write_terminal STALLED "identical agent result output for $result_streak consecutive passes"
    exit 3
  fi

  sleep "$SLEEP_SECS"
done

write_terminal EXHAUSTED "iteration cap $MAX_ITERS hit with $(failing_count) feature(s) still failing"
exit 4
