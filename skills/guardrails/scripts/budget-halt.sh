#!/usr/bin/env bash
# charge guardrails: budget-halt — PreToolUse hook, wire with matcher "*" so
# ALL tool calls (not just Bash) halt once today's estimated spend (via
# ccusage, cached 60s) crosses CHARGE_DAILY_BUDGET_USD. Unset budget =
# disarmed. Fails OPEN on tooling errors (a broken npx must not brick the
# session) with a stderr warning.
# Isolation caveat: inside a container/docker sandbox, ccusage reads the
# container's own ~/.claude/projects/ — the ceiling is per-environment unless
# the host logs are mounted in.
# ccusage is PINNED (vetting rule 6: never float @latest in a hook). Bump
# CCUSAGE_PIN deliberately and diff the release first; CHARGE_CCUSAGE_VERSION
# overrides for testing.
set -uo pipefail
CCUSAGE_PIN="${CHARGE_CCUSAGE_VERSION:-20.0.19}"
BUDGET="${CHARGE_DAILY_BUDGET_USD:-}"
[ -n "$BUDGET" ] || exit 0

CACHE="${TMPDIR:-/tmp}/charge-ccusage-cache.json"
fresh=0
if [ -f "$CACHE" ]; then
  now=$(date +%s); mtime=$(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE" 2>/dev/null || echo 0)
  [ $(( now - mtime )) -lt 60 ] && fresh=1
fi
if [ "$fresh" -ne 1 ]; then
  if ! npx -y "ccusage@${CCUSAGE_PIN}" daily --json --since "$(date +%Y%m%d)" --until "$(date +%Y%m%d)" > "$CACHE" 2>/dev/null; then
    echo "charge budget-halt: ccusage unavailable — budget check skipped (fail-open)." >&2
    exit 0
  fi
fi

COST="$(grep -o '"totalCost":[[:space:]]*[0-9.]*' "$CACHE" | tail -1 | grep -o '[0-9.]*$')"
if [ -z "$COST" ]; then
  echo "charge budget-halt: could not parse ccusage output — budget check skipped." >&2
  exit 0
fi

OVER="$(awk -v c="$COST" -v b="$BUDGET" 'BEGIN{print (c>b)?1:0}')"
if [ "$OVER" = "1" ]; then
  MSG="charge budget-halt: today's estimated spend \$$COST exceeds CHARGE_DAILY_BUDGET_USD=\$$BUDGET (ccusage estimate — real bill can be 10-30% higher). Stopping further tool calls; the human can raise the budget or continue tomorrow."
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg r "$MSG" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
  else
    echo "$MSG" >&2; exit 2
  fi
fi
exit 0
