# GOAL — <one-line outcome>

> The destination the loop drives toward. Keep it short; every line should change
> what the loop does. If a dedicated goal/spec skill produced SPEC.md + GOAL.md,
> use those instead of this.

## done_when  (mechanical — each line is a command/count with a yes/no answer)
- [ ] <e.g. `npm test` exits 0 with 0 failures>
- [ ] <e.g. `npm run lint` exits 0 AND tests still pass>
- [ ] <e.g. `rg "from './legacy-api'" src/` returns no matches>

## verify with  (the exact command(s) that prove the above, run each pass)
```
<e.g. npm test && npm run lint && npm run typecheck>
```

## guards  (what must NOT regress — pair with each narrowing target)
- <e.g. do not reduce test coverage>
- <e.g. do not change public API behavior>
- <e.g. do not edit files outside src/>

## out of scope / off-limits
- <e.g. no dependency upgrades; no schema changes>

## needs approval  (loop prepares, then pauses — never fires these itself)
- <e.g. any deploy; any `git push` to main; any external message; any delete>

## caps
- max turns/iterations: <e.g. 20>
- budget: <e.g. $X or N tokens>
- stop on no-progress after: <e.g. 3 identical-error passes>

## context the loop needs
- repo / paths in scope: <...>
- how to run things: <build/test/lint commands, env setup>
- state: loop-state.json (the authority — each done_when above becomes a
  features[] entry; agents flip only passes, with evidence)
- narrative: loop-log.md (context for the next pass, never authority)
