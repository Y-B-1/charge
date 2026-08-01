---
paths:
  - "<GLOB>/**"
  - "<GLOB>/**"
---

<!-- Path-scoped rule file. Save as .claude/rules/<subsystem>.md
     LOADS ONLY when the agent reads a file matching one of the globs above,
     and after compaction only the project root file is re-injected - these
     rules are LOST until re-triggered.
     So: nothing unconditional goes here. Unconditional and probabilistic ->
     CLAUDE.md. Unconditional and mandatory -> a PreToolUse hook. -->

# <SUBSYSTEM NAME>

<ONE SENTENCE: what this subsystem is and why its rules differ from the rest
of the repo.>

## Read first

- `<PATH>` — <WHAT IT SETTLES>.

## Rules

<!-- Only rules that are FALSE elsewhere in the repo. A rule that applies
     repo-wide belongs in CLAUDE.md, not here - duplicated across rule files it
     becomes drift. -->

- <RULE, ONE LINE, IMPERATIVE.>
- <RULE, ONE LINE, IMPERATIVE.>

## Commands

- Test just this subsystem: `<COMMAND>`

<!-- Keep under 50 lines. Same no-op test as CLAUDE.md: if deleting a line
     would not change behavior, delete it. -->
