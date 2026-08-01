# The goal handoff

> **Canonical authoring lives in the `goal` skill.** If it's installed, invoke it
> (it interviews the user and writes `SPEC.md`/`GOAL.md`) and skip the interview
> below. This file is `loop`'s built-in fallback so it still never starts blind
> when the `goal` skill isn't present. Either way, the non-negotiable is §3: a
> mechanical `done_when`.

A loop is only as good as the finish line it drives toward. This file covers how
to **get a checkable `done_when`** before the loop starts — by reusing one that
already exists, or authoring a minimal one when it doesn't. This is the seam
where `loop` meets a goal/spec skill: `loop` is the engine, the goal is the
destination. Keep them separate in your head even when this skill does both.

## 1. Detect the destination before authoring one

Check these in order and stop at the first hit. Re-deriving a goal the user
already wrote is wasted effort and risks contradicting their decisions.

1. **The `goal` skill (or any installed goal/spec skill).** If it's available,
   **invoke it and let it own the destination** — it interviews the user and
   writes `SPEC.md` + `GOAL.md`. Then come back here for execution. This is the
   cleanest pairing.
2. **Goal artifacts in the repo / message.** `GOAL.md`, `SPEC.md`, `PLAN.md`, a
   `done_when`/acceptance-criteria block, a linked ticket or issue, a PR
   description, or a clear finish line stated in the user's prompt. Use it as-is.
3. **Nothing usable.** Run the compressed interview below.

If artifacts exist but are **vague** (e.g. a ticket that says "improve
performance"), don't reject them — keep their intent and *tighten only the
`done_when`* via §3, asking one question if a number or command is genuinely
unknown.

## 2. The compressed goal interview

Assume the user is busy and may be new to loops. Ask **one short plain-language
question at a time**, and only the ones still unanswered. Don't use jargon
(trigger, terminal state, gate) unless they do. Start with the first; infer the
rest where you can.

1. "What should be true when this is finished?" → the **done_when**.
2. "What's explicitly out of scope or off-limits?" → **non-goals** + approval
   boundaries.
3. "How will we *prove* it's done — what command, count, or check?" → the
   **verification**. If they don't know, propose one and confirm.
4. "Anything that would make you want to be asked before it happens?" →
   **approval gates** (deploys, deletes, sends, money, public posts).
5. "How long/expensive should it be allowed to run?" → the **cap** (turns and/or
   budget). If unspecified, propose a conservative default and state it.

Stop asking once more detail wouldn't change the design. Write the answers into
`GOAL.md` using `assets/GOAL.template.md`. Keep unknowns generic ("the existing
test suite") rather than inventing specifics.

## 3. Turn a fuzzy goal into a mechanical `done_when`

This is the highest-leverage thing in the whole skill. A `done_when` must be
something a command or count can answer **yes/no with no interpretation**, and
it must name the exact check that proves it. Rewrite every soft phrase:

| Fuzzy (a wish) | Mechanical (a goal) |
| --- | --- |
| "tests pass" | "`npm test` exits 0 with 0 failures" |
| "code is clean" | "`npm run lint` exits 0 **and** `npm test` still exits 0" |
| "the build works" | "`npm run build` exits 0 and produces `dist/`" |
| "migrate off the legacy API" | "`rg \"from './legacy-api'\"` returns no matches **and** `npm run typecheck` exits 0 **and** tests pass" |
| "good coverage" | "coverage ≥ 80% lines (per the coverage report) with all tests passing" |
| "no more flaky tests" | "the suite passes N consecutive full runs under the same conditions" |
| "the endpoint works" | "`GET /users` returns 200 with a paginated JSON body; the contract test passes" |
| "docs are up to date" | "every public symbol in `src/` has a doc entry; the docs build has no broken links" |

Then add **guard conditions** so the loop can't satisfy the letter while
violating the intent — the classic failure is "make the linter pass," which the
model achieves by deleting the offending code. Pair every narrowing target with
what must *not* regress: "…**without** reducing test coverage," "…**without**
changing public behavior," "…**without** editing files outside `src/`."

A good `done_when` has three properties (the Downloads-folder test):

- **A clear end state** — "no loose files left," not "tidy it up."
- **A check it can run** — count the files; run the command.
- **A guardrail** — "do not delete anything," "stop after N turns."

## 4. When *not* to loop at all

If fresh feedback can't change the next action, it's a **one-shot task**, not a
loop — running it in a loop just repeats the same first step. Tell the user and
do it once instead. Loops earn their cost only when each pass sees something new
(a new test result, a new diff, a new error) that steers the next pass.

Also stop and ask, rather than loop, when the blocker is a **product decision**
(two reasonable builds diverge) — the loop can converge a decided target, but it
can't decide what the target should be.

## 5. Two-file split for bigger work (optional)

For substantial builds, separating *what* from *how* keeps each stable:

- **`SPEC.md`** — what to build, what's excluded, edge cases that matter, and the
  measurable `done_when`. The product decision.
- **`GOAL.md`** — how to execute and verify it: the ordered work, the quick
  per-pass check and the slower final check, the memory files, the evidence
  required, the approval boundaries, and the caps.

Then translate the `done_when` list into the loop's contract: each line becomes
a `features[]` entry in `loop-state.json`
([../assets/loop-state.template.json](../assets/loop-state.template.json)) with
its own `verify` command and `passes: false` — the harness gates DONE on zero
`passes:false` plus the verify command, so the goal doubles as the completion
check. `loop-state.json` is the authority across passes; `loop-log.md` carries
the narrative. If a dedicated goal skill produced `SPEC.md`/`GOAL.md`, this
skill just consumes them and runs.
