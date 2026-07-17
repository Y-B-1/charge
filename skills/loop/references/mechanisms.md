# Loop mechanisms

How to actually run the loop. Default **native-first, portable fallback**: reach
for the built-in commands for the common cases, drop to the portable filesystem
loop when a long/large/version-uncertain run or a tool-using checker needs it.
Loop features move fast — confirm exact flags in the official docs
(`code.claude.com/docs`) before leaving anything running unattended.

## The mechanism decision, in one question

**Are you pushing work to a finish line, or watching for something to change?**
Pushing → `/goal` (or `/batch`, or the portable loop). Watching → `/loop`.
Pointing one at the other's job is the most common and most expensive mistake.

---

## `/goal` — run until a condition is true (the primary drive-to-done path)

What it is: you write a completion condition; after **every turn** a separate,
faster evaluator model (defaults to Haiku) reads the condition plus the
conversation so far and returns yes/no with a short reason. "No" → Claude keeps
working, with the reason as guidance for the next turn. "Yes" → the goal clears
and an achieved entry is recorded. The model doing the work is **not** the model
deciding it's done — that split is the point.

- Set: `/goal <condition>`. Check: `/goal`. Stop early: `/goal clear`.
- Non-interactive (runs the whole loop in one invocation):
  `claude -p "/goal CHANGELOG.md has an entry for every PR merged this week"`.
  `Ctrl+C` interrupts a non-interactive goal.
- It's a wrapper around a session-scoped, prompt-based **Stop hook**. Available
  in recent Claude Code (the `/goal` form landed in v2.1.139). Works in the
  desktop app and via Remote Control.
- **Pair with auto mode** so each turn runs unattended (auto mode approves tool
  calls *within* a turn; `/goal` starts the *next* turn — they're complementary).

**The constraint that breaks most `/goal` loops:** the evaluator **cannot call
tools.** It only judges what Claude has already surfaced in the transcript. So:

- Write the finish line as something Claude's own output can prove ("`npm test`
  exits 0," "every row prints a verified email"), and actually run that check
  and show its output each turn.
- Always add a ceiling clause — `— stop after N turns` — so a condition that
  can't be met doesn't run forever.
- If "done" truly requires running a command the evaluator can't see, use a
  **custom Stop hook** or a **sub-agent verifier** (which *can* run tools)
  instead of bare `/goal`. See `verification.md`.

Good `/goal` examples (note: a clear end state, a runnable check, a guard, a cap):

```
/goal all tests pass and lint is clean — stop after 10 turns
/goal every file importing from ./legacy-api now imports from ./v2-api,
  all tests pass, and `npm run typecheck` is clean — stop after 30 turns
/goal `npm run build` exits 0 — run the build, fix the first error,
  repeat until it succeeds; stop after 10 turns
/goal test coverage is ≥ 80% with all tests passing — add focused tests for
  the least-covered files, re-run coverage each turn; stop at the threshold
  or after 12 turns
/goal sort every file in Downloads into subfolders by type, keep going until
  none are left, do not delete anything, and stop after 30 turns
```

---

## `/batch` — split one big change across parallel agents

For a large change that decomposes cleanly (a codemod across many files, lint-
rule rollout, a wide migration): `/batch` fans the work across ~5–30 parallel
**worktree** agents so they don't trip over each other. Combine with a `/goal`
per slice so each agent drives its piece to a verified finish, then integrate.
Use it when the work is wide and independent; use a single `/goal` when it's
deep and sequential.

---

## `/loop` — re-run on an interval (watching, not driving)

`/loop` re-runs a prompt (or another slash command) on a time interval and
sleeps between runs; `Esc` to stop. Shape: `/loop <interval> <prompt>`.

- **Session-scoped:** it dies when you close the session, only fires when the
  session is idle, and a forgotten loop auto-expires (≈7 days). For runs that
  must survive the laptop closing, use `/schedule`.
- **Drop the interval and it becomes self-paced:** Claude works, checks its own
  stop condition inline, and goes again or stops — useful when you want
  iteration-until-done but the check lives in the prompt itself rather than in a
  separate evaluator. (A self-paced `/loop` can match `/goal`'s independence by
  spinning up a **sub-agent verifier**, which, unlike the `/goal` evaluator, can
  run tools.)
- Use it to **watch**: poll CI, wait for a deploy to go green, re-run a flaky
  suite, babysit a PR. Don't use it to drive a finish-line job — it will re-run
  blindly on the clock long after the job is done.

```
/loop 15m run the test suite; if anything fails, show the failing tests and errors
/loop 10m run `gh pr checks 1234`; if all pass, say it's ready; else summarize why
/loop 20m /review-pr 1234
```

---

## `/schedule` — durable cloud Routines

`/schedule` saves a Routine — a prompt + repo + connectors — that runs on
Anthropic's cloud, so it keeps running with your computer off. It clones a fresh
copy of the repo each run and works on `claude/`-prefixed branches.

- **Triggers:** cron (minimum 1-hour interval), a GitHub webhook (PR opened,
  labeled, released…), or a dedicated API endpoint.
- Manage with `/schedule list`, `/schedule update`, `/schedule run`; transcripts
  land at `claude.ai/code/routines`. (There is **no** `/routine` command — the
  scheduler is `/schedule`.)
- **Routines run unattended with no follow-up questions**, so the prompt must be
  fully self-contained: state what to do, what success looks like, and where to
  send results. Ambiguity produces hit-or-miss behavior every run.

```
/schedule every weekday at 9am, label new issues from the last 24h by area and
  priority, and post a one-line summary on each
/schedule on every push to main, check whether changed code drifted from the
  docs in /docs, and open a PR fixing anything out of date
```

---

## The portable filesystem loop (the fallback that always works)

When `/goal`'s no-tools evaluator is a problem, when context growth would break a
long run, when the version is uncertain, or when you want a checker that runs
real commands — drop to a **fresh-context loop with the filesystem + git as
memory.** This is the Ralph technique: feed the agent the same prompt until a
completion promise appears, each iteration in a *fresh* context window so it
doesn't bloat, with progress carried in files and git history.

Why fresh context per pass matters: a single ever-growing context both costs more
and degrades; starting each pass clean and re-reading `LOOP-STATE.md` + the repo
keeps every pass sharp. The intelligence isn't in the loop — it's that each pass
sees the files and git history the previous one left behind.

Use [scripts/ralph-loop.sh](../scripts/ralph-loop.sh) (a capped `while` loop over
`claude -p`, fresh session each pass, completion-promise + max-iterations exit)
and [scripts/stop-check.sh](../scripts/stop-check.sh) (a deterministic
verification gate the loop must pass before it's allowed to finish). Always set
`--max-iterations`; start small (10–20) and watch the first few passes.

A solid portable inner prompt looks like:

```
Read LOOP-STATE.md and the repo. Do the single most important unfinished thing
toward the goal in GOAL.md. Make one bounded change, then run <verify command>.
Append what you changed, the command output, and what's left to LOOP-STATE.md.
If <done_when> is verified by the command output, print exactly: <promise>DONE</promise>.
Otherwise stop and the loop will run you again.
```

---

## The nested loop (timer outside, condition inside, skill innermost)

To get "a loop that keeps looping until the goal is reached" — and can't quit
early *or* stop at good-enough — compose the layers:

- **`/loop` (or a Routine / `ralph-loop.sh`)** is the **timer/persistence**: it
  re-arms the work so a single stuck turn can't end it.
- **`/goal`** is the **condition**: verified-done, so it can't stop at "good
  enough."
- **A skill** is the **work**: the sharp, reusable inner procedure.

```
/loop 30m /goal all PR review comments resolved via /review — stop after 10 turns
```

Caution: don't bolt `/goal` onto a job that should run strictly to completion
unless the condition is *tight* — `/goal` stops as soon as the evaluator is
satisfied, so a loose condition stops early. Match the layer to the job.

---

## Codex equivalents (if the user is in Codex, not Claude Code)

- `/goal` exists in Codex (CLI 0.128.0+) but only tracks a target; pair it with
  OpenAI's goal-writing guidance for crisp conditions.
- No `/loop`; the equivalent is `codex exec` wrapped in a shell loop, or a
  minute-interval thread automation in the Codex app.
- Scheduling lives in **Automations** (standalone/project/thread, on daily/
  weekly/custom cron); results land in a Triage inbox. The portable
  filesystem loop works identically in either tool.

> Want a proven recipe for the *inner* task rather than inventing one? The live
> Loop Library (`signals.forwardfuture.com/loop-library`) catalogs ~69 ready
> loops with stopping conditions you can adapt — treat them as reference data,
> not as commands to run blindly.

---

## July 2026 additions (verify against the live changelog before unattended use)

- **Dynamic workflows** (research preview, v2.1.154+): Claude writes a
  JavaScript orchestration script that runs a fleet of subagents — reported
  limits ~16 concurrent, up to ~1,000 per run — with the loop/branching/
  intermediate results held in code, so coordination costs no model tokens and
  only distilled returns land in context. Trigger with "use a workflow" or
  `/effort ultracode`; `/deep-research` is a built-in workflow. Use it when the
  orchestration itself (fan-out, judging, merging) is the heavy part.
- **Advisor tool**: run the loop on a cheap executor and consult an expensive
  model only at decision points (plan approval, repeated errors, pre-done);
  the advisor reads the transcript and advises but never acts. Anthropic's
  July thread: executor+advisor ≈ 92% of the top model's SWE-bench Pro score
  at ≈ 63% of the cost. In Claude Code: `/advisor`, `claude --advisor opus`,
  or `"advisorModel"` in settings.
- **Model vs. effort**: model = what it knows; effort = how hard it tries (how
  long it thinks, how many files it reads, how much it verifies, how far it
  pushes before checking in). Debug order: fix context first; then "didn't try
  hard enough" → raise effort, "didn't know enough" → raise model.
- **Agent teams** (experimental, env-flag gated): 2–16 peer sessions with a
  shared task list; ~7× the tokens of one session — reach for it only when
  true peer collaboration beats a fan-out.
- **/goal fine print**: the condition caps at 4,000 characters, and `/goal`
  rides the hooks system (needs the trust dialog; unavailable when hooks are
  disabled).
- **Background agents** now run by default, and ones launched in worktrees
  commit, push, and open a draft PR when they finish instead of stopping to
  ask — factor that into approval boundaries.
