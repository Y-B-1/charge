#!/bin/bash
# PostToolUse(Write|Edit): keep the standing instruction files inside budget.
# Prose asks an agent not to dump into CLAUDE.md; this notices when it did.
# Exit 2 feeds the message back so the agent trims in the same turn.
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_response.filePath // .tool_input.file_path // empty')
case "$FILE" in
  */CLAUDE.md|CLAUDE.md|*/AGENTS.md|AGENTS.md) CAP=${INSTRUCTION_BUDGET_CAP:-200} ;;
  */.claude/rules/*.md)                         CAP=${RULES_BUDGET_CAP:-80} ;;
  */AGENT-MEMORY.md|AGENT-MEMORY.md)            CAP=${MEMORY_INDEX_CAP:-200} ;;
  *) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0
LINES=$(grep -vcE '^\s*<!--|^\s*$' "$FILE" 2>/dev/null || wc -l < "$FILE")
if [ "$LINES" -gt "$CAP" ]; then
  echo "BUDGET: $FILE is $LINES lines (cap $CAP). Adherence drops as this file grows. Before finishing: move must-always-hold rules to a hook, file-specific rules to .claude/rules/ with paths: frontmatter, and codebase facts to a pointer. Delete anything that fails the no-op test. Then re-check." >&2
  exit 2
fi
exit 0
