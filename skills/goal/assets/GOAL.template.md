# GOAL — <feature / project name>

> How to execute and verify what SPEC.md describes. This is the contract an
> executor (the `loop` skill, or Codex `/goal`) reads to know how to drive and
> when to stop. Pair it with SPEC.md (what) and LOOP-STATE.md (progress).

## readiness:  READY | NOT READY
blockers (if NOT READY): <missing decision / permission / tool / test — be specific>

## done_when  (copied from SPEC.md — each is mechanically checkable)
- [ ] <condition + the command that proves it>
- [ ] <condition + the command that proves it>

## verify
- quick check (run every pass): `<fast command, e.g. the affected unit tests>`
- final check (before declaring done): `<full command, e.g. full suite + lint + typecheck>`

## guards  (what must NOT regress)
- <e.g. do not reduce coverage; no public behavior change; no edits outside src/>

## ordered work  (slices, roughly dependency order)
1. <slice>
2. <slice>

## progress scorecard
- done: <…>   ·   in progress: <…>   ·   not started: <…>

## evidence required  (what proves each slice / the whole thing is done)
- <e.g. command output showing exit 0; a passing contract test; a verified screenshot>

## approval boundaries  (executor PREPARES, then pauses — never fires these itself)
- <e.g. any deploy; push to main; external message; delete; schema/access change>

## caps
- max turns/iterations: <e.g. 20–30>
- budget: <e.g. $X or N tokens>
- stop on no-progress after: <e.g. 3 identical-error or empty-diff passes>

## environment / how to run
- repo & paths in scope: <…>
- setup / build / test / lint commands: <…>
- memory spine: LOOP-STATE.md  ·  branch: claude/<name>  ·  isolation: worktree
