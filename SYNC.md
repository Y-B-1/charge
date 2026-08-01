# SYNC — refreshing vendored Matt Pocock skills

The 21 skills listed in ATTRIBUTION.md (v2.0 section) are vendored
**verbatim** from https://github.com/mattpocock/skills. Never edit their
content or frontmatter in this repo — fixes go upstream; this file only
refreshes the copy.

Vendored version: **1.2.0** (see ATTRIBUTION.md). Upstream layout is
categorized (`skills/engineering/…`, `skills/productivity/…`,
`skills/misc/…`); charge flattens to `skills/<name>/`.

## Diff against upstream

```bash
# 1. Get upstream (either works)
git clone --depth 1 https://github.com/mattpocock/skills /tmp/matt-skills
UP=/tmp/matt-skills/skills
# or use the local plugin cache:
# UP=~/.claude/plugins/cache/mattpocock/mattpocock-skills/<version>/skills

# 2. Diff every vendored skill (flat here, categorized upstream)
cd "$(git rev-parse --show-toplevel)"
for s in code-review codebase-design diagnosing-bugs domain-modeling \
         grill-with-docs implement improve-codebase-architecture prototype \
         research resolving-merge-conflicts tdd to-spec to-tickets triage \
         wayfinder setup-matt-pocock-skills; do diff -ru "$UP/engineering/$s" "skills/$s"; done
for s in grill-me grilling handoff writing-great-skills; do
  diff -ru "$UP/productivity/$s" "skills/$s"; done
for s in git-guardrails-claude-code setup-pre-commit; do
  diff -ru "$UP/misc/$s" "skills/$s"; done
```

No output = in sync. Any output = local drift (revert it — vendored means
verbatim) or upstream changes (refresh below).

## Refresh

```bash
# Replace wholesale — entire directory, preserving executable bits
for pair in engineering:code-review engineering:codebase-design \
  engineering:diagnosing-bugs engineering:domain-modeling \
  engineering:grill-with-docs engineering:implement \
  engineering:improve-codebase-architecture engineering:prototype \
  engineering:research engineering:resolving-merge-conflicts \
  engineering:tdd engineering:to-spec engineering:to-tickets \
  engineering:triage engineering:wayfinder engineering:setup-matt-pocock-skills productivity:grill-me \
  productivity:grilling productivity:handoff \
  productivity:writing-great-skills misc:git-guardrails-claude-code \
  misc:setup-pre-commit; do
  cat="${pair%%:*}"; s="${pair##*:}"
  rm -rf "skills/$s" && cp -Rp "$UP/$cat/$s" "skills/$s"
done
```

Then, in one commit:

1. Read the upstream diff before adopting it — vendored skills are a
   supply-chain surface (see guardrails' vetting checklist: read bundled
   scripts, check for egress/exec, pin what you fetch).
2. Update ATTRIBUTION.md: new vendored version + date.
3. Update this file's "Vendored version" line.
4. Check name collisions against charge-origin skills
   (`ls skills/` — every dir name must be unique) and re-run skill-audit
   if descriptions changed.
5. If upstream added/removed skills, decide vendoring per the
   architecture doc — the vendored list itself is a curated subset
   (persona/installer/personal skills are intentionally skipped).

Reminder: disable the mattpocock-skills plugin locally when charge is
installed — the names intentionally collide.
