# Loop mechanisms

The default is **the fresh-context harness** (`scripts/ralph-loop.sh`). The
native commands cover two specific shapes — a short attended push (`/goal`) and
a watch (`/loop`) — plus fan-out (`/batch`) and scheduling (`/schedule`). Loop
features move fast — confirm exact flags in the official docs
(`code.claude.com/docs`) before leaving anything running unattended.

## The selection rule, in one question

**Are you pushing work to a finish line, or watching for something to change?**
Pushing → the harness (default), or `/goal` for a short attended run. Watching
→ `/loop`. Pointing one at the other's job is the most common and most
expensive mistake: `/goal` on an external wait spins (the thing isn't Claude's
to move); `/loop` on a finish-line job re-runs blindly after done.

---

## 1. The fresh-context harness (the default)

Feed the agent the same prompt repeatedly, **each pass a fresh process** — a
new context window — with the filesystem + git as memory. Process restart is
the load-bearing detail: in-session looping accumulates context and degrades;
a fresh pass re-reads the state file, the log, and the repo, and stays sharp.
The intelligence is in the files the previous pass left behind.

The harness's per-pass sequence (all deterministic, all script-side):

1. **Pre-pass done check** — zero `passes:false` in the state JSON + verify
   command exits 0 → DONE without paying for another pass.
2. **Feature pick accounting** — the first `passes:false`, non-`blocked`
   feature (the same rule the prompt gives the agent) gets its `attempts`
   counter incremented.
3. **Agent pass** — the prompt piped into a brand-new agent process; output
   captured and tee'd to the log.
4. **Empty-diff detection** — a change signature (HEAD + status + diff,
   excluding the state/log files, plus the features' `passes` values) compared
   against the last pass. Identical = an empty pass.
5. **Attempt-cap blocking** — a feature at `-A` attempts, still failing, with
   an empty diff → `blocked:true` with a reason; it is skipped, not re-picked,
   so one stuck feature can't eat the whole cap. All remaining features
   blocked → BLOCKED.
6. **Sigil parse** — the result stream (stream-json extracted via
   `jq 'select(.type=="result")'`, plain output as-is) is grepped for the
   agent's sigil; see the taxonomy below.
7. **Verify + failure signatures** — the `-v` command runs; on failure its
   output is hashed, and the agent's result text is hashed too (an agent
   emitting the identical result every pass — same error, same refusal — is
   spinning even if git churns). `-N` identical hashes in a row on either
   signal → STALLED.
8. **Persist** — streaks, signatures, and iteration are written into
   `harness.*` in the state file, so a restarted harness resumes rather than
   restarts.

State contract: **agents flip `features[].passes` (with `evidence`) and
nothing else.** `attempts`, `blocked`, and `harness.*` are script-written;
`loop-log.md` is narrative, never authority. Invocation and flags are in the
script header; the prompt skeleton is in `../assets/RECIPES.md`.

Reach for the harness whenever the run is long, unattended, context-heavy,
version-uncertain, or the check needs to run tools. It is fully portable: pass
any agent CLI after `--` (e.g. `-- codex exec`).

---

## 2. The circuit breakers + terminal-state taxonomy

Every loop exit — harness, `/goal`, Stop hook — lands on exactly one of five
states, and **never dresses one as another**:

| State | Exit | Detected by | Meaning |
| --- | --- | --- | --- |
| DONE | 0 | harness confirms the agent's claim | zero `passes:false` (checked via jq) AND verify exits 0, output surfaced |
| STALLED | 3 | harness streaks, or agent report | no measurable progress — the repeating obstacle named |
| EXHAUSTED | 4 | harness only | the iteration cap hit before done — the agent cannot observe its own cap |
| BLOCKED | 5 | agent sigil, or every feature attempt-capped | a decision, access, or tool is missing — named precisely |
| NEEDS-APPROVAL | 6 | agent sigil | a gated action staged and described, never executed — the human fires it |

Detection responsibility is split on purpose: **DONE, BLOCKED, NEEDS-APPROVAL,
and the STALLED candidate are agent-emitted sigils; EXHAUSTED and confirmed
STALLED are harness-detected.** A sigil is a claim; the harness's jq + verify
check is the verdict.

Three distinct breakers, three different problems:

- **The stall breaker (nothing is changing).** `-N` consecutive empty-diff
  passes, identical verify-failure signatures, or identical agent result
  outputs → STALLED. This is the cheap
  third exit between "sigil" and "cap": without it a spinning loop burns every
  remaining capped iteration re-hitting the same wall. Detection is a hash
  comparison in the script — never a model judgement.
- **The attempt-cap breaker (one feature is stuck).** A feature attempted `-A`
  passes with `passes` still false and no diff is marked `blocked` and
  skipped — preventing the same-first-step-forever failure without killing the
  whole run.
- **The consecutive-failure breaker (things are actively breaking).** Each fix
  adding a new regression is not a stall — it's a hole being dug. Roll back to
  the last good git checkpoint, stop, report. The rollback runs inside the
  same isolation as the loop.

Related facts: a Stop-hook override after ~8 consecutive blocks
(`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`) is STALLED, never done. An EXHAUSTED or
STALLED run reported as DONE is the premature-completion failure this
vocabulary exists to prevent — the two are indistinguishable without it.

---

## 3. `/goal` — native push (short, attended runs)

You write a completion condition; after **every turn** a separate, faster
evaluator model (defaults to Haiku) reads the condition plus the conversation
and returns yes/no with a reason. "No" → Claude keeps working with the reason
as guidance; "Yes" → the goal clears. The doer is not the judge — that split is
the point.

- Set: `/goal <condition>`. Check: `/goal`. Stop early: `/goal clear`.
- Non-interactive: `claude -p "/goal <condition>"`; `Ctrl+C` interrupts.
- It's a wrapper around a session-scoped, prompt-based Stop hook (the `/goal`
  form landed in v2.1.139). Pair with auto mode so turns run unattended.

**The constraint that breaks most `/goal` loops: the evaluator cannot call
tools.** It judges only what's already surfaced in the transcript. So: run the
check each turn and show its real output; always add `— stop after N turns`;
and when the proof needs a tool run, use a Stop hook or sub-agent verifier —
or the harness, whose checker is a real command. Prefer the harness over
`/goal` for anything long, unattended, or context-heavy: `/goal` turns share
one growing session.

Good conditions (clear end state, runnable check, guard, cap):

```
/goal all tests pass and lint is clean — stop after 10 turns
/goal every file importing from ./legacy-api now imports from ./v2-api,
  all tests pass, and `npm run typecheck` is clean — stop after 30 turns
/goal test coverage ≥ 80% with all tests passing and no test deleted or
  skipped — stop at the threshold or after 12 turns
```

---

## 4. `/loop` — native watch (polling, not driving)

`/loop <interval> <prompt>` re-runs a prompt (or slash command) on a time
interval, sleeping between runs; `Esc` to stop.

- **Session-scoped:** dies with the session, fires only when idle, auto-expires
  (≈7 days). Runs that must survive the laptop closing → `/schedule`.
- **Drop the interval and it self-paces:** the check lives in the prompt
  itself. A self-paced `/loop` can match `/goal`'s independence by spinning up
  a sub-agent verifier (which, unlike the `/goal` evaluator, can run tools).
- Use it to **watch**: poll CI, wait for a deploy, re-run a flaky suite,
  babysit a PR.

```
/loop 15m run the test suite; if anything fails, show the failing tests and errors
/loop 10m run `gh pr checks 1234`; if all pass, say it's ready; else summarize why
```

---

## 5. `/batch` — split one big change across parallel agents

For a large change that decomposes cleanly (codemod, lint rollout, wide
migration): `/batch` fans the work across ~5–30 parallel worktree agents.
Combine with a `/goal` per slice, or run the harness per slice; integrate
after. Wide and independent → `/batch`; deep and sequential → one loop. When
the orchestration itself is the heavy part (fan-out, judging, merging), a
dynamic workflow runs the fleet from code — see §9.

---

## 6. `/schedule` — durable cloud Routines

`/schedule` saves a Routine — prompt + repo + connectors — that runs on
Anthropic's cloud with your computer off, cloning fresh and working on
`claude/`-prefixed branches.

- **Triggers:** cron (min 1-hour interval), a GitHub webhook, or an API
  endpoint. Manage with `/schedule list|update|run`; transcripts at
  `claude.ai/code/routines`. (There is no `/routine` command.)
- **Routines run with no follow-up questions** — the prompt must be fully
  self-contained: what to do, what success looks like, where results go.

---

## 7. The nested shape

Timer outside, condition inside, skill innermost: `/loop` (or a Routine, or
the harness) re-arms the work so a stuck turn can't end it; a verified-done
condition stops it from settling for good-enough; a sharp skill does the work.
The harness embeds the first two natively (the `for` loop is the timer; the
state-file + verify gate is the condition). If you bolt `/goal` onto a
run-to-completion job, keep the condition tight — it stops the moment the
evaluator is satisfied.

```
/loop 30m /goal all PR review comments resolved via /review — stop after 10 turns
```

---

## 8. Codex equivalents

- `/goal` exists in Codex (CLI 0.128.0+) but only tracks a target.
- No `/loop`; wrap `codex exec` in a shell loop — or run the harness with
  `-- codex exec`, which works identically.
- Scheduling lives in **Automations** (daily/weekly/custom cron); results land
  in a Triage inbox.

> Want a proven recipe for the *inner* task? The live Loop Library
> (`signals.forwardfuture.com/loop-library`) catalogs ~69 ready loops with
> stopping conditions — reference data, not commands to run blindly.

---

## 9. July 2026 additions (verify against the live changelog before unattended use)

- **Dynamic workflows** (research preview, v2.1.154+): Claude writes a
  JavaScript orchestration script that runs a fleet of subagents (~16
  concurrent, up to ~1,000 per run) with loop/branching/intermediate results
  held in code — coordination costs no model tokens. Trigger with "use a
  workflow" or `/effort ultracode`.
- **Advisor tool**: run the loop on a cheap executor and consult an expensive
  model only at decision points (plan approval, repeated errors, pre-done).
  Anthropic's July thread: executor+advisor ≈ 92% of the top model's SWE-bench
  Pro score at ≈ 63% of the cost. `/advisor`, `claude --advisor opus`, or
  `"advisorModel"` in settings.
- **Model vs. effort**: model = what it knows; effort = how hard it tries.
  Debug order: fix context first; "didn't try hard enough" → raise effort,
  "didn't know enough" → raise model.
- **Agent teams** (experimental, env-flag gated): 2–16 peer sessions, ~7× the
  tokens of one session — only when true peer collaboration beats a fan-out.
- **/goal fine print**: the condition caps at 4,000 characters; `/goal` rides
  the hooks system (needs the trust dialog; unavailable when hooks are
  disabled).
- **Background agents** run by default, and ones launched in worktrees commit,
  push, and open a draft PR when they finish instead of stopping to ask —
  factor that into approval boundaries.
