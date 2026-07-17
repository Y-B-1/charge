---
name: requesting-code-review
description: >-
  Use when completing a task, finishing a major feature, or before merging —
  dispatches a fresh-context code reviewer subagent against the requirements
  and the exact diff (base..head SHAs) to catch issues before they cascade.
  Mandatory after each task in subagent-driven development and before merge;
  valuable when stuck or after a complex fix.
---

# Requesting Code Review

Review early, review often. The reviewer gets precisely crafted context — the
work product and its requirements, never your session history or thought
process. Fresh context is what makes the review unbiased.

## How

1. **SHAs:** `BASE_SHA=$(git rev-parse HEAD~1)` (or origin/main),
   `HEAD_SHA=$(git rev-parse HEAD)`.
2. **Dispatch** a general-purpose subagent from the template at
   [code-reviewer.md](code-reviewer.md), filling {DESCRIPTION} (what you
   built), {PLAN_OR_REQUIREMENTS}, {BASE_SHA}, {HEAD_SHA}. Scale the model to
   the diff's size and risk; the final whole-branch review gets the most
   capable model.
3. **Act on findings:** Critical → fix immediately. Important → fix before
   proceeding. Minor → note for later. Reviewer wrong → push back with
   technical reasoning and the code/tests that prove it.

## Mandatory points

After each task in charge:subagent-driven-development · after a major feature
· before merge (charge:finishing-a-development-branch). In the autonomy suite:
owner's backlog red-team and loop's independent checker use this same
dispatch pattern.

## Never

Skip review because "it's simple" · ignore Critical · proceed past unfixed
Important · argue with valid technical feedback instead of fixing.
