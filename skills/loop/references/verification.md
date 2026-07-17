# Verification — the part that makes a loop trustworthy

Boris Cherny's one rule: **always give the agent a way to verify its work** — it
raises quality roughly 2–3×. The corollary is just as important: **the agent
that did the work must not be the only thing that decides it's done**, because
models are good at *looking* finished. The hard part of a task is exactly what a
model learns to route around, since that's where it might fail, and a confident
summary reads like success. Verification is how you stop it faking the finish.

This file is about writing a stop condition the loop **cannot fake or fail to
see**, and about who does the checking.

## 1. A stop condition the loop can't fake

A faking-proof `done_when` has all three:

- **Objective** — a command, exit code, count, or diff with a yes/no answer and
  no interpretation. "`pytest -q` exits 0," not "tests look good."
- **Complete** — it pins down the *intent*, not a proxy. "Lint passes **and**
  tests still pass **and** no files deleted outside `src/`," not "lint passes"
  (which the model can satisfy by deleting the linted code).
- **Visible** — its result actually appears where the checker can read it (see
  §2). A condition the checker can't observe never flips to yes.

If you can't make a condition objective, the task isn't ready for autonomous
execution yet — narrow the scope until some part of it *is* checkable, loop that
part, and hand the subjective remainder back to the human.

## 2. The constraint that quietly breaks `/goal`: the evaluator can't run tools

The `/goal` evaluator reads the **transcript** and **cannot call tools** — it
can't run your tests or read your files on its own. So:

- **Run the check inside the loop and surface its output.** Each turn, actually
  execute `done_when`'s command and let its real output land in the conversation.
  A goal of "the tests pass" only flips to yes if the test run's result is
  visible in the transcript.
- **Don't rely on the model's narration.** "I ran the tests and they pass" is not
  evidence; the command's exit code and summary are.
- **When the proof can't live in the transcript** (it needs a tool run, a fresh
  process, a browser), use a checker that *can* run tools — a **Stop hook** or a
  **sub-agent verifier** — instead of bare `/goal`.

## 3. Who checks: the maker–checker split

Match the strength of the checker to the stakes. From cheapest to strongest:

1. **Self-check, surfaced (low stakes).** The doer runs the check and shows the
   output; `/goal`'s separate evaluator reads it. Fine for objective, low-blast-
   radius conditions.
2. **TDD red→green (high reliability, code).** Write the failing test first; the
   loop implements until it goes green, then keeps the full suite green. Tests
   are objective — they pass or they don't. This is the most reliable verifier
   for code and the best default for "implement feature X."
3. **Separate sub-agent verifier (high stakes / long runs).** After the doer
   finishes a slice, spawn a *different* agent in its own context to review the
   changed files, run the full suite, check for regressions, and report. Unlike
   the `/goal` evaluator, a sub-agent **can run tools**. This is the standard for
   anything unattended and consequential — the writer and the grader are
   different agents.
4. **Stop hook (deterministic gate).** A script that fires when Claude tries to
   stop and checks the work directly (run the suite, grep for banned strings,
   confirm a build artifact). Use it for conditions that must be proven from
   *outside* the transcript, or that should apply to every session in scope.
   See [../scripts/stop-check.sh](../scripts/stop-check.sh).
5. **Screenshot / visual review (UI).** For anything user-facing, render the
   affected screens, review each, and only allow completion after a verified
   pass — e.g. require a `verified_` prefix on reviewed screenshots and one extra
   confirmation pass, so the loop can't claim done without the visual check.

## 4. Don't let the loop overfit its own metric

When the thing being improved is *also* judged by a metric it can game — a
prompt, a ranking, a policy, a heuristic — keep two things separate:

- the **working signal** you use to *choose* the next change (a working set of
  cases), and
- the **acceptance gate** you use to *accept* it (untouched holdout cases or a
  fresh check the change never saw).

Promote a change only if it beats the current best on the **holdout** without
weakening a must-pass check. Otherwise you'll climb your own training metric and
ship something that's worse in the wild. (This is why "improve the prompt until
the eval score is high" needs a held-out eval the optimizer can't see.)

## 5. Make every claim of "done" carry its receipt

When the loop reports DONE, it shows the command and the output that proves each
`done_when` — not a summary, the receipt. A verified loop ends like:

```
DONE — done_when met:
  - `npm test`      → 142 passed, 0 failed   (exit 0)
  - `npm run lint`  → 0 problems              (exit 0)
  - `rg "legacy-api" src/` → no matches
Changed: src/api/*.ts (8 files), src/index.ts. Checkpointed at <sha>.
Remaining: none. Next: open the PR for review.
```

If the receipt isn't there, the run isn't DONE — it's STALLED, EXHAUSTED, or
BLOCKED. Name it honestly (see SKILL.md Step 4).

## 6. The Gate, and 2026 stop-hook notes

Adopted from Superpowers' verification-before-completion — the Iron Law:
**no completion claims without fresh verification evidence.** The gate before
any claim of done/fixed/passing: **identify** the command that proves it →
**run** it fresh and in full → **read** the output and exit code → **verify**
it confirms the claim → only then claim, with the evidence pasted. "Should",
"probably", a previous run, or a subagent reporting "success" are not
evidence — the diff and the command output are.

Stop-hook practice: an **agent-type** Stop hook can run commands (tests, greps,
builds) before permitting a stop — the strongest checker for proof that lives
outside the transcript; a **prompt-type** hook judges the transcript only (like
`/goal`). Always set a hook `timeout`; respect `stop_hook_active` to avoid a
hook re-triggering itself; and remember the ~8-consecutive-block override
(`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`) — an override means STALLED, not done.
Worked JSON examples live in the owner skill's references/self-reprompting.md.
