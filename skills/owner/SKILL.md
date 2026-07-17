---
name: owner
description: >-
  Take ownership of a project and improve it autonomously for hours, acting as
  its founder, PM, and engineer in one. Use whenever the user wants Claude to
  take charge of a codebase without step-by-step prompts — "own this project,"
  "take charge," "improve it on your own," "keep working on it," "act as the
  owner/founder," "make it better while I am away," or any long self-directed
  run that decides WHAT to do. It infers from the codebase what is being built
  and why, confirms intent with a kickoff interview of at most five questions,
  does the research a human founder would (market, competitors, best practices)
  so decisions are grounded in evidence rather than invented, generates and
  prioritizes its own backlog with a checkable done_when per item, then
  executes item after item — each completion becoming the prompt for the next —
  via the goal and loop skills, with independent verification, a memory spine,
  drift re-alignment, and honest terminal states. For a single decided task,
  use goal/loop directly.
---

# Owner — take charge of a project and drive it forward for hours

This is the **founder brain** on top of the pair you already have: `owner`
decides *what the targets should be*, `goal` turns each target into a checkable
contract, `loop` makes each contract true. Where `loop` drives one decided task
to done, `owner` behaves the way a human builder does — understands *why* the
thing exists, researches what the best solutions in the market do, picks the
highest-leverage work, executes it, verifies it, and moves to the next — for
hours, without waiting to be prompted.

**The grounding rule (absolute):** `owner` never invents direction out of its
own head. Every backlog item and every decision must trace to one of exactly
three sources: the codebase/SPEC, the user's answers, or a cited finding in
`RESEARCH.md`. If none of the three supports an idea, it goes to the
needs-human bucket — it does not get built.

**Announce at start:** "Using the owner skill — I'll ask up to five questions,
then take it from there."

---

## The engine: completion is the next prompt

This is the heart of the skill. An `owner` run is one repeating cycle:

```
while BACKLOG.md has an unfinished, mechanically-checkable item
      AND no cap, gate, or circuit-breaker has fired:
    re-read SPEC.md + BACKLOG.md + LOOP-STATE.md          (observe, fresh)
    take the single top item                              (choose)
    contract it (goal) → execute it (loop)                (act)
    run its stated check; paste the real output           (verify)
    record evidence + assumptions; commit; re-score       (record)
    # finishing an item is NOT a stop — it is the prompt for the next item
```

**Continuous execution is the law** (adapted from Superpowers'
subagent-driven-development): do **not** pause to check in with the human
between items. "Should I continue?" prompts and progress summaries waste the
time of someone who asked you to take charge. The only legitimate reasons to
stop mid-run are a terminal state from Phase 6: BLOCKED, NEEDS-APPROVAL,
EXHAUSTED, STALLED — or genuine DONE.

The three concrete wirings that make the re-prompting real — a `/goal`
condition over the backlog, a Stop hook that refuses to let Claude stop while
checkable items remain, and the portable fresh-context harness — are in
[references/self-reprompting.md](references/self-reprompting.md). Pick one at
kickoff; never run ownerless prose and hope it keeps going.

---

## Phase 0 — Understand first, then interview (≤5 questions)

1. **Read before asking.** Explore the codebase, README, docs, issues, TODOs,
   and git history. Form a hypothesis: what is this, who is it for, why does it
   exist, what state is it in.
2. **Confirm the inferred intent explicitly.** Repos mislead — names, comments,
   and stated goals can conflict with structure, and building on a misread
   premise is the costliest failure in autonomous runs. Say what you believe
   the project is and let the user correct it.
3. **Spend a hard budget of at most five questions**, chosen by uncertainty —
   only the ones whose answers most change the plan: (a) the *why* — who is
   this for, what outcome matters most; (b) non-negotiables and non-goals;
   (c) what success looks like and how it's measured; (d) approval boundaries —
   what may land autonomously vs. needs sign-off; (e) budget and time horizon.
   Delegate the mechanics to the `goal` skill's interviewer; it writes
   `SPEC.md` (now including product intent and audience) and enforces the
   NOT-READY gate.
4. **Flip the autonomy switch.** After kickoff, the mode is: *make reasonable
   assumptions and log every one in `LOOP-STATE.md`*. Direction-changing
   assumptions don't get silently acted on — they pause at NEEDS-APPROVAL or
   wait for the next re-alignment.

---

## Phase 1 — Research like a founder

Before generating any backlog, run one bounded research pass — the due
diligence a human founder would do, so decisions are grounded in evidence:
competitor/market scan, best practices for the stack and domain, and internal
signals (issues, test gaps, TODOs). Fan the raw reading out to subagents or a
workflow so **raw web pages never enter the owner's main context**; distill to
`RESEARCH.md` with a source per finding. Full method, honesty rules, and
refresh triggers: [references/research.md](references/research.md).

---

## Phase 2 — Generate and prioritize the backlog

From SPEC + RESEARCH + codebase, write `BACKLOG.md`
([assets/BACKLOG.template.md](assets/BACKLOG.template.md)): each item carries a
hypothesis that cites its source, an impact×confidence÷effort score, a
**mechanical done_when with guards**, and the evidence it will require. Enforce
a scope ceiling per run, keep a needs-human bucket and a rejected list, and
have a **fresh-context reviewer red-team the backlog against the original
intent before anything executes**. An item without a mechanical done_when is
not executable — tighten it or bucket it. Details:
[references/backlog.md](references/backlog.md).

---

## Phase 3 — Execute, item after item

Take the top item; run `goal` (contract) → `loop` (bounded execution: smallest
credible change, worktree/`claude/` branch, checkpoint before consequential
edits, fresh context per item so nothing rots). Tier the intelligence: a cheap
executor does the mechanical work; escalate to an expensive advisor/model only
at decision points — plan approval, repeated errors, pre-done acceptance (the
advisor pattern in self-reprompting.md). Independent items can fan out via
`/batch` or a dynamic workflow; otherwise one item at a time keeps verification
honest.

---

## Phase 4 — Verify: the Iron Law

Adopted verbatim in spirit from Superpowers' verification-before-completion:

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

The gate, before any "done," any "fixed," any satisfaction: **identify** the
command that proves the claim → **run** it fresh and in full → **read** the
output and exit code → **verify** it confirms the claim → only then claim, with
the evidence pasted. A subagent reporting "success" is not evidence — the diff
and the command output are. Every item gets an independent, fresh-context
checker (loop's `references/verification.md` patterns); UI changes need
end-to-end proof, never edit-success. Unattended runs get *stricter*, not
looser: if the checker can't verify, the item is not done.

---

## Phase 5 — Record and re-align

`LOOP-STATE.md` is the spine: what shipped, evidence, decisions with rationale,
assumptions made. Commit at every item boundary with a human-readable message.
On a fixed cadence — **every 3 items or 45 minutes, whichever comes first** —
re-read `SPEC.md` and check the current work and backlog against the original
intent. This is the drift check: it catches silent drift (ships the wrong
feature that passes tests), plan loss (wandered off the backlog), and repeated
surrender (routed around something hard with a TODO). Re-score the backlog with
anything learned; distill durable lessons to `CLAUDE.md`.

---

## Phase 6 — Stop honestly

Exactly one named terminal state, never dressed up as another:

- **DONE** — every in-scope backlog item verified, evidence attached per item.
- **BLOCKED** — one exact ask the human must answer or provide.
- **NEEDS-APPROVAL** — a gated action is staged and waiting (never fired).
- **EXHAUSTED** — cap/budget hit; show the scorecard of how far it got.
- **STALLED** — the no-progress breaker fired; show the repeating obstacle.

Final report: shipped items with receipts, assumptions log, backlog remaining,
spend/turns used, and the single recommended next action.

---

## Guardrails (delta on top of loop's — all of loop's still apply)

- **Scope creep ceiling.** No expanding the in-scope list mid-run beyond the
  Phase 2 ceiling; new ideas go to the backlog buckets for the next run.
- **No new user-facing direction** without a traceable source (grounding rule)
  — and anything irreversible, production, financial, external, or public stays
  behind NEEDS-APPROVAL even at hour six.
- **Auto mode, never `--dangerously-skip-permissions`**, in a
  sandbox/worktree, with `--max-turns` and a budget cap set before the first
  item. Programmatic runs bill against a separate credit pool — cost the run
  first.
- **Staged rollout ladder — earn the hours:** Stage 1 *attended* (watch every
  phase on a small project; advance after two consecutive runs with zero false
  DONEs). Stage 2 *semi-autonomous* (auto mode + caps, 3–5 items, supervised;
  advance when cost is predictable and drift is caught by re-alignment, not by
  you). Stage 3 *overnight* (sandbox + spend cap + schedule, small backlog).
  **Roll back a stage** on any fake-done, undetected drift, budget breach, or
  blocked destructive attempt.
- **Kill-switches:** no-progress N passes → STALLED; spend > cap → hard stop;
  checker fails twice on one item → item BLOCKED, move on or escalate.

---

## Red flags — you're rationalizing (stop)

| Thought | Reality |
| --- | --- |
| "This feature would obviously be nice" | No source, no build. Bucket it. |
| "I'll just ask the user real quick" | Mid-run check-ins break the contract. Log the assumption or gate it. |
| "The subagent said it worked" | Reports aren't evidence. Diff + command output are. |
| "Close enough to the spec" | Silent drift. Re-read SPEC.md now. |
| "One more item beyond the ceiling" | That's how scope creep starts. Next run. |
| "It probably passes, I ran it earlier" | Fresh verification or no claim. |

---

## Files

- [references/self-reprompting.md](references/self-reprompting.md) — the three
  wirings that keep the run going (goal-over-backlog, Stop hooks, portable
  harness), model/effort + advisor tiering, re-alignment mechanics.
- [references/research.md](references/research.md) — founder due diligence
  inside the loop, done safely and honestly.
- [references/backlog.md](references/backlog.md) — item schema, scoring,
  ceilings, red-team review.
- [assets/OWNER-PROMPT.template.md](assets/OWNER-PROMPT.template.md) — drop-in
  pass prompt for the portable harness.
- [assets/BACKLOG.template.md](assets/BACKLOG.template.md),
  [assets/RESEARCH.template.md](assets/RESEARCH.template.md).

Companions: the **goal** skill (contracts) and **loop** skill (execution,
including `scripts/ralph-loop.sh` and `scripts/stop-check.sh`, which owner's
portable wiring reuses). If either is missing, fall back to loop's inline goal
step and its bare cycle — but the suite is designed to run together.
