# LOOP-STATE — <project / goal name>

> The spine. Re-read this at the start of every pass and append to it at the end.
> Without it, each pass restarts from zero and you get the same first step forever.
> This file is the one source of truth for "what's done / what's next" across runs.

## goal
<one line — or "see GOAL.md"> · done_when: <copy the checkable conditions>

## status:  IN-PROGRESS | DONE | BLOCKED | NEEDS-APPROVAL | EXHAUSTED | STALLED
turn: <n> / <cap>   ·   last checkpoint: <git sha>

## done so far  (newest first; one line each, with evidence)
- [pass N] <what changed> — <verify output, e.g. tests 142/142 ✅> — <sha>

## next  (the single largest remaining gap)
- <the one highest-leverage thing the next pass should do>

## open / blocked / needs decision
- <anything waiting on access, a tool, or a human decision>

## attempts that failed  (so the loop doesn't repeat them — root cause, not symptom)
- <what was tried, why it failed, what to avoid>

## lessons  (distill into CLAUDE.md if project-wide)
- <a correction worth carrying to the next run>
