#!/usr/bin/env bash
# PreToolUse guard for the Bash tool. Blocks this project's MUST-NOT commands
# deterministically, before execution.
#
# Install:
#   cp guard-template.sh .claude/hooks/<NAME>.sh && chmod +x .claude/hooks/<NAME>.sh
# Wire it in .claude/settings.json — the timeout is REQUIRED, not optional:
#   { "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
#       { "type": "command",
#         "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/<NAME>.sh",
#         "timeout": 10 } ] } ] } }
#
# Contract: only exit 2 blocks (stderr is fed back to the agent).
# Exit 0 with no output is NO DECISION - the call continues through normal
# permission flow. Exit 1 is a non-blocking error and the action proceeds.
set -uo pipefail

# --- Bypass switch (for the human, never for the model) ----------------------
# Deliberate autonomous or maintenance runs must not be blocked by this guard.
[ "${CLAUDE_PERMISSION_MODE:-}" = "bypassPermissions" ] && exit 0
[ "${CHARGE_YOLO:-0}" = "1" ] && exit 0
[ -f "${CLAUDE_PROJECT_DIR:-.}/.claude/.bypass-guards" ] && exit 0

# --- Extract the command ------------------------------------------------------
INPUT="$(cat)"
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
  [ -n "$CMD" ] || CMD="$INPUT"
else
  # No jq: scan the raw payload. Over-broad, but failing toward "deny" is the
  # safe direction for a guard.
  CMD="$INPUT"
fi

deny() {
  echo "BLOCKED by .claude/hooks: $1" >&2
  echo "This is a project invariant. Do not retry, do not work around it." >&2
  echo "If genuinely intended, ask the human to run it or to set CHARGE_YOLO=1." >&2
  exit 2
}

# --- Pattern table: pattern<TAB>reason ---------------------------------------
# Extended regex, matched case-insensitively. Replace every <PLACEHOLDER> with
# this project's real hazards, taken from the never-do list. Delete the
# examples you do not need - a guard that blocks noise gets disabled.
PATTERNS='<DEPLOY-COMMAND-REGEX>	deploying (needs human approval)
<MIGRATION-COMMAND-REGEX>	running a migration against a shared database
git[[:space:]]+push[[:space:]]+.*(-f|--force)	force-push
git[[:space:]]+push[[:space:]]+[^|;&]*[[:space:]]<DEFAULT-BRANCH>([[:space:]]|$)	pushing directly to <DEFAULT-BRANCH>
git[[:space:]]+reset[[:space:]]+--hard	git reset --hard (discards uncommitted work)
git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f	git clean -f (deletes untracked files)
DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)	SQL DROP
<PROJECT-SPECIFIC-PATTERN>	<WHY IT MUST NEVER RUN>'

while IFS=$'\t' read -r pat reason; do
  [ -n "$pat" ] || continue
  case "$pat" in '<'*) continue ;; esac   # skip unfilled placeholder rows
  if printf '%s' "$CMD" | grep -Eiq -- "$pat"; then
    deny "$reason"
  fi
done <<< "$PATTERNS"

exit 0

# --- Verify the guard ---------------------------------------------------------
# Clear the context and ask the agent to run one blocked command. If it runs,
# the hook is not wired. Re-check after every settings.json edit.
