---
name: goal
description: >-
  Turn a rough idea or vague ticket into a buildable, checkable plan before
  anyone — you, an autonomous loop, Codex's /goal, or a teammate — starts
  building. Use whenever the user wants to define what "done" means, write a spec
  or acceptance criteria, scope a feature (what to build, what's out of scope,
  edge cases), set measurable completion checks, or get a rough coding idea ready
  to hand off for autonomous execution. Trigger on "help me spec this," "what
  should this build," "turn this idea into a plan," "write the acceptance
  criteria," or "plan it before I loop on it." It interviews the user, writes
  SPEC.md (what to build / exclude / consider) and GOAL.md (work plan, mechanical
  done_when checks, evidence, approval boundaries, caps), turns fuzzy goals into
  commands that return yes/no, and returns an explicit NOT-READY state when a key
  decision, tool, or test is missing instead of starting blind. It defines the
  destination; the loop skill drives to it.
---

# Goal — define a checkable destination before you build

This skill produces the **destination**: a spec and a goal crisp enough that
something else — you, the `loop` skill, Codex's `/goal`, or another engineer —
can drive to it and *prove* it arrived. It does not write the feature; it makes
the feature buildable and verifiable, then hands off.

The one idea under everything here: **a goal you can't check is a wish.** A wish
handed to an autonomous agent loops forever burning tokens, or stops the moment
the agent *feels* done. So the job is to (1) decide what "done" actually means,
(2) express it as checks a machine can answer yes/no, and (3) refuse to call it
ready when an essential decision, tool, or test is still missing.

Separate **what** from **how**: `SPEC.md` is the product decision (what to build,
what to exclude, what to consider); `GOAL.md` is the execution contract (the
plan, the checks, the evidence, the boundaries). Keeping them apart means a
change to one doesn't quietly corrupt the other.

Do not start implementation from this skill. Produce the plan, mark it READY or
NOT READY, and stop. Hand off to `loop` (or Codex `/goal`) to execute.

---

## Step 1 — Interview the user

**Infer before you ask.** Read the codebase, docs, and anything the user
already wrote first, and form a hypothesis of the intent — then **confirm that
inferred intent explicitly**, because repos mislead (names, comments, and
stated goals can conflict with structure) and building on a misread premise is
the costliest failure. Spend a hard budget of **at most five questions**,
chosen by uncertainty: only the ones whose answers most change the plan.

Assume they're busy and may be new to this. Ask **one short, plain-language
question at a time**, and only the ones still unanswered — pull everything you
can from what they've already said or written. Resolve genuine product forks
*with the user*; never let an agent silently pick what the thing should be.

For autonomous runs (e.g. under the `owner` skill), close the interview with
the switch: *"From here I'll make reasonable assumptions and log each one;
direction-changing ones will pause for your approval."* Interview once, then
commit — don't drip questions into the run.

1. "What should be true when this is finished?" → the core outcome.
2. "What's explicitly out of scope?" → non-goals (just as important as goals).
3. "Which edge cases or failure modes actually matter here?" → what to consider.
4. "How will we *prove* it's done — what command, count, or check?" → evidence.
   If they don't know, propose one and confirm.
5. "Anything that should pause for your approval before it happens?" → gates
   (deploys, deletes, sends, money, public posts, schema/access changes).
6. "How long or expensive should the build be allowed to run?" → caps. Propose a
   conservative default if unspecified and state it.

Stop once more detail wouldn't change the plan. Point out ambiguous requirements
with a concrete interpretation and let the user resolve them, rather than
guessing. Don't invent a stack, tool, metric, owner, schedule, or environment —
keep unknowns generic ("the existing test suite") or ask one targeted question.

---

## Step 2 — Write SPEC.md (what to build)

Use [assets/SPEC.template.md](assets/SPEC.template.md). Capture: what to build,
what to exclude, edge cases that matter, and the **measurable `done_when`**
completion checks. This is the decision record — short, concrete, and free of
implementation detail. Every requirement should trace to something the user
actually said or decided.

---

## Step 3 — Write GOAL.md (how to execute and verify)

Use [assets/GOAL.template.md](assets/GOAL.template.md). Capture:

- the **ordered work** (the slices, roughly in dependency order);
- a **progress scorecard** (what's done / in progress / not started);
- a **quick check** to run each pass and a **slower final check** to confirm the
  whole thing;
- the **memory file** for long runs (`LOOP-STATE.md`) so progress survives
  between passes;
- the **evidence** each requirement needs to count as done;
- the **approval boundaries** and the **caps** (turns/iterations and budget).

`GOAL.md` is what an executor reads to know *how* to drive and *when* to stop.

---

## Step 4 — Make every `done_when` mechanical

This is the highest-leverage step. Each completion check must be a command,
count, or diff with a yes/no answer and **no interpretation**, paired with the
exact command that proves it. Rewrite every soft phrase:

| Fuzzy (a wish) | Mechanical (a goal) |
| --- | --- |
| "tests pass" | "`npm test` exits 0 with 0 failures" |
| "code is clean" | "`npm run lint` exits 0 **and** `npm test` still exits 0" |
| "the build works" | "`npm run build` exits 0 and produces `dist/`" |
| "migrate off the legacy API" | "`rg \"from './legacy-api'\"` returns no matches **and** typecheck + tests pass" |
| "good coverage" | "coverage ≥ 80% lines with all tests passing" |
| "no more flaky tests" | "the suite passes N consecutive full runs under the same conditions" |
| "the endpoint works" | "`GET /users` returns 200 with a paginated JSON body; the contract test passes" |

Two rules that catch the common failures:

- **Add guard conditions** so the letter can't be met while the intent is
  violated. The classic trap is "make the linter pass," which an agent satisfies
  by *deleting* the linted code — so pair it: "…**without** reducing coverage,"
  "…**without** changing public behavior," "…**without** editing files outside
  `src/`."
- **Name the proving command**, because an autonomous evaluator (e.g. Claude
  Code's `/goal` checker) reads the transcript and **can't run tools** — it can
  only confirm a result that gets surfaced. "Done" must be something a named
  command's output can show.

A solid `done_when` has a clear end state, a check it can run, and a guardrail.

---

## Step 5 — Readiness check (the honest NOT-READY state)

Before declaring the plan ready, confirm the essentials exist. Mark the goal
**NOT READY** and list exactly what's missing if any of these is absent:

- a key product decision (two reasonable builds still diverge),
- a required permission or access,
- a required tool, integration, or environment,
- a way to actually run the completion check (the test/command exists).

Do not paper over a gap with a "sensible default" or an invented detail. An
honest NOT-READY with a short list of blockers is far more useful than a
confident plan that sends an agent off to build the wrong thing or to spin on a
check it can't run.

---

## Step 6 — Hand off

When the plan is **READY** and approved, hand off to execution — don't build it
here:

- **Claude Code:** run the `loop` skill; it consumes `SPEC.md`/`GOAL.md`, drives
  to the `done_when` with verification and a memory spine, and stops at a named
  terminal state with proof.
- **Codex:** the same `GOAL.md` can seed Codex's `/goal` (which tracks a target);
  keep the conditions tight since it stops when satisfied.
- **Under the `owner` skill:** you were likely invoked from its kickoff or its
  per-item contracting — return the contract and let `owner` drive the backlog;
  it calls `loop` for each item and keeps the run going between items.

Deliver a short summary: the outcome, the `done_when` checks, the caps, the
approval gates, and the readiness verdict (READY / NOT READY + blockers).

---

## Constitution and consistency (spec-kit integration)

Two upgrades for bigger projects, carried from GitHub's spec-kit (MIT;
templates in [assets/speckit/](assets/speckit/)):

- **A constitution** — instantiate
  [assets/speckit/constitution-template.md](assets/speckit/constitution-template.md)
  once per project: the non-negotiable principles every spec and plan must
  honor. writing-plans copies the relevant articles verbatim into its Global
  Constraints; a plan that contradicts the constitution is NOT-READY.
- **An analyze pass before READY** — cross-artifact consistency: every SPEC
  requirement maps to a GOAL work item (and later to a plan task); every
  done_when names its proving command; an ambiguity scan (any line with two
  readings gets one made explicit). Coverage gaps are NOT-READY blockers, not
  footnotes. The full spec/plan/tasks/checklist templates in the same folder
  serve when a heavier scaffold is warranted.

## Files

- [assets/SPEC.template.md](assets/SPEC.template.md) — what to build / exclude /
  consider + measurable done_when.
- [assets/GOAL.template.md](assets/GOAL.template.md) — the execution contract:
  plan, checks, evidence, boundaries, caps.

`LOOP-STATE.md` (the progress spine the executor writes during the run) is owned
by the `loop` skill.
