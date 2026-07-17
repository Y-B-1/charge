---
name: brainstorming
description: >-
  Use before any creative or feature work — creating features, building
  components, adding functionality, or modifying behavior — while direction is
  still open. Explores intent, requirements, and design through one-question-
  at-a-time dialogue, proposes 2-3 approaches, and gates all implementation
  behind an approved design. Hands off to the goal skill and writing-plans.
  Skipped when the owner skill is driving (its kickoff covers this).
---

# Brainstorming — ideas into approved designs

Turn an idea into a validated design through natural collaborative dialogue:
understand context, refine with questions, propose approaches, present the
design, get approval — then hand off.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, or scaffold anything
until you have presented a design and the human has approved it. This applies
to EVERY project regardless of perceived simplicity — a todo list, a config
change, all of them. "Simple" is where unexamined assumptions waste the most
work. The design may be three sentences; it must still be presented.
</HARD-GATE>

## Checklist (create a todo per item, in order)

1. **Explore project context** — files, docs, recent commits, existing patterns.
2. **Scope check** — if the request spans multiple independent subsystems,
   decompose into sub-projects first; brainstorm the first one. Each
   sub-project gets its own spec → plan → implementation cycle.
3. **Ask clarifying questions** — one per message, multiple-choice when
   possible; purpose, constraints, success criteria. Don't ask what the repo
   or the user already answered.
4. **Propose 2–3 approaches** — trade-offs, lead with your recommendation and
   why. YAGNI ruthlessly in all of them.
5. **Present the design in sections** scaled to complexity (a few sentences to
   ~300 words each); confirm after each. Cover architecture, components, data
   flow, error handling, testing.
6. **Write the design doc** to `docs/charge/specs/YYYY-MM-DD-<topic>-design.md`
   (user preference overrides) and commit it.
7. **Spec self-review, inline:** placeholder scan (no TBD/TODO/vague reqs),
   internal consistency, single-plan scope, ambiguity (two readings → make one
   explicit). Fix and move on.
8. **User review gate:** "Spec written and committed to `<path>` — review
   before we plan?" Wait; apply changes; re-review.
9. **Hand off:** invoke **charge:goal** to turn the approved design into
   SPEC.md/GOAL.md contract terms (mechanical done_when, guards, caps), then
   **charge:writing-plans**. No other skill follows brainstorming.

## Design principles

- Units with one clear purpose, well-defined interfaces, independently
  testable. If you can't change internals without breaking consumers, the
  boundaries need work. Smaller focused files > large ones — you reason best
  about code you can hold in context.
- In existing codebases: follow established patterns; fold in targeted
  improvements only where the current work touches a real problem; no
  unrelated refactoring.
- One question at a time; explore alternatives before settling; incremental
  validation; be ready to loop back when something doesn't fit.
