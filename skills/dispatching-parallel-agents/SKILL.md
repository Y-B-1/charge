---
name: dispatching-parallel-agents
description: >-
  Use when facing 2+ independent tasks or failures with no shared state or
  sequential dependency — different test files, different subsystems, separate
  bugs. Dispatches one focused subagent per problem domain, all in the same
  response so they run concurrently, then reviews, conflict-checks, and
  integrates. For wide splittable changes, also consider /batch or a dynamic
  workflow (see the loop skill's mechanisms reference).
---

# Dispatching Parallel Agents

One agent per independent problem domain, working concurrently. Subagents get
precisely crafted, self-contained context — never your session history — which
keeps them focused and preserves your context for coordination.

## Decide

Independent (fixing one can't fix or break another; no shared state) AND
parallelizable → parallel dispatch. Related failures → one agent investigates
all. Shared state → sequential agents. Wide mechanical change across many
files → consider `/batch` (worktree fan-out) or a dynamic workflow instead.

## The pattern

1. **Group by what's broken** — one domain per test file/subsystem/bug.
2. **Craft each task:** specific scope (one file/subsystem), clear goal ("make
   these tests pass"), constraints ("don't change other code"; include the
   relevant Global Constraints), expected output (summary of found + fixed).
   Self-contained: all context needed, nothing more.
3. **Dispatch all in ONE response** — multiple dispatches in one message run in
   parallel; one per message runs sequential. Specify a model per agent
   (subagent-driven-development's table).
4. **Review and integrate:** read each summary → check for conflicts (same
   code edited?) → run the FULL suite yourself → spot-check; agents make
   systematic errors, and their "success" reports are not evidence.

## Don't

Dispatch related failures separately; let agents share mutable state; skip the
full-suite run because every agent reported green.
