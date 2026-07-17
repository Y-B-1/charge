#!/usr/bin/env bash
# charge guardrails: guard-bash — PreToolUse hook for the Bash tool.
# Denies destructive command patterns deterministically, before execution.
# Human override for intentional ops: re-run the session/command with
# CHARGE_GUARD_ALLOW=1 (the override is for humans; never let the model set it).
set -uo pipefail
[ "${CHARGE_GUARD_ALLOW:-0}" = "1" ] && exit 0

INPUT="$(cat)"
# Extract the command if jq is available; otherwise scan the whole payload
# (over-broad, but failing toward "deny" is the safe direction for a guard).
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
  [ -n "$CMD" ] || CMD="$INPUT"
else
  CMD="$INPUT"
fi

deny() {
  local reason="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg r "charge guard-bash blocked: $reason. If genuinely intended, ask the human to run it manually or to set CHARGE_GUARD_ALLOW=1." \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
  else
    echo "charge guard-bash blocked: $reason" >&2
    exit 2   # legacy blocking exit code; stderr is fed back to Claude
  fi
}

# pattern<TAB>label — extended regex, case-insensitive where it matters
PATTERNS='rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[[:space:]]+("?/"?|~|\$HOME|\*|\.\.)([[:space:]]|$|/)	recursive delete at a dangerous root
--no-preserve-root	rm --no-preserve-root
git[[:space:]]+reset[[:space:]]+--hard	git reset --hard (discards uncommitted work)
git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f	git clean -f (deletes untracked files)
git[[:space:]]+checkout[[:space:]]+--[[:space:]]+\.	git checkout -- . (discards all changes)
git[[:space:]]+stash[[:space:]]+(drop|clear)	git stash drop/clear
git[[:space:]]+push[[:space:]]+.*(-f|--force).*[[:space:]](main|master)([[:space:]]|$)	force-push to main/master
git[[:space:]]+branch[[:space:]]+-D[[:space:]]+(main|master)([[:space:]]|$)	deleting main/master
DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)	SQL DROP
TRUNCATE[[:space:]]+TABLE	SQL TRUNCATE
(terraform|pulumi)[[:space:]]+destroy	infrastructure destroy
cdk[[:space:]]+destroy	cdk destroy
mkfs(\.| )	filesystem format
dd[[:space:]]+.*of=/dev/	raw write to a device
>[[:space:]]*/dev/sd	redirect onto a disk device
chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/([[:space:]]|$)	chmod -R 777 /
(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh	pipe-to-shell install
(^|[;&|[:space:]])(shutdown|reboot|halt|poweroff)([[:space:]]|$)	system shutdown/reboot
:\(\)[[:space:]]*\{[[:space:]]*:\|:&[[:space:]]*\};:	fork bomb'

while IFS=$'\t' read -r pat label; do
  [ -n "$pat" ] || continue
  if printf '%s' "$CMD" | grep -Eiq -- "$pat"; then
    deny "$label"
  fi
done <<< "$PATTERNS"

exit 0
