#!/usr/bin/env bash
# charge skill-audit: measure every skill's always-loaded footprint.
# Usage: audit.sh [skills-root ...]   (default: ~/.claude/skills)
set -uo pipefail
ROOTS=("$@"); [ ${#ROOTS[@]} -gt 0 ] || ROOTS=("$HOME/.claude/skills")

total=0; count=0
declare -A seen
printf "%-34s %7s  %s\n" "SKILL" "DESC" "FLAG"
for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || { echo "(missing root: $root)" >&2; continue; }
  for f in "$root"/*/SKILL.md; do
    [ -f "$f" ] || continue
    name=$(basename "$(dirname "$f")")
    # description: single line, block scalar (>-, |), or quoted — join until next key/end of frontmatter
    desc=$(awk '
      /^---[[:space:]]*$/ {fm++; next}
      fm==1 && /^description:/ {
        d=$0; sub(/^description:[[:space:]]*[>|][-+]?[[:space:]]*/,"",d); sub(/^description:[[:space:]]*/,"",d);
        grab=1; if (d!="") buf=d; next }
      fm==1 && grab && /^[a-zA-Z_-]+:/ {grab=0}
      fm==1 && grab {line=$0; gsub(/^[[:space:]]+|[[:space:]]+$/,"",line); if(line!="") buf=(buf==""?line:buf" "line)}
      fm==2 {exit}
      END {print buf}' "$f")
    n=${#desc}
    flag=""
    [ "$n" -gt 800 ] && flag="WARN>800"
    [ "$n" -gt 1024 ] && flag="FAIL>1024"
    if [ -n "${seen[$name]:-}" ]; then flag="${flag:+$flag,}DUP(${seen[$name]})"; else seen[$name]="$root"; fi
    printf "%-34s %7d  %s\n" "$name" "$n" "$flag"
    total=$((total+n)); count=$((count+1))
  done
done
echo "-----------------------------------------------------------"
echo "skills: $count   description chars: $total   ~always-loaded tokens: $((total/4)) (+names/overhead)"
echo "Compact WARN/FAIL first; keep trigger nouns; re-run to confirm."
