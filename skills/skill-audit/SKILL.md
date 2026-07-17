---
name: skill-audit
description: >-
  Use when the skill catalog feels bloated, routing misfires, session context
  seems heavy, or after adding several skills — audits every installed skill's
  always-loaded footprint (name + description budget), flags overlong or
  duplicate descriptions and name collisions, estimates total token cost, and
  guides compaction and pruning. Triggers: "audit my skills," "skill budget,"
  "too many skills," "clean up the catalog," "why is my context so heavy."
---

# Skill Audit

Every installed skill's **name + description loads into every session** — the
body loads only on invocation. So the catalog's always-on cost is the sum of
its descriptions, and it grows silently with every skill added. This skill
measures it, finds the offenders, and guides the trim. (Workflow adapted from
steipete's skill-cleaner, MIT; reimplemented portably for Claude Code.)

## Process

1. **Measure:** run [scripts/audit.sh](scripts/audit.sh) against each skill
   root in use (`~/.claude/skills`, the project's `.claude/skills`). It
   reports per-skill description chars, the catalog total, an approximate
   always-loaded token estimate, and flags:
   FAIL >1024 chars (over the spec cap) · WARN >800 (compaction candidate) ·
   duplicate names across roots · near-duplicate descriptions.
2. **Compact the WARN/FAIL descriptions** — keep the trigger nouns (product,
   tool, action, object — they're what routing matches on); cut narrative,
   qualifiers, and repeated phrasing. Relaxed grammar is fine; missing
   triggers are not. Re-run the audit to confirm the saving.
3. **Resolve duplicates:** keep exactly one copy per skill name; prefer the
   project-local copy when it encodes project policy, the user-level copy
   otherwise. Verify the kept copy loads before deleting the other.
4. **Prune candidates:** a skill unused for months, fully covered by another,
   or one-off by nature (belongs in CLAUDE.md or a script instead) — propose
   removal to the human with the reason; never silently delete.
5. **Update the router:** any rename/removal must be reflected in
   using-charge's routing table, or routing silently breaks.

## Cadence

Run after every 3–5 skills added, when charge exceeds ~20 skills, or whenever
sessions feel slow to start. Record the before/after totals in the commit
message — the audit should pay for itself in tokens.
