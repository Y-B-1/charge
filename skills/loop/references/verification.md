# Verification — the part that makes a loop trustworthy

Boris Cherny's one rule: **always give the agent a way to verify its work** — it
raises quality roughly 2–3×. The corollary matters just as much: **the agent
that did the work must not be the only thing that decides it's done**, because
models are good at *looking* finished. The hard part of a task is exactly what a
model learns to route around, since that's where it might fail, and a confident
summary reads like success. Verification is how you stop it faking the finish.

## 1. The evidence rules (the state-file contract)

These hold for every loop, harness or native:

1. **A `passes` flip carries its receipt.** An agent sets a feature
   `passes:true` only with the verify command's real output pasted into
   `evidence` (and surfaced in its result). A flip without a receipt is
   tampering, not progress.
2. **DONE is confirmed, never claimed.** `SIGIL: DONE` is a claim; the harness
   accepts it only when `jq` shows zero `passes:false` in the state file AND
   the `-v` verify command exits 0 — with the output landing in the log/stream.
   A premature sigil just keeps the loop running.
3. **Narration is never evidence.** "I ran the tests and they pass" proves
   nothing; the command, its exit code, and its output do. "Should," a previous
   run, or a subagent reporting "success" are not evidence either.
4. **The log is narrative, not proof.** `loop-log.md` gives the next pass
   context; status lives in the state JSON alone, and even the JSON is gated by
   the harness's verify. Two layers: agents flip `passes`, the script checks.
5. **Premature stops are STALLED, not done.** A Stop-hook override after ~8
   consecutive blocks, an agent that quits without a sigil, an exhausted cap —
   none of these is DONE. Name the real state.

## 2. A stop condition the loop can't fake

A faking-proof `done_when` has all three:

- **Objective** — a command, exit code, count, or diff with a yes/no answer and
  no interpretation. "`pytest -q` exits 0," not "tests look good."
- **Complete** — it pins down the *intent*, not a proxy. "Lint passes **and**
  tests still pass **and** no files deleted outside `src/`," not "lint passes"
  (which the model can satisfy by deleting the linted code).
- **Visible** — its result actually appears where the checker can read it: the
  harness log/result stream, or the transcript for `/goal`. A condition the
  checker can't observe never flips to yes.

If you can't make a condition objective, the task isn't ready for autonomous
execution — narrow the scope until some part *is* checkable, loop that part,
and hand the subjective remainder back to the human.

## 3. The native constraint: the `/goal` evaluator can't run tools

The `/goal` evaluator reads the **transcript** and **cannot call tools**. So:

- **Run the check inside the loop and surface its output** each turn — a goal
  of "the tests pass" only flips if the run's result is visible in the
  transcript.
- **When the proof can't live in the transcript** (it needs a tool run, a fresh
  process, a browser), use a checker that *can* run tools — a Stop hook, a
  sub-agent verifier, or the harness, whose verify command is a real command
  with a real exit code.

## 4. Who checks: the maker–checker split

Match the checker to the stakes. From cheapest to strongest:

1. **Self-check, surfaced (low stakes).** The doer runs the check and shows the
   output; a separate evaluator reads it.
2. **The harness verify gate (the default).** A deterministic command
   (`stop-check.sh`, or any script that exits 0 only when done) run by the
   outer script — never model-judged, immune to a confident summary, and the
   same gate that feeds failure-signature stall detection.
3. **TDD red→green (high reliability, code).** Write the failing test first;
   implement until green, then keep the full suite green. Tests pass or they
   don't — the best default for "implement feature X."
4. **Separate sub-agent verifier (high stakes / long runs).** A *different*
   agent in its own context reviews the changed files, runs the full suite, and
   reports. The writer and the grader are different agents.
5. **Stop hook (deterministic gate on stopping).** A script that fires when
   Claude tries to stop and checks the work directly. Use for proof that lives
   outside the transcript, or that should apply to every session in scope. See
   [../scripts/stop-check.sh](../scripts/stop-check.sh).
6. **Screenshot / visual review (UI).** Render the affected screens, review
   each, and require a verified pass (e.g. a `verified_` prefix on reviewed
   screenshots) before completion.

## 5. Don't let the loop overfit its own metric

When the thing being improved is *also* judged by a metric it can game — a
prompt, a ranking, a policy, a heuristic — keep two things separate: the
**working signal** used to *choose* the next change, and the **acceptance
gate** used to *accept* it (untouched holdout cases or a fresh check the change
never saw). Promote a change only if it beats the current best on the holdout
without weakening a must-pass check. Otherwise you climb your own training
metric and ship something worse in the wild.

## 6. Every claim of done carries its receipt

A verified run ends with the receipts in the result stream, not a summary:

```
SIGIL: DONE
done_when receipts:
  - `npm test`      → 142 passed, 0 failed   (exit 0)
  - `npm run lint`  → 0 problems             (exit 0)
  - `rg "legacy-api" src/` → no matches
features: 6/6 passes:true (evidence in loop-state.json)
Changed: src/api/*.ts (8 files), src/index.ts. Checkpointed at <sha>.
Remaining: none. Next: open the PR for review.
```

The harness then re-checks anyway (jq + verify) — belt and suspenders, because
the sigil is a claim. If the receipt isn't there, the run isn't DONE — it's
STALLED, EXHAUSTED, or BLOCKED. Name it honestly (SKILL.md, terminal states).

## 7. The Gate, and 2026 stop-hook notes

The Iron Law (from Superpowers' verification-before-completion): **no
completion claims without fresh verification evidence.** Before any claim of
done/fixed/passing: **identify** the command that proves it → **run** it fresh
and in full → **read** the output and exit code → **verify** it confirms the
claim → only then claim, with the evidence pasted.

Stop-hook practice: an **agent-type** Stop hook can run commands (tests, greps,
builds) before permitting a stop — the strongest in-session checker for proof
outside the transcript; a **prompt-type** hook judges the transcript only (like
`/goal`). Always set a hook `timeout`; respect `stop_hook_active` to avoid a
hook re-triggering itself; and remember the ~8-consecutive-block override
(`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`) — an override means STALLED, not done.
Worked JSON examples live in the owner skill's references/self-reprompting.md.
