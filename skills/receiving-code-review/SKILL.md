---
name: receiving-code-review
description: >-
  Use when code-review feedback arrives — from the human, a reviewer subagent,
  or an external reviewer — before implementing any of it. Requires technical
  verification over performative agreement: restate, verify against the
  codebase, evaluate, then implement one item at a time or push back with
  reasoning. Especially when feedback is unclear or technically questionable.
---

# Receiving Code Review

Technical evaluation, not emotional performance. Verify before implementing;
ask before assuming; correctness over social comfort.

## The pattern

READ all feedback without reacting → UNDERSTAND (restate in your own words, or
ask) → VERIFY against codebase reality → EVALUATE (sound for THIS codebase?) →
RESPOND (technical acknowledgment or reasoned pushback) → IMPLEMENT one item
at a time, testing each.

**Forbidden:** "You're absolutely right!", "Great point!", "Let me implement
that now" (before verification). Instead: restate the requirement, ask, push
back with reasoning, or just start working — actions over words.

## Unclear items

ANY item unclear → stop, implement nothing yet, ask about the unclear ones.
Items may be related; partial understanding = wrong implementation.
("Understand 1,2,3,6 — need clarification on 4 and 5 before proceeding.")

## By source

- **The human:** trusted — implement after understanding; still ask if scope
  is unclear; no performative agreement.
- **External/automated reviewers:** before implementing, check — correct for
  this codebase? breaks existing behavior? reason the current code is this
  way? all platforms/versions? does the reviewer have full context? Wrong →
  push back with reasoning. Can't verify → say so and ask how to proceed.
  Conflicts with the human's prior decisions → stop and discuss first.
- **YAGNI check on "implement properly":** grep for actual usage; unused →
  propose removal instead.

External feedback = suggestions to evaluate, not orders to follow.
