---
name: executing-plans
description: >-
  Use when executing a written implementation plan inline in this session (or
  when subagents are unavailable) — batch execution with review checkpoints.
  Loads the plan, reviews it critically, executes tasks exactly with their
  verifications, and hands off to finishing-a-development-branch. For
  independent tasks with subagents available, prefer subagent-driven-
  development; for unattended runs, use loop.
---

# Executing Plans

Load plan, review critically, execute all tasks, report when complete.
**Announce at start.** Work in an isolated workspace
(charge:using-git-worktrees) — never on main without explicit consent.

## Process

1. **Load and review.** Read the plan file; review critically. Concerns →
   raise them before starting. None → create a todo per task and proceed.
2. **Execute each task:** mark in_progress → follow each bite-sized step
   exactly (the plan shows the code; write it) → run the specified
   verifications and paste real output → mark completed. Commit per the plan's
   cadence.
3. **Complete:** after all tasks verified, invoke
   charge:finishing-a-development-branch (verify suite → present options →
   execute choice).

## Continuous execution

Do not pause between tasks for "should I continue?" check-ins or progress
summaries — the human asked you to execute the plan. Stop ONLY for: a blocker
you cannot resolve (missing dependency, repeated verification failure, unclear
instruction), a plan gap that prevents starting, or all tasks complete. Ask
rather than guess; don't force through blockers.

## Revisit the plan when

The human updates it on your feedback, or the approach itself proves wrong —
return to review, don't improvise a divergent plan silently.

## Remember

Follow steps exactly; never skip verifications; reference skills when the plan
says to (TDD inside every code step; systematic-debugging on any failure;
verification-before-completion before any claim); stop when blocked.
