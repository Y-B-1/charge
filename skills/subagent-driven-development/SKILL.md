---
name: subagent-driven-development
description: >-
  Use when executing an implementation plan with mostly independent tasks in
  the current session and subagents are available. Dispatches a fresh
  implementer subagent per task with precisely crafted context (never session
  history), a task reviewer (spec compliance + code quality) after each, and a
  broad whole-branch review at the end — continuous execution, no between-task
  check-ins.
---

# Subagent-Driven Development

Fresh implementer subagent per task + per-task review + broad final review =
high quality, fast iteration. Subagents never inherit your session's context —
you construct exactly what each needs; that keeps them focused and preserves
your context for coordination. Narrate at most one short line between
dispatches; the ledger and tool results carry the record.

**Continuous execution:** never pause between tasks to check in. Stop only for
BLOCKED-you-can't-resolve, genuine ambiguity, or all-tasks-complete.

## Process

1. **Read the plan**; note Global Constraints; create the todo ledger.
2. **Pre-flight scan** (once): tasks that contradict each other or the
   constraints, or anything the plan mandates that the review rubric treats as
   a defect. Batch ALL findings into one question to the human before Task 1 —
   not one interrupt each mid-run. Clean scan → proceed silently.
3. **Per task:** dispatch an implementer from
   [implementer-prompt.md](implementer-prompt.md) (task brief, context,
   invitation to ask questions first). It implements with TDD, tests, commits,
   self-reviews. Then write the diff and dispatch a task reviewer from
   [task-reviewer-prompt.md](task-reviewer-prompt.md) for two verdicts: spec
   compliance and code quality. Critical/Important findings → dispatch a fix
   subagent → re-review. Approved → mark complete in ledger.
4. **After all tasks:** dispatch the final whole-branch reviewer
   (../requesting-code-review/code-reviewer.md) on the most capable model,
   then charge:finishing-a-development-branch.

## Model selection (specify explicitly on EVERY dispatch)

An omitted model silently inherits your session's — usually the most
expensive. Turn count beats token price: the cheapest models take 2–3× the
turns on multi-step work, so use mid-tier as the floor for reviewers and for
implementers working from prose.

| Task | Model |
| --- | --- |
| Plan text contains the complete code (transcription + testing); single-file mechanical fix | cheapest tier |
| 1–2 files, complete spec | cheap |
| Multi-file integration, pattern matching, debugging | standard |
| Design judgment, broad codebase understanding, the final whole-branch review | most capable |
| Reviews | scale to the diff's size and risk |

## Verification rule

A subagent reporting "success" is not evidence — read its diff, and run the
suite yourself before marking the ledger. charge:verification-before-completion
governs every claim.
