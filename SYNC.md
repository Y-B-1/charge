# SYNC — refreshing vendored Matt Pocock skills

The 35 skills listed in ATTRIBUTION.md (v2.0 section) are vendored
**verbatim** from https://github.com/mattpocock/skills. Never edit their
content or frontmatter in this repo — fixes go upstream; this file only
refreshes the copy.

Vendored version: **1.2.2** (see ATTRIBUTION.md). Upstream layout is
categorized (`skills/engineering/…`, `skills/productivity/…`,
`skills/misc/…`, `skills/in-progress/…`); charge flattens to
`skills/<name>/`.

The vendored set is **everything upstream publishes** — there is no curated
subset to maintain. When upstream adds a skill, vendor it; when upstream
removes one, remove it here too.

## Diff against upstream

```bash
# 1. Get upstream (either works)
git clone --depth 1 https://github.com/mattpocock/skills /tmp/matt-skills
UP=/tmp/matt-skills/skills
# or use the local plugin cache:
# UP=~/.claude/plugins/cache/mattpocock/mattpocock-skills/<version>/skills

# 2. Diff every vendored skill (flat here, categorized upstream)
cd "$(git rev-parse --show-toplevel)"
for s in ask-matt code-review codebase-design diagnosing-bugs domain-modeling \
         grill-with-docs implement improve-codebase-architecture prototype \
         research resolving-merge-conflicts setup-matt-pocock-skills tdd \
         to-spec to-tickets triage wayfinder wizard; do
  diff -ru "$UP/engineering/$s" "skills/$s"; done
for s in grill-me grilling handoff teach to-questionnaire wait-what \
         writing-for-agents; do diff -ru "$UP/productivity/$s" "skills/$s"; done
for s in git-guardrails-claude-code migrate-to-shoehorn scaffold-exercises \
         setup-pre-commit; do diff -ru "$UP/misc/$s" "skills/$s"; done
for s in claude-handoff loop-me setup-ts-deep-modules writing-beats \
         writing-fragments writing-shape; do
  diff -ru "$UP/in-progress/$s" "skills/$s"; done
```

No output = in sync. Any output = local drift (revert it — vendored means
verbatim) or upstream changes (refresh below).

## Refresh

```bash
# Replace wholesale — entire directory, preserving executable bits
for pair in engineering:ask-matt engineering:code-review \
  engineering:codebase-design engineering:diagnosing-bugs \
  engineering:domain-modeling engineering:grill-with-docs \
  engineering:implement engineering:improve-codebase-architecture \
  engineering:prototype engineering:research \
  engineering:resolving-merge-conflicts engineering:setup-matt-pocock-skills \
  engineering:tdd engineering:to-spec engineering:to-tickets \
  engineering:triage engineering:wayfinder engineering:wizard \
  productivity:grill-me productivity:grilling productivity:handoff \
  productivity:teach productivity:to-questionnaire productivity:wait-what \
  productivity:writing-for-agents misc:git-guardrails-claude-code \
  misc:migrate-to-shoehorn misc:scaffold-exercises misc:setup-pre-commit \
  in-progress:claude-handoff in-progress:loop-me \
  in-progress:setup-ts-deep-modules in-progress:writing-beats \
  in-progress:writing-fragments in-progress:writing-shape; do
  cat="${pair%%:*}"; s="${pair##*:}"
  rm -rf "skills/$s" && cp -Rp "$UP/$cat/$s" "skills/$s"
done
```

Then, in one commit:

1. Read the upstream diff before adopting it — vendored skills are a
   supply-chain surface (see guardrails' vetting checklist: read bundled
   scripts, check for egress/exec, pin what you fetch). Bundled scripts
   currently in scope: `diagnosing-bugs/scripts/hitl-loop.template.sh`,
   `git-guardrails-claude-code/scripts/block-dangerous-git.sh`,
   `wizard/template.sh`, `setup-ts-deep-modules/dependency-cruiser.config.cjs`.
2. Update ATTRIBUTION.md: new vendored version + date.
3. Update this file's "Vendored version" line and both loops above.
4. Check name collisions against charge-origin skills
   (`ls skills/ | sort | uniq -d` must print nothing) and re-run skill-audit
   if descriptions changed.
5. If upstream added or removed skills, mirror it — additions get vendored,
   removals get deleted here. A removal that charge-origin skills point at
   is a rewire, not a keep: upstream's 1.2.1 rename of
   `writing-great-skills` → `writing-for-agents` is the worked example.

Reminder: disable the mattpocock-skills plugin locally when charge is
installed — the names intentionally collide.
