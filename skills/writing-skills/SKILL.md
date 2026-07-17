---
name: writing-skills
description: >-
  Use when creating a new skill, editing an existing skill, or verifying a
  skill works before deployment. Applies TDD to process documentation:
  baseline an agent failing without the skill, write the skill against those
  exact rationalizations, verify compliance, close loopholes. Includes
  Anthropic's official best practices and subagent testing methodology.
---

# Writing Skills

Writing skills IS test-driven development applied to process documentation:
pressure-test scenarios are the tests, the SKILL.md is the production code.
If you didn't watch an agent fail WITHOUT the skill, you don't know the skill
teaches the right thing. Required background: charge:test-driven-development.

## The cycle

**RED** — run the pressure scenario with a subagent before the skill exists;
document the exact rationalizations it uses. **GREEN** — write the skill
addressing those specific violations. **REFACTOR** — find new rationalizations,
plug them, re-verify. Method details:
[testing-skills-with-subagents.md](testing-skills-with-subagents.md); wording
that actually changes agent behavior:
[persuasion-principles.md](persuasion-principles.md); Anthropic's official
guidance: [anthropic-best-practices.md](anthropic-best-practices.md).

## Create a skill when

The technique wasn't obvious to you · you'd reference it again across projects
· it applies broadly. NOT for one-offs, well-documented standard practice,
project conventions (CLAUDE.md), or anything a regex/validator could enforce
(automate those).

## House format (this repo)

- `skills/<name>/SKILL.md` + supporting files ONLY for heavy reference
  (100+ lines) or reusable tools; principles stay inline.
- Frontmatter description: third person, states what it does AND when to use
  it, concrete trigger keywords, ≤1024 chars. Under-triggers → add the words
  users actually say; over-triggers → make it more specific.
- Body: iron law up top if there is one, a checklist or numbered process,
  a rationalization table for the pressure points, no narrative storytelling.
  Keep it lean; put searchable terms early.
- Test with a subagent before shipping; commit; update using-charge's routing
  table if the new skill changes what should trigger.

## Validation tooling (Anthropic scripts, Apache-2.0)

Ship-gate every skill with the official tooling in [scripts/](scripts/):
`python scripts/quick_validate.py <skill-dir>` (frontmatter + structure — a
FAIL blocks commit), `python scripts/package_skill.py <skill-dir> <out>`
(distributable .skill), and `python scripts/improve_description.py` when
skill-audit flags a description. Run validate before every catalog commit.
