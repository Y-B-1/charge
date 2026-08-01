#!/usr/bin/env bash
# charge project-audit: the mechanical half of the agent-infrastructure audit.
# Read-only. Non-interactive. Never edits the audited repo.
#
# Usage: audit.sh [repo-dir] [--global /path/to/global/CLAUDE.md] [--no-fire]
#
# Exit: 0 clean · 1 findings (MAJOR/MINOR) · 2 critical · 3 usage error
set -uo pipefail

REPO=""; GLOBAL=""; FIRE=1
while [ $# -gt 0 ]; do
  case "$1" in
    --global) GLOBAL="${2:-}"; shift 2 || exit 3 ;;
    --no-fire) FIRE=0; shift ;;
    -h|--help) sed -n '2,7p' "$0"; exit 3 ;;
    -*) echo "unknown option: $1" >&2; exit 3 ;;
    *) [ -n "$REPO" ] && { echo "too many arguments" >&2; exit 3; }; REPO="$1"; shift ;;
  esac
done
[ -n "$REPO" ] || REPO="."
[ -d "$REPO" ] || { echo "not a directory: $REPO" >&2; exit 3; }
REPO="$(cd "$REPO" && pwd)"
[ -z "$GLOBAL" ] || [ -f "$GLOBAL" ] || { echo "--global file not found: $GLOBAL" >&2; exit 3; }

CRIT=0; MAJOR=0; MINOR=0; NOTCHECKED=0
crit()  { CRIT=$((CRIT+1));   printf 'CRITICAL  %s\n' "$*"; }
major() { MAJOR=$((MAJOR+1)); printf 'MAJOR     %s\n' "$*"; }
minor() { MINOR=$((MINOR+1)); printf 'MINOR     %s\n' "$*"; }
skip()  { NOTCHECKED=$((NOTCHECKED+1)); printf 'NOTCHECKED %s\n' "$*"; }
pass()  { printf 'pass      %s\n' "$*"; }
sec()   { printf '\n== %s ==\n' "$*"; }

TMPD="$(mktemp -d 2>/dev/null || mktemp -d -t chargeaudit)"
trap 'rm -rf "$TMPD"' EXIT

HAVE_JQ=0; command -v jq >/dev/null 2>&1 && HAVE_JQ=1
HAVE_PY=0; command -v python3 >/dev/null 2>&1 && HAVE_PY=1

rel() { printf '%s' "${1#$REPO/}"; }

echo "charge project-audit — $REPO"
[ -n "$GLOBAL" ] && echo "global brief: $GLOBAL"

# ---------------------------------------------------------------- 1. BUDGET
sec "1. BUDGET (cap: <200 operational lines per brief file)"
BRIEFS="$TMPD/briefs"
{ ls "$REPO"/CLAUDE.md "$REPO"/AGENTS.md 2>/dev/null
  find "$REPO" -name CLAUDE.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null
  find "$REPO" -name AGENTS.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null
  find "$REPO/.claude/rules" -name '*.md' 2>/dev/null
  ls "$REPO"/CONSTITUTION.md "$REPO"/CHARTER.md 2>/dev/null
} | sort -u > "$BRIEFS"
[ -s "$BRIEFS" ] || minor "no CLAUDE.md / AGENTS.md found in $REPO — the repo has no standing brief"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  raw=$(wc -l < "$f" | tr -d ' ')
  # operational = non-blank, not a pure heading, not an HTML comment (stripped before injection)
  op=$(awk 'BEGIN{c=0}
    /<!--/{inc=1} inc{if(/-->/)inc=0; next}
    /^[[:space:]]*$/{next} /^[[:space:]]*#/{next}
    {c++} END{print c}' "$f")
  if [ "$op" -gt 200 ]; then major "$(rel "$f"): $op operational lines (raw $raw) — over the 200 cap; adherence drops. Cut sediment or demote sections to skills."
  elif [ "$op" -gt 150 ]; then minor "$(rel "$f"): $op operational lines (raw $raw) — approaching the 200 cap."
  else pass "$(rel "$f"): $op operational lines (raw $raw)"; fi
done < "$BRIEFS"

# ------------------------------------------------------------ 2. MEMORY SIZE
sec "2. MEMORY FILES (mandated-load files should stay under ~200 lines)"
MEM="$TMPD/mem"
{ find "$REPO" -maxdepth 2 \( -name 'MEMORY.md' -o -name 'PROGRESS*' -o -name 'progress.txt' \
    -o -name 'PRD.md' -o -name 'RESEARCH*.md' -o -name 'NOTES.md' \) \
    -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null
  find "$REPO/.claude/memory" -type f -name '*.md' 2>/dev/null
} | sort -u > "$MEM"
if [ -s "$MEM" ]; then
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    n=$(wc -l < "$f" | tr -d ' ')
    if [ "$n" -gt 200 ]; then major "$(rel "$f"): $n lines — split into a thin index + on-demand topic files if it loads at session start."
    else pass "$(rel "$f"): $n lines"; fi
    case "$(basename "$f")" in RESEARCH*|NOTES.md)
      if grep -qiE 'expire|expires|stale after|verified:|valid until|as of [0-9]{4}' "$f"; then
        pass "$(rel "$f"): carries a staleness/expiry stamp"
      else minor "$(rel "$f"): no expiry or verified stamp — cached findings rot silently."; fi ;;
    esac
  done < "$MEM"
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    grep -qiE 'api[_-]?key[[:space:]]*[:=]|secret[[:space:]]*[:=]|password[[:space:]]*[:=]|BEGIN [A-Z ]*PRIVATE KEY' "$f" && \
      crit "$(rel "$f"): contains secret-shaped strings — memory is read back into context and usually committed. Remove and rotate."
  done < "$MEM"
else pass "no memory/progress files found"; fi

# --------------------------------------------------------------- 3. SETTINGS
sec "3. SETTINGS JSON"
SETTINGS=""
for s in "$REPO/.claude/settings.json" "$REPO/.claude/settings.local.json" "$REPO/.mcp.json"; do
  [ -f "$s" ] || continue
  if [ "$HAVE_JQ" = 1 ]; then ok=$(jq -e . "$s" >/dev/null 2>&1 && echo 1 || echo 0)
  elif [ "$HAVE_PY" = 1 ]; then ok=$(python3 -c 'import json,sys;json.load(open(sys.argv[1]))' "$s" >/dev/null 2>&1 && echo 1 || echo 0)
  else ok=skip; fi
  case "$ok" in
    1) pass "$(rel "$s"): valid JSON" ;;
    0) crit "$(rel "$s"): does NOT parse — no hooks or permissions from this file load at all. Fix the syntax first; every other hook finding is unreliable until it parses." ;;
    *) skip "$(rel "$s"): no jq and no python3 — JSON validity not checked" ;;
  esac
  case "$s" in *settings.json) [ "$ok" = 1 ] && SETTINGS="$s" ;; esac
done
[ -f "$REPO/.claude/settings.json" ] || minor "no .claude/settings.json — this repo has no hook-level enforcement."

# ------------------------------------------------------------------ 4. HOOKS
sec "4. HOOKS (exists · bash -n · explicit timeout · fires)"
HOOKS="$TMPD/hooks"   # event \t matcher \t type \t command \t timeout
: > "$HOOKS"
if [ -n "$SETTINGS" ]; then
  if [ "$HAVE_JQ" = 1 ]; then
    jq -r '(.hooks // {}) | to_entries[] | .key as $ev | (.value // [])[] |
           ((.matcher // "*") ) as $m | ((.hooks // [])[] |
           [$ev,$m,(.type // "command"),(.command // .url // "(non-command handler)"),
            (if .timeout == null then "" else (.timeout|tostring) end)] | @tsv)' \
      "$SETTINGS" > "$HOOKS" 2>/dev/null
  elif [ "$HAVE_PY" = 1 ]; then
    python3 - "$SETTINGS" > "$HOOKS" 2>/dev/null <<'PY'
import json,sys
d=json.load(open(sys.argv[1])).get("hooks",{}) or {}
for ev,groups in d.items():
    for g in (groups or []):
        m=g.get("matcher","*")
        for h in (g.get("hooks") or []):
            print("\t".join([ev,str(m),h.get("type","command"),
                  str(h.get("command") or h.get("url") or "(non-command handler)"),
                  "" if h.get("timeout") is None else str(h["timeout"])]))
PY
  else skip "hooks not enumerated — no jq and no python3"; fi
fi

if [ ! -s "$HOOKS" ]; then
  echo "(no hooks configured)"
else
  while IFS="$(printf '\t')" read -r ev matcher htype cmd tmo; do
    [ -n "${ev:-}" ] || continue
    label="$ev/$matcher ($htype)"
    # explicit timeout
    if [ -z "$tmo" ]; then
      major "$(rel "$SETTINGS"): hook $label has no explicit \"timeout\" — an untimed chain bounds nothing. Add \"timeout\": <seconds> to the hook entry."
    else pass "hook $label: timeout=${tmo}s"; fi
    # resolve first token to a script path
    first="${cmd%% *}"
    path="$first"
    case "$path" in "~"*) path="$HOME${path#\~}" ;; esac
    path="$(printf '%s' "$path" | sed "s|\$CLAUDE_PROJECT_DIR|$REPO|g; s|\${CLAUDE_PROJECT_DIR}|$REPO|g")"
    case "$path" in /*) ;; *) [ -e "$REPO/$path" ] && path="$REPO/$path" ;; esac
    if [ ! -f "$path" ]; then
      if command -v "$first" >/dev/null 2>&1; then
        pass "hook $label: inline command (\`$first\`), no script file to check"
      else
        crit "$(rel "$SETTINGS"): hook $label points at \`$first\` which does not exist and is not on PATH — this hook enforces nothing. Restore the script or delete the entry."
      fi
      continue
    fi
    [ -x "$path" ] || major "$(rel "$path"): hook script is not executable — chmod +x it."
    if bash -n "$path" 2>"$TMPD/synerr"; then pass "$(rel "$path"): bash -n clean"
    else crit "$(rel "$path"): bash -n FAILS ($(head -1 "$TMPD/synerr")) — the hook aborts on every fire and blocks nothing."; continue; fi
    grep -qE '@latest|@next|curl[^|]*\|[[:space:]]*(ba)?sh' "$path" && \
      major "$(rel "$path"): unpinned version or pipe-to-shell inside a gate — its behavior can change with no commit. Pin the version; vendor the script."
    printf '%s\t%s\t%s\n' "$ev" "$matcher" "$path" >> "$TMPD/firelist"
  done < "$HOOKS"
fi

# ------------------------------------------------------------- 4e. FIRE TEST
sec "4e. HOOK FIRE TESTS (synthetic PreToolUse stdin; only exit 2 or a deny decision blocks)"
fire() { # $1 script  $2 payload-file -> FIRE_EXIT / FIRE_OUT
  local out="$TMPD/f.out" err="$TMPD/f.err" pid i=0
  : > "$out"; : > "$err"
  ( CHARGE_GUARD_ALLOW= exec "$1" ) < "$2" > "$out" 2> "$err" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    i=$((i+1))
    if [ "$i" -gt 100 ]; then kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; FIRE_EXIT=124; FIRE_OUT=""; return; fi
    sleep 0.1
  done
  wait "$pid"; FIRE_EXIT=$?
  FIRE_OUT="$(cat "$out")$(cat "$err")"
}
blocked() { [ "${FIRE_EXIT:-0}" = "2" ] || printf '%s' "${FIRE_OUT:-}" | grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"'; }

if [ "$FIRE" = 0 ]; then skip "fire tests disabled (--no-fire)"
elif [ ! -s "${TMPD}/firelist" ]; then echo "(no runnable hook scripts to fire)"
else
  DANGER='git reset --hard HEAD~5|rm -rf /|git push --force origin main|git clean -fd|DROP TABLE users;'
  SAFE='git status'
  while IFS="$(printf '\t')" read -r ev matcher path; do
    [ "$ev" = "PreToolUse" ] || { skip "$(rel "$path"): $ev hook — no synthetic payload derived here; fire it by hand (see references/hook-fire-tests.md)"; continue; }
    case "$matcher" in Bash|\*|"") ;; *) skip "$(rel "$path"): matcher '$matcher' — payload not derivable mechanically; hand-test it."; continue ;; esac
    hit=""
    OLDIFS=$IFS; IFS='|'
    for c in $DANGER; do
      IFS=$OLDIFS
      printf '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s"}}' "$c" > "$TMPD/p.json"
      fire "$path" "$TMPD/p.json"
      [ "${FIRE_EXIT}" = "124" ] && { major "$(rel "$path"): hook HANGS on \`$c\` (killed at 10s) — set an explicit timeout and fix the script."; break; }
      if blocked; then hit="$c"; break; fi
      IFS='|'
    done
    IFS=$OLDIFS
    if [ -n "$hit" ]; then
      pass "$(rel "$path"): blocks \`$hit\` (exit ${FIRE_EXIT})"
    else
      major "$(rel "$path"): denied NONE of the dangerous shapes tested — this hook cannot block; it is decoration. Check the pattern list and the exit path (only exit 2 or a deny decision blocks). CRITICAL if any doc claims it enforces something."
    fi
    printf '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s"}}' "$SAFE" > "$TMPD/p.json"
    fire "$path" "$TMPD/p.json"
    if blocked; then major "$(rel "$path"): denies the benign shape \`$SAFE\` — over-blocking gets the hook disabled, and then nothing is enforced."
    else pass "$(rel "$path"): allows \`$SAFE\` (exit ${FIRE_EXIT})"; fi
    [ -n "${FIRE_OUT:-}" ] && minor "$(rel "$path"): writes output on a non-blocking fire — hooks should cost zero context unless they have something to say."
  done < "$TMPD/firelist"
fi

# ----------------------------------------------------- 5. ENFORCEMENT / CLAIMS
sec "5. ENFORCEMENT INVENTORY + CLAIMS (each is a candidate for prose -> hook)"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  n=$(grep -cE '\b(NEVER|never|ALWAYS|always|MUST|must not|do not|don'\''t)\b' "$f" 2>/dev/null | tr -d ' ')
  [ "${n:-0}" -gt 0 ] && echo "  $(rel "$f"): $n never/always/MUST sentences — read each: what happens the one time the model ignores it?"
done < "$BRIEFS"
CLAIMS="$TMPD/claims"
grep -rnEi 'enforced by|blocked by|hook (prevents|blocks|ensures)|pre-commit (ensures|blocks)|is impossible|cannot (push|commit|delete|run)|automatically (blocks|prevents)' \
  --include='*.md' "$REPO" 2>/dev/null | grep -v '/node_modules/' > "$CLAIMS"
if [ -s "$CLAIMS" ]; then
  echo "  enforcement CLAIMS to verify against section 4 (a claim without a firing mechanism is CRITICAL):"
  sed 's|^'"$REPO"'/|    |' "$CLAIMS" | cut -c1-160
else pass "no unverified enforcement claims found in markdown"; fi

# -------------------------------------------------------- 6. DANGLING POINTERS
sec "6. STALE POINTERS"
DOCS="$TMPD/docs"
find "$REPO" -name '*.md' -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | head -200 > "$DOCS"
dang=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  d="$(dirname "$f")"
  grep -oE '`[^`]+`|\]\([^)]+\)' "$f" 2>/dev/null \
    | sed 's/^`//; s/`$//; s/^](//; s/)$//' \
    | grep -E '(/|\.(md|sh|json|ts|tsx|js|jsx|py|rb|go|rs|ya?ml|toml|txt))$|/' \
    | grep -vE '^(https?|mailto):|[[:space:]]|[*?<>$]|^-|^~|^#' \
    | sort -u | while IFS= read -r p; do
        [ -n "$p" ] || continue
        [ -e "$d/$p" ] && continue
        [ -e "$REPO/$p" ] && continue
        [ -e "$p" ] && continue
        echo "  $(rel "$f"): dangling pointer \`$p\`"
      done
done < "$DOCS" | sort -u > "$TMPD/dangling"
dang=$(wc -l < "$TMPD/dangling" | tr -d ' ')
if [ "$dang" -gt 0 ]; then
  cat "$TMPD/dangling"
  minor "$dang dangling pointer(s) — confirm each (some are illustrative). A dead pointer inside a mandated explore-step is MAJOR."
else pass "every path-shaped reference in markdown resolves"; fi

# ------------------------------------------------------- 7. PROJECT SKILLS
sec "7. PROJECT SKILL ECONOMICS (.claude/skills)"
found_skill=0
for sk in "$REPO"/.claude/skills/*/SKILL.md; do
  [ -f "$sk" ] || continue
  found_skill=1
  name=$(basename "$(dirname "$sk")")
  lines=$(wc -l < "$sk" | tr -d ' ')
  desc=$(awk '/^---[[:space:]]*$/{fm++; next}
    fm==1 && /^description:/{d=$0; sub(/^description:[[:space:]]*[>|][-+]?[[:space:]]*/,"",d); sub(/^description:[[:space:]]*/,"",d); grab=1; if(d!="")buf=d; next}
    fm==1 && grab && /^[a-zA-Z_-]+:/{grab=0}
    fm==1 && grab {l=$0; gsub(/^[[:space:]]+|[[:space:]]+$/,"",l); if(l!="") buf=(buf==""?l:buf" "l)}
    fm==2{exit} END{print buf}' "$sk")
  dl=${#desc}
  [ "$dl" -gt 1024 ] && major "$(rel "$sk"): description is $dl chars (spec cap 1024) — compact it, trigger nouns first."
  [ "$dl" = 0 ] && major "$(rel "$sk"): no description — the model cannot route to it."
  [ "$lines" -gt 500 ] && major "$(rel "$sk"): $lines lines (cap 500) — an invoked body bills every turn after it fires. Move detail behind pointers."
  if grep -q '^disable-model-invocation:[[:space:]]*true' "$sk"; then mode="zero-cost (disable-model-invocation)"
  elif grep -q '^user-invocable:[[:space:]]*false' "$sk"; then mode="model-invoked, hidden from / menu — description still bills every session"
  else mode="model-invoked — description bills every session"; fi
  pass "$(rel "$sk"): $lines lines, description $dl chars, $mode"
  grep -qE '@latest|@next' "$sk" && major "$(rel "$sk"): pins @latest/@next — never in a gate."
  grep -qE 'curl[^|]*\|[[:space:]]*(ba)?sh|curl .*-o .*&&' "$sk" && \
    crit "$(rel "$sk"): fetches and runs remote content at run time — the instruction supply chain becomes whatever the host serves today. Vendor it."
done
[ "$found_skill" = 1 ] || echo "(no project-local skills)"

# ----------------------------------------------------------- 8. DUPLICATION
sec "8. DUPLICATION vs the global brief"
PROJ="$REPO/CLAUDE.md"
if [ -z "$GLOBAL" ]; then skip "no --global path given — duplication against the user's global CLAUDE.md not checked"
elif [ ! -f "$PROJ" ]; then skip "no $REPO/CLAUDE.md — nothing to diff"
else
  awk '
    function norm(s,   t){ t=tolower(s);
      gsub(/`|\*\*|__/,"",t);
      sub(/^[[:space:]]*([-*+>]|[0-9]+\.)[[:space:]]*/,"",t);
      gsub(/[^a-z0-9]+/," ",t);
      sub(/^ /,"",t); sub(/ $/,"",t); return t }
    function keyset(s, arr,   n,i,w,out,seen){ n=split(s,w," "); out=""; delete seen;
      for(i=1;i<=n;i++){ if(length(w[i])<4) continue;
        if(w[i] ~ /^(this|that|with|from|into|when|then|than|they|them|your|have|been|will|must|never|always|should|which|what|whose|about|these|those|there|here)$/) continue;
        if(!(w[i] in seen)){ seen[w[i]]=1; out=out" "w[i] } }
      return out }
    NR==FNR { t=keyset(norm($0)); n=split(t,w," "); if(n>=4){ gc++; gtxt[gc]=t; gsrc[gc]=FNR": "substr($0,1,70) } next }
    { t=keyset(norm($0)); n=split(t,pw," "); if(n<4) next
      best=0; bi=0
      for(i=1;i<=gc;i++){
        m=split(gtxt[i],gw," "); delete S; inter=0
        for(j=1;j<=m;j++) S[gw[j]]=1
        for(j=1;j<=n;j++) if(pw[j] in S) inter++
        uni=n+m-inter; if(uni==0) continue
        jac=inter/uni; if(jac>best){best=jac; bi=i}
      }
      if(best>=0.55) printf "  project:%d  overlap %.2f  global:%s\n    project: %s\n", FNR, best, gsrc[bi], substr($0,1,90)
      if(best>=0.55) dup++
    }
    END { printf "DUPCOUNT %d\n", dup+0 }
  ' "$GLOBAL" "$PROJ" > "$TMPD/dup"
  dupn=$(awk '/^DUPCOUNT/{print $2}' "$TMPD/dup")
  grep -v '^DUPCOUNT' "$TMPD/dup"
  if [ "${dupn:-0}" -gt 0 ]; then
    major "$dupn project line(s) restate the global brief — the two concatenate, they never override. Delete from the project file; keep only the delta. Confirm each pair by reading (overlap is a heuristic)."
  else pass "no line-level duplication against the global brief"; fi
fi

# ------------------------------------------------------------------ SUMMARY
sec "SUMMARY"
printf 'CRITICAL %d · MAJOR %d · MINOR %d · NOT CHECKED %d\n' "$CRIT" "$MAJOR" "$MINOR" "$NOTCHECKED"
if [ "$CRIT" -gt 0 ]; then echo "verdict: BLOCK (critical findings)"; exit 2; fi
if [ "$MAJOR" -gt 0 ]; then echo "verdict: BLOCK (major findings)"; exit 1; fi
if [ "$MINOR" -gt 0 ]; then echo "verdict: findings, no blockers"; exit 1; fi
if [ "$NOTCHECKED" -gt 0 ]; then
  echo "verdict: INCOMPLETE — no findings, but $NOTCHECKED check(s) could not run. Report them under NOT CHECKED; never call an unrun check a pass."
  exit 1
fi
echo "verdict: PASS (mechanical checks only — checks 1,2,3,5,6,7 still need a human/agent read)"
exit 0
