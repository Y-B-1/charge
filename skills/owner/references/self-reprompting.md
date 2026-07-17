# Self-reprompting — how the run keeps going without you

The principle: **the stop is the prompt.** A model naturally halts at the end of
a turn; loop engineering intercepts that halt and turns it into the next
instruction. Everything here is a way of wiring "you tried to stop, but the
backlog isn't done — here's why, keep going" into the harness itself, so
continuing doesn't depend on the model's mood or the human's presence.

Pick **one** wiring at kickoff and state it in `LOOP-STATE.md`. Feature names
and flags below reflect mid-2026 Claude Code — verify against the live docs
(`code.claude.com/docs`, changelog) before an unattended run.

---

## Wiring A — `/goal` over the backlog (native, default)

Set a goal whose condition is the backlog's completion, pair it with **auto
mode** so turns run unattended, and optionally wrap it in `/loop` so a single
stuck turn can't end the run:

```
/goal Every in-scope item in BACKLOG.md is status:done with its stated
check's real output pasted into LOOP-STATE.md, the full test suite passes,
and no NEEDS-APPROVAL entry is pending — work the items top-down, one at a
time, re-reading SPEC.md/BACKLOG.md/LOOP-STATE.md each turn — stop after 40
turns.
```

How it re-prompts: after **every turn**, a separate fast evaluator model reads
the condition plus the transcript and answers yes/no with a reason; "no" — with
the reason — becomes the next turn's instruction. That reason is literally the
model prompting itself.

Constraints that make or break it:

- **The evaluator cannot run tools and only sees the transcript.** So every
  turn must *surface* the state it needs to judge: the count of unfinished
  items, the check's real output, the updated LOOP-STATE entry. A condition the
  transcript can't demonstrate never flips to yes.
- The condition caps at **4,000 characters** and `/goal` rides the hooks system
  (needs the trust dialog; unavailable when hooks are disabled).
- Always include the ceiling clause (`stop after N turns`) — it's the cap of
  last resort.
- Nested for persistence: `/loop 30m /goal <condition>` re-arms on a timer;
  `/schedule` moves the whole thing to a cloud Routine when the laptop closes.

## Wiring B — a Stop hook that refuses premature stops (strongest gate)

A Stop hook fires exactly when Claude tries to stop; returning "not done"
blocks the stop and injects the reason as the next prompt. Two flavors:

**Prompt-type** (an LLM judges a rubric — like `/goal`, transcript-only):

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Check BACKLOG.md status lines quoted in the transcript. If any in-scope item is not status:done with pasted evidence, respond {\"ok\": false, \"reason\": \"<name the top unfinished item and its next step>\"}. Otherwise {\"ok\": true}.",
        "timeout": 60
      }]
    }]
  }
}
```

**Agent-type** (a checker that **can run commands** — use this when proof lives
outside the transcript):

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "agent",
        "prompt": "Run `grep -c 'status: todo\\|status: doing' BACKLOG.md` and run the quick test command from GOAL.md. If the grep count is 0 AND tests exit 0, respond {\"ok\": true}. Otherwise respond {\"ok\": false, \"reason\": \"<unfinished count and/or failing test names>\"}.",
        "timeout": 300
      }]
    }]
  }
}
```

Operational rules learned the hard way:

- **Always set a hook `timeout`** — an unbounded hook chain has recursed into a
  multi-thousand-dollar overnight bill before; the postmortem lesson is depth
  and time limits on every hook.
- Claude Code **overrides a Stop hook after it blocks ~8 consecutive times
  without progress** (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` adjusts it). That's a
  feature: it's the built-in no-progress breaker. Treat an override as STALLED,
  not as done.
- Parse/respect `stop_hook_active` in hook input to avoid a hook re-triggering
  itself into a verification loop.

## Wiring C — the portable harness (fresh context per item; always works)

When native primitives aren't available, the run is very long, or you want
every pass sharp: feed
[../assets/OWNER-PROMPT.template.md](../assets/OWNER-PROMPT.template.md) to the
loop skill's `scripts/ralph-loop.sh`:

```
./ralph-loop.sh -p OWNER-PROMPT.md -n 40 -c OWNER-DONE \
  -v "./stop-check.sh -r 'npm test' -a 'status: todo:BACKLOG.md'"
```

Each pass is a **fresh context window**; all continuity lives in
SPEC/RESEARCH/BACKLOG/LOOP-STATE and git — which is why every pass starts by
re-reading them. The harness re-prompts mechanically: same prompt, new pass,
until the completion promise appears **and** the verify gate passes (the
promise alone is never trusted). Its built-in stall detector (no working-tree
change for 3 passes) is the portable no-progress breaker.

**Which wiring when:** A for interactive-machine runs on current Claude Code;
B layered on A when "done" needs command-level proof or you want the hardest
gate; C for very long runs, other agent CLIs, or when context growth/rot would
degrade a single session.

---

## Model & effort tiering — run hours affordably (the advisor pattern)

From Anthropic's July 2026 guidance, two dials govern a long run:

- **Model = what it knows; effort = how hard it tries.** Effort controls how
  long it thinks, how many files it reads, how much it verifies, and how far it
  pushes before checking in. Debug in this order: fix **context** first (skills,
  CLAUDE.md, the files on disk); then ask *"didn't try hard enough, or didn't
  know enough?"* — the first is an effort raise, the second a model raise.
- **The advisor pattern:** run the bulk of the loop on a cheap executor and
  consult an expensive advisor model **only at decision points** — plan
  approval, the same error twice, and pre-done acceptance. The advisor reads
  the transcript, advises, and does not act. Anthropic's published numbers:
  executor+advisor reached ~92% of the top model's SWE-bench Pro score at ~63%
  of its cost. In Claude Code: `/advisor`, `claude --advisor opus`, or
  `"advisorModel"` in settings.
- Route research and backlog extraction to **cheap worker subagents** (or a
  dynamic workflow) so raw pages and bulk reading never bill at the
  orchestrator's rate or pollute its context.

## Re-alignment — the anti-drift heartbeat

Every **3 completed items or 45 minutes**, whichever first:

1. Re-read `SPEC.md` in full. 2. Ask, in writing in `LOOP-STATE.md`: does the
work since the last heartbeat still serve the stated intent? Is the top of the
backlog still the highest-leverage item given what was learned? Any assumption
made that the user would want to veto? 3. Re-score/re-order the backlog;
promote anything from the buckets **only** if a source justifies it. 4. If
drift is found: fix the backlog *before* executing anything else, and record
what drifted and why.

The three drift signatures to check for by name: **silent drift** (tests pass,
wrong feature), **plan loss** (working, but not on any backlog item), and
**repeated surrender** (a hard step got a TODO/mock instead of a fix). Any of
them found twice in a row → STALLED, report honestly.
