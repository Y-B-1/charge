# Doctrine baseline — the rules most likely already global

Read this only while running the T0 dedup check.

These are the standing rules a well-configured operator already carries in their
**global** instruction file. They are listed here so you can recognise them and
**delete** them from a project `CLAUDE.md` — not so you can copy them in.

## The baseline set

- Load the minimum context that makes the task solvable; read the pointed file, not the whole area.
- Answer tersely: return diffs not files, skip restating context.
- Plan read-only before editing: state assumptions, ask one question at a time, never ask what the codebase can answer.
- Make done checkable — success criteria must return yes/no (tests pass, command exits 0).
- Work one ticket per session; keep state on disk (spec, progress file, commits), not in conversation.
- Commit every working iteration; a bad step is a revert, not a debugging session.
- Write tests red-green-refactor; assert behavior, never the mock.
- Ship a thin end-to-end slice first and verify the whole pipe before widening.
- Push searches, bulk reads, and verification into subagents that return one result.
- If a rule must always hold, propose a hook or check — don't add another sentence here.

## How to use it

1. Read the user's global instruction file if it is readable.
2. For each candidate project line, ask: **does the global file already say
   this, in any wording?** If yes → delete the project line.
3. If no global file exists, you may seed the project file from this list — but
   still apply the no-op test to each line, and keep the total under 200 lines.
4. If the project needs a *different value* than a global rule (different test
   command, different commit cadence, a documented exception), write the
   **delta** in one line — never restate the rule and then amend it.

## Why deletion is the default

Every always-loaded sentence spends instruction budget. Models follow only a few
hundred standing instructions with consistency, and adherence drops as files
grow. A duplicated rule buys nothing and risks a near-duplicate that conflicts
with its global twin — conflicting standing rules get resolved arbitrarily.

The bar for a standing project line is: **undiscoverable from the repo AND
relevant in most sessions.** Everything else belongs in a skill, a path-scoped
rule, or a hook.
