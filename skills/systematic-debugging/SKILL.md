---
name: systematic-debugging
description: >-
  Use when encountering any bug, test failure, build break, or unexpected
  behavior, BEFORE proposing fixes — especially under time pressure, after a
  failed fix, or when a quick patch seems obvious. Enforces root-cause
  investigation through four phases; symptom fixes are failure. Includes
  root-cause tracing, defense-in-depth, and condition-based-waiting references.
---

# Systematic Debugging

Random fixes waste time and create new bugs. **Iron Law:**

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Use for ANY technical issue — and ESPECIALLY under pressure, when "one quick
fix" tempts, after 2+ failed fixes, or when you don't fully understand it.
Systematic is faster than thrashing (~95% first-time fix rate vs ~40%).

## Phase 1 — Root cause investigation (before ANY fix)

1. **Read the error completely** — full stack trace, line numbers, codes; the
   answer is often in it.
2. **Reproduce consistently** — exact steps; not reproducible → gather data,
   don't guess.
3. **Check recent changes** — git diff/log, new deps, config, environment.
4. **Multi-component systems: instrument the boundaries** — log what enters
   and exits each layer, run once, find WHERE it breaks, then investigate that
   component. Evidence before theories.
5. **Error deep in a call stack →** [root-cause-tracing.md](root-cause-tracing.md):
   trace backward to the original trigger.

## Phase 2 — Pattern analysis

Find a working example of the same pattern in this codebase; compare precisely;
read referenced code COMPLETELY (partial understanding guarantees bugs).

## Phase 3 — Hypothesis

One clear theory of the mechanism → the smallest test that confirms or kills
it → confirmed: fix it; killed: new hypothesis. One change at a time — multiple
simultaneous fixes can't be isolated.

## Phase 4 — Implementation

Write the failing test that reproduces the bug (charge:test-driven-development)
→ minimal fix → full suite green → charge:verification-before-completion.
After the fix, consider [defense-in-depth.md](defense-in-depth.md) validation
at the layers the bug crossed. Flaky timing waits →
[condition-based-waiting.md](condition-based-waiting.md).

## Escalation and honesty

**3+ failed fix attempts = architectural problem** — stop patching, question
the pattern, discuss with the human (in a loop run: that's the circuit-breaker;
report STALLED with the repeating obstacle). If investigation truly ends at
environmental/external: document what you ruled out, add
handling+logging — but 95% of "no root cause" is incomplete investigation.

| Excuse | Reality |
| --- | --- |
| "I see the problem, quick fix" | Symptom ≠ root cause. |
| "No time for the process" | Thrashing is slower. |
| "Test after confirming the fix" | Untested fixes don't stick. |
| "One more attempt" (after 2+) | Question the architecture. |
