---
name: testing-skills
description: >-
  Adversarial pressure-testing of skills before deployment — baseline an agent
  failing WITHOUT the skill, verify compliance WITH it, close rationalization
  loopholes. Use when a new or edited skill enforces discipline that an agent
  under pressure would want to dodge, or as the ship gate before any skill
  lands in the catalog. Authoring doctrine lives in writing-great-skills, not
  here.
disable-model-invocation: true
---

# Testing Skills

Scope: this skill covers one thing — pressure-testing skills so they hold
when an agent wants to break them. How to WRITE a skill (invocation choice,
description craft, information hierarchy, splitting, pruning, failure modes)
is [writing-great-skills](../writing-great-skills/SKILL.md) territory; read it
first, and nothing here overrides it.

## The cycle

**RED** — run the pressure scenario with a fresh-context subagent before the
skill exists; capture its rationalizations verbatim. **GREEN** — write the
skill against those exact failures; re-run, verify compliance. **REFACTOR** —
find new rationalizations, close each one, re-verify until none remain.
Full method: [testing-skills-with-subagents.md](testing-skills-with-subagents.md).
Wording that measurably changes agent behavior (cited research):
[persuasion-principles.md](persuasion-principles.md). Anthropic's official
guidance: [anthropic-best-practices.md](anthropic-best-practices.md).

## What to pressure-test

Only discipline-enforcing skills — rules with compliance costs (time, rework)
that contradict an agent's immediate goals (TDD, verification gates, review
requirements). Pure reference skills get benign evals only (with/without
baselines, should/shouldn't-trigger tuning), never pressure scenarios.

## Closing loopholes

State the target behavior positively first — "Delete means delete. Start
over." leads. Keep a "don't" only as a hard guardrail that cannot be phrased
positively, and always pair it with the do-instead. Every counter you add
(rationalization-table row, red-flag entry) is session-resident once the
skill loads: each must survive the no-op test or it is dead weight.
Description additions stay one trigger per branch — no restating body
identity.

## Ship gate (Anthropic scripts, Apache-2.0)

Before any catalog commit: `python scripts/quick_validate.py <skill-dir>`
(frontmatter + structure — a FAIL blocks commit);
`python scripts/package_skill.py <skill-dir> <out>` for a distributable
.skill; `python scripts/improve_description.py` when skill-audit flags a
description. Then update using-charge's routing table if the skill changes
what should trigger.
