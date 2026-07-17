# Loop recipes — proven presets, adapt then run

Copy-paste starting points, each already shaped correctly: a checkable end
state, a named proving check, guards, and a cap. Adapt the specifics; keep the
shape. Mined and adapted from Anthropic's loops guidance, the Forward Future
Loop Library (MIT), and serenakeyitan/awesome-agent-loops (CC BY 4.0 —
attribution retained); tightened to charge's rules (evidence surfaced every
turn, ceiling clause always present).

## Drive-to-done (`/goal` + auto mode)

**Build green:**
```
/goal `npm run build` exits 0 and `npm run lint` is clean — run them, fix the
first error, re-run, surfacing real output each turn — stop after 10 turns
```

**Migration sweep:**
```
/goal every file importing from ./legacy-api imports from ./v2-api, `rg
"legacy-api" src/` returns nothing, typecheck and the full test suite pass —
stop after 30 turns
```

**Coverage climb (with the anti-gaming guard):**
```
/goal line coverage ≥ 80% with ALL tests passing and no test deleted or
skipped — add focused tests for the least-covered files, re-run coverage each
turn — stop at the threshold or after 12 turns
```

**Flaky-test hunter (streak condition — one pass proves nothing):**
```
/goal the full suite passes 5 consecutive runs under identical conditions —
on any failure, root-cause the flake (charge:systematic-debugging), fix the
cause not the retry, restart the streak count — stop after 25 turns
```

**Review-resolution (nested: timer outside, condition inside):**
```
/loop 30m /goal every open review comment on PR <n> is resolved with a commit
or a reasoned reply, and CI is green — stop after 10 turns
```

## Watch loops (`/loop` — polling, not driving)

**CI babysit:**
```
/loop 10m run `gh pr checks <n>`; all green → say it's ready and stop the
loop; otherwise summarize exactly which check fails and why
```

**Suite watch during someone else's refactor:**
```
/loop 15m run the test suite; on any failure show the failing tests and the
first error verbatim
```

## Scheduled routines (`/schedule` — self-contained prompts, no follow-ups)

**Issue triage:**
```
/schedule every weekday 9am: label issues from the last 24h by area and
severity, post a one-line rationale on each; touch nothing else
```

**Doc drift:**
```
/schedule on push to main: diff changed code against /docs; anything stale →
open a claude/ branch PR fixing only the affected pages
```

## Portable overnight (Ralph harness — fresh context per pass)

```
./ralph-loop.sh -p PROMPT.md -n 20 -c DONE \
  -v "./stop-check.sh -r 'npm test' -r 'npm run lint'"
```
Prompt shape: read LOOP-STATE.md → single most important unfinished thing →
one bounded change → run the checks, paste output → append state → promise
only when the verify gate would pass.

## Owner runs (the full autonomy chain)

```
/goal every in-scope item in BACKLOG.md is status:done with its check's real
output pasted into LOOP-STATE.md, the suite passes, and no NEEDS-APPROVAL is
pending — work top-down, one item at a time — stop after 40 turns
```
(Wirings, Stop-hook variants, and the advisor tiering: owner skill,
`references/self-reprompting.md`.)

## Anti-recipes — shapes that always fail

"Improve the UX" (no exit condition — decompose first via goal) · `/goal` on
an external wait (spins; use `/loop`) · `/loop` on a finish-line job (re-runs
after done; use `/goal`) · any recipe without its ceiling clause · a condition
whose proof never gets surfaced into the transcript.
