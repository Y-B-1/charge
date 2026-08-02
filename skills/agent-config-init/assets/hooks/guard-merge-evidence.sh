#!/usr/bin/env bash
# PreToolUse guard for the Bash tool. Blocks a merge that reaches the protected
# branch unless a FRESH full-suite marker exists: a passing exit code AND the
# sha the suite actually ran against, equal to current HEAD.
#
# Why a marker and not a sentence: evidence expiry written as prose has to be
# remembered every time. Written as a marker it is deterministic — any commit
# after the green run moves HEAD, the marker no longer matches, and this gate
# re-blocks by construction.
#
# The orchestrator writes the marker itself, from its own authoritative run:
#
#   <FULL-SUITE COMMAND>; printf '%s %s\n' "$?" "$(git rev-parse HEAD)" > .claude/.suite-pass
#
# (`$?` is the suite's exit code, so a red run writes a marker that this guard
# rejects — the marker records the result, it does not assert one.) Add
# `.claude/.suite-pass` to .gitignore: it is a fact about one machine's tree.
#
# Install:
#   cp guard-merge-evidence.sh .claude/hooks/ && chmod +x .claude/hooks/guard-merge-evidence.sh
# Wire it in .claude/settings.json — the timeout is REQUIRED, not optional.
# 10 s is ample: this hook runs two git plumbing commands and reads one small
# file. It never runs the suite itself.
#   { "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
#       { "type": "command",
#         "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/guard-merge-evidence.sh",
#         "timeout": 10 } ] } ] } }
#
# Configure by environment variable (defaults in the assignments below):
#   CHARGE_SUITE_MARKER   path to the marker, relative to the project dir
#   CHARGE_PROTECTED_BRANCH  the branch a merge must not reach unverified
#   CHARGE_SUITE_CMD      the command named in the failure text
#
# Contract: only exit 2 blocks (stderr is fed back to the agent). Exit 0 with
# no output is NO DECISION. Exit 1 is a non-blocking error and the action
# proceeds — which is why every failure path here exits 2, not 1. This guard
# fails CLOSED: a missing, malformed, red or stale marker blocks.
set -uo pipefail

# --- Bypass switch (for the human, never for the model) ----------------------
[ "${CLAUDE_PERMISSION_MODE:-}" = "bypassPermissions" ] && exit 0
[ "${CHARGE_YOLO:-0}" = "1" ] && exit 0
[ -f "${CLAUDE_PROJECT_DIR:-.}/.claude/.bypass-guards" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MARKER="$PROJECT_DIR/${CHARGE_SUITE_MARKER:-.claude/.suite-pass}"
PROTECTED="${CHARGE_PROTECTED_BRANCH:-main}"
SUITE_CMD="${CHARGE_SUITE_CMD:-<FULL-SUITE COMMAND>}"

# --- Extract the command -----------------------------------------------------
INPUT="$(cat)"
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
  [ -n "$CMD" ] || CMD="$INPUT"
else
  CMD="$INPUT"
fi

# --- Does this command reach the protected branch? ---------------------------
# 1. `gh pr merge` in any form — the PR's base is the protected branch often
#    enough that asking is not worth a network call.
# 2. `git merge <anything>` while checked out ON the protected branch.
# 3. `git push` of a local branch onto the protected ref (fast-forward merge by
#    another name).
is_merge=0
printf '%s' "$CMD" | grep -Eiq 'gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)' && is_merge=1

if [ "$is_merge" -eq 0 ] && printf '%s' "$CMD" | grep -Eiq 'git[[:space:]]+merge([[:space:]]|$)'; then
  CURRENT_BRANCH="$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
  [ "$CURRENT_BRANCH" = "$PROTECTED" ] && is_merge=1
fi

if [ "$is_merge" -eq 0 ] && \
   printf '%s' "$CMD" | grep -Eiq "git[[:space:]]+push[^|;&]*[[:space:]](HEAD|[A-Za-z0-9._/-]+):?${PROTECTED}([[:space:]]|$)"; then
  is_merge=1
fi

[ "$is_merge" -eq 1 ] || exit 0

deny() {
  echo "BLOCKED by .claude/hooks/guard-merge-evidence.sh: $1" >&2
  echo "" >&2
  echo "A merge reaching '$PROTECTED' needs a fresh full-suite marker: the suite's" >&2
  echo "exit code plus the sha it ran against, matching current HEAD." >&2
  echo "" >&2
  echo "Run the authoritative suite on THIS commit and record the result:" >&2
  echo "  $SUITE_CMD; printf '%s %s\\n' \"\$?\" \"\$(git rev-parse HEAD)\" > ${CHARGE_SUITE_MARKER:-.claude/.suite-pass}" >&2
  echo "" >&2
  echo "Do not write the marker by hand and do not retry the merge without it." >&2
  echo "If this is deliberate, ask the human to set CHARGE_YOLO=1." >&2
  exit 2
}

# --- Current HEAD -------------------------------------------------------------
HEAD_SHA="$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo '')"
[ -n "$HEAD_SHA" ] || deny "cannot resolve HEAD — no git repo here, so freshness cannot be proven"

# --- The marker ---------------------------------------------------------------
[ -f "$MARKER" ] || deny "no full-suite marker at ${CHARGE_SUITE_MARKER:-.claude/.suite-pass} — the suite has not run, or ran without recording"

read -r MARK_CODE MARK_SHA _rest < "$MARKER" 2>/dev/null || true
MARK_CODE="${MARK_CODE:-}"
MARK_SHA="${MARK_SHA:-}"

case "$MARK_CODE" in
  ''|*[!0-9]*) deny "marker is malformed (expected '<exit-code> <sha>', got '$MARK_CODE $MARK_SHA')" ;;
esac
[ -n "$MARK_SHA" ] || deny "marker carries no sha — it cannot be tied to a tree, so it is not evidence"

[ "$MARK_CODE" = "0" ] || \
  deny "the recorded full-suite run FAILED (exit $MARK_CODE). Fix the suite, do not merge red"

if [ "$MARK_SHA" != "$HEAD_SHA" ]; then
  deny "marker is stale: it proves ${MARK_SHA:0:12}, HEAD is ${HEAD_SHA:0:12}. A commit landed after the green run and voided it"
fi

exit 0

# --- Verify the guard ---------------------------------------------------------
# Fire-test both directions after wiring, and again after every settings.json
# edit. From the project root:
#   P='{"tool_name":"Bash","tool_input":{"command":"gh pr merge 12 --squash"}}'
#   rm -f .claude/.suite-pass;                        printf '%s' "$P" | .claude/hooks/guard-merge-evidence.sh; echo "no marker -> $?"      # 2
#   printf '0 %s\n' deadbeef > .claude/.suite-pass;   printf '%s' "$P" | .claude/hooks/guard-merge-evidence.sh; echo "stale sha -> $?"      # 2
#   printf '1 %s\n' "$(git rev-parse HEAD)" > .claude/.suite-pass
#                                                     printf '%s' "$P" | .claude/hooks/guard-merge-evidence.sh; echo "red suite -> $?"      # 2
#   printf '0 %s\n' "$(git rev-parse HEAD)" > .claude/.suite-pass
#                                                     printf '%s' "$P" | .claude/hooks/guard-merge-evidence.sh; echo "fresh pass -> $?"     # 0
#   printf '{"tool_name":"Bash","tool_input":{"command":"git status"}}' | .claude/hooks/guard-merge-evidence.sh; echo "unrelated -> $?"     # 0
