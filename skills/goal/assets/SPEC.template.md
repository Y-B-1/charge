# SPEC — <feature / project name>

> What to build, and what not to. The product decision, free of implementation
> detail. Keep it short; every line should be something the user actually decided.

## Goal (one sentence)
<what finished delivers, in plain language>

## Build  (what's in scope)
- <capability 1>
- <capability 2>

## Exclude  (explicitly out of scope — say the no's)
- <thing we are deliberately NOT doing>

## Consider  (edge cases & failure modes that matter)
- <edge case / risk and how it should behave>

## done_when  (measurable completion checks — each is a yes/no a command can answer)
- [ ] <e.g. `npm test` exits 0 with 0 failures>
- [ ] <e.g. `GET /users` returns 200 with a paginated JSON body; contract test passes>
- [ ] <e.g. `rg "legacy-api" src/` returns no matches AND typecheck passes>

## Open questions / product forks  (resolve with the user — don't let an agent pick)
- <decision still needed, with the options>
