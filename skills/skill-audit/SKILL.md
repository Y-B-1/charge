---
name: skill-audit
description: >-
  Audit the installed skill catalog's always-loaded footprint. Run when the
  catalog feels bloated, routing misfires, sessions start heavy, or after
  adding 3-5 skills — measures per-skill description cost, flags overlong or
  near-duplicate descriptions and name collisions, then applies the prune and
  duplicate-resolution rubrics below.
disable-model-invocation: true
---

# Skill Audit

Every installed skill's **name + description loads into every session** — the
body loads only on invocation. The catalog's always-on cost is the sum of its
descriptions, and it grows silently with every skill added. This skill
measures it, then applies two rubrics: duplicate-name resolution and catalog
prune. (Workflow adapted from steipete's skill-cleaner, MIT; reimplemented
portably for Claude Code.)

## Process

1. **Measure:** run [scripts/audit.sh](scripts/audit.sh) against each skill
   root in use (`~/.claude/skills`, the project's `.claude/skills`, plugin
   skill dirs). It reports per-skill description chars, the catalog total, an
   approximate always-loaded token estimate, and flags:
   FAIL >1024 chars (over the spec cap) · WARN >800 (compaction candidate) ·
   duplicate names across roots.
2. **Compact WARN/FAIL descriptions** — keep the trigger nouns (product,
   tool, action, object — they are what routing matches on); cut narrative,
   qualifiers, repeated phrasing, and synonyms that rename one branch.
   Relaxed grammar is fine; missing triggers are not. Re-run to confirm the
   saving. The reference shape is three sentences — when to READ it, when to
   USE it, what it DOES — and every sentence says *when to reach for it*,
   never what it is; a description that opens by describing the skill has its
   trigger buried where routing can't see it (PostHog, 226-skill catalog).
3. **Resolve duplicate names** with the rubric below.
4. **Prune** with the criteria below.
5. **Update the router:** any rename or removal must be reflected in
   using-charge's routing table in the same commit, or routing silently
   breaks.

## Duplicate-name resolution rubric

Exactly one copy survives per skill name. Decide by case:

- **Same content, two roots** — keep the project-local copy when it encodes
  project policy, the user-level copy otherwise. Verify the survivor loads
  before deleting the loser.
- **Different content, same name** — two skills wearing one name. Rename the
  narrower one (a rename means a new leading word AND a routing-table
  update), or merge them if they are the same job diverged.
- **Vendored copy vs local fork** — the vendored copy is upstream truth;
  never edit it in place. Move local edits into a separately named skill or
  drop them.
- **Plugin vs plugin** (two plugins shipping the same skill) — disable the
  redundant plugin locally; carrying both pays double description load and
  makes routing nondeterministic.

## Catalog-prune criteria

A skill is a prune candidate when ANY of these hold:

- Not invoked in months and its trigger domain has not recurred.
- Fully covered by another skill — every branch of it routes somewhere
  better.
- One-off by nature — belongs in CLAUDE.md, a script, or a hook, not a
  skill.
- Restates well-documented standard practice the model already does
  unprompted — fails the no-op test at catalog scale.
- Its description cannot be written with a distinct leading word — it will
  never win routing against its neighbors.
- It never cleared the admission bar: the work is not recurring (three times
  so far, three more expected), agents already do it well by default, and it
  carries no context the model lacks. Catalog size is a quality budget, not
  only a token one — wrong-skill routing rises with count (PostHog;
  Databricks).

Propose each removal to the human with the criterion it met; never silently
delete.

## Cadence

Run after every 3-5 skills added, when the catalog exceeds ~20 skills, or
whenever sessions feel slow to start. Record before/after totals in the
commit message — the audit should pay for itself in tokens.
