---
name: writing-plans
description: >-
  Use when a spec or requirements exist for a multi-step task, before touching
  code. Produces an implementation plan of bite-sized, independently testable
  tasks with exact file paths, complete code in every step, interfaces between
  tasks, global constraints, and zero placeholders — written for an engineer
  with zero codebase context. Consumes the goal skill's SPEC/GOAL contract;
  hands off to subagent-driven-development, executing-plans, or loop.
---

# Writing Plans

Write the plan assuming the engineer has zero context for this codebase and
questionable taste: which files to touch per task, the actual code, how to
test, what to check. DRY. YAGNI. TDD. Frequent commits.

**Announce at start.** Save to `docs/charge/plans/YYYY-MM-DD-<feature>.md`
(user preference overrides). If a GOAL.md contract exists, its done_when,
guards, and caps are the plan's law — copy them into Global Constraints.

## Scope and file structure first

- If the spec spans independent subsystems, split into one plan per subsystem;
  each must produce working, testable software on its own.
- Before tasks, map every file to create/modify and its single responsibility.
  Files that change together live together; split by responsibility, not
  layer. This locks decomposition in.

## Task right-sizing and bite-sized steps

A task is the smallest unit carrying its own test cycle and worth a fresh
reviewer's gate — split only where a reviewer could reject one task while
approving its neighbor. Each step is one 2–5 minute action: write the failing
test → run it, confirm it fails → minimal implementation → run tests, confirm
pass → commit.

## Required header

```markdown
# [Feature] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: charge:subagent-driven-development
> (recommended), charge:executing-plans (inline), or charge:loop (unattended,
> self-reprompting). Steps use `- [ ]` checkboxes.

**Goal:** [one sentence]  **Architecture:** [2-3 sentences]  **Stack:** [key tech]

## Global Constraints
[Spec-wide requirements verbatim — version floors, naming, platform, GOAL.md
guards/caps — one line each. Every task implicitly includes these.]
```

## Task structure

Per task: **Files** (Create/Modify/Test with exact paths and line ranges),
**Interfaces** (Consumes: exact signatures from earlier tasks; Produces: exact
names/types later tasks rely on — a task's implementer sees only their own
task, this block is how neighbors' names reach them), then checkbox steps with
real code blocks and exact commands with expected output.

## No placeholders — these are plan failures

"TBD", "TODO", "add appropriate error handling", "write tests for the above"
(without the test code), "similar to Task N" (repeat the code), steps that say
what without showing how, references to types no task defines.

## Self-review (yourself, inline)

1. **Spec coverage:** every spec requirement points to a task; add missing.
2. **Placeholder scan:** hunt the patterns above; fix.
3. **Type consistency:** later tasks use exactly the names/signatures earlier
   tasks defined.

## Execution handoff

Offer: **1. Subagent-Driven** (fresh subagent per task, two-stage review —
recommended), **2. Inline** (executing-plans, batch with checkpoints),
**3. Unattended** (loop — self-reprompting until the contract's done_when,
for long runs). Invoke the chosen skill.

## Constitution feed

If `goal/assets/speckit/constitution-template.md` has been instantiated for
this project, its articles are law: copy the relevant ones verbatim into
Global Constraints before writing any task. A plan that contradicts the
constitution is NOT-READY, not a judgment call.
