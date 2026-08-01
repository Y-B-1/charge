# CONSTITUTION — <PROJECT-NAME>

Invariants that are expensive or impossible to reverse.

**Authority.** This file is amendable by the user only. An agent may propose an
amendment; it may never write one. If work requires violating an article,
the work stops and asks — it does not reinterpret the article.

**Rank.** The user's verbatim words and `docs/agents/rulings-*.md` outrank this
file. This file outranks `CLAUDE.md`, the current plan, and `AGENT-MEMORY.md`.

<!-- Keep this short. A preference is not an invariant. The test: would
     violating it cost real money, real data, real trust, or a rewrite?
     If not, it is a CLAUDE.md rule, not an article. -->

## Articles

### A1 — <SHORT NAME>

<THE INVARIANT, ONE OR TWO SENTENCES, STATED AS AN ABSOLUTE.>

- Why it is hard to reverse: <ONE LINE.>
- Enforced by: `<HOOK / TEST / CI CHECK>` <!-- or "prose only - unenforced" -->

### A2 — <SHORT NAME>

<THE INVARIANT.>

- Why it is hard to reverse: <ONE LINE.>
- Enforced by: `<HOOK / TEST / CI CHECK>`

## Amendment log

<!-- Every amendment, in order, with the user's AUTHORIZING WORDS QUOTED
     VERBATIM. No entry, no amendment. Without this log, agents relitigate
     settled decisions. -->

| Date | Article | Change | User's authorizing words (verbatim) |
|---|---|---|---|
| `<YYYY-MM-DD>` | A<N> | <ADDED / CHANGED / REMOVED> | "<QUOTE>" |

## Decisions that are not articles

Reasoned decisions with alternatives and consequences go in `docs/adr/`, not
here. An article states a boundary; an ADR explains a choice.
