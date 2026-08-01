# Self-reprompting — how the run keeps going without you

The principle: **the stop is the prompt.** A model naturally halts at the end of
a turn; loop engineering intercepts that halt and turns it into the next
instruction. Everything here is a way of wiring "you tried to stop, but the
backlog isn't done — here's why, keep going" into the harness itself, so
continuing doesn't depend on the model's mood or the human's presence.

Pick **one** wiring at kickoff and state it in `LOOP-STATE.md`. Feature names
and flags reflect mid-2026 Claude Code — verify against the live docs
(`code.claude.com/docs`, changelog) before an unattended run.

---

## Wiring A — the fresh-context harness (default)

Feed [../assets/OWNER-PROMPT.template.md](../assets/OWNER-PROMPT.template.md)
to the loop skill's harness (`scripts/ralph-loop.sh`), with a verifier that
gates the completion promise on the JSON backlog:

```
./ralph-loop.sh -p OWNER-PROMPT.md -n 40 -c OWNER-DONE \
  -v "jq -e '[.items[] | select(.passes == false)] | length == 0' BACKLOG.json && npm test"
```

Each pass is a **fresh context window**; all continuity lives in
SPEC/RESEARCH/BACKLOG.json/LOOP-STATE and git — which is why every pass starts
by re-reading them. The harness re-prompts mechanically: same prompt, new pass,
until the completion sigil appears **and** the verify gate passes (the promise
alone is never trusted). This is the default because in-session looping
accumulates context — the process restart is the load-bearing detail that
keeps every pass sharp, and the harness (not the agent) detects EXHAUSTED
(iteration cap) and STALLED (empty diffs / identical failure signatures /
per-item attempt counters), so those states can't be dressed up as DONE.

## Wiring B — `/goal` over the backlog (native, secondary)

For runs you are **watching** on an interactive machine: set a goal whose
condition is the backlog's completion, and optionally wrap it in `/loop` so a
single stuck turn can't end the run:

```
/goal BACKLOG.json contains zero items with "passes": false — shown by
pasting the jq count into the transcript — every flip is accompanied by its
check's real output, the run-level acceptance commands pass, and no
NEEDS-APPROVAL entry is pending. Work items top-down, one at a time,
re-reading SPEC.md/BACKLOG.json/LOOP-STATE.md each turn — stop after 40 turns.
```

How it re-prompts: after **every turn**, a separate fast evaluator model reads
the condition plus the transcript and answers yes/no with a reason; "no" — with
the reason — becomes the next turn's instruction.

Constraints that make or break it:

- **The evaluator cannot run tools and only sees the transcript.** So every
  turn must *surface* the state it needs to judge: the jq count of unfinished
  items, the check's real output, the updated LOOP-STATE entry. A condition the
  transcript can't demonstrate never flips to yes.
- The condition caps at **4,000 characters** and `/goal` rides the hooks system
  (needs the trust dialog; unavailable when hooks are disabled).
- Always include the ceiling clause (`stop after N turns`) — the cap of last
  resort.
- Nested for persistence: `/loop 30m /goal <condition>` re-arms on a timer;
  `/schedule` moves the whole thing to a cloud Routine when the laptop closes.

**Push vs. watch:** the harness (A) when the run is unattended or long — it
pushes state to disk and survives restarts; `/goal` (B) when you're watching
and want native ergonomics. Layer C below on B when "done" needs command-level
proof.

## Wiring C — a Stop hook that refuses premature stops (layered gate)

A Stop hook fires exactly when Claude tries to stop; returning "not done"
blocks the stop and injects the reason as the next prompt. Two flavors:

**Prompt-type** (an LLM judges a rubric — like `/goal`, transcript-only):

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Check the BACKLOG.json state quoted in the transcript. If any item has \"passes\": false without a NEEDS-APPROVAL or blocked note, respond {\"ok\": false, \"reason\": \"<name the top unfinished item and its next step>\"}. Otherwise {\"ok\": true}.",
        "timeout": 60
      }]
    }]
  }
}
```

**Agent-type** (a checker that **can run commands** — use when proof lives
outside the transcript):

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "agent",
        "prompt": "Run `jq '[.items[] | select(.passes == false)] | length' BACKLOG.json` and the run-level acceptance commands from BACKLOG.json. If the count is 0 AND acceptance exits 0, respond {\"ok\": true}. Otherwise respond {\"ok\": false, \"reason\": \"<unfinished count and/or failing check names>\"}.",
        "timeout": 300
      }]
    }]
  }
}
```

Operational rules:

- **Set an explicit `timeout` on every hook entry** rather than relying on
  defaults (600 s for command hooks, 30 s prompt, 60 s agent). Prompt and
  agent hooks are LLM calls billed per fire — an agent hook can run up to 50
  turns — so the timeout is a cost bound, not just a hang bound. Full hygiene:
  the guardrails skill's hook-hygiene section.
- Claude Code **overrides a Stop hook after ~8 consecutive blocks without
  progress** (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` adjusts it). That's the
  built-in recursion-depth bound — it caps how many times the gate fires,
  while the timeout caps what each firing costs. Treat an override as
  STALLED, never as done.
- Parse/respect `stop_hook_active` in hook input to avoid a hook re-triggering
  itself into a verification loop.

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
- Route research and backlog extraction to **cheap worker subagents** so raw
  pages and bulk reading never bill at the orchestrator's rate or pollute its
  context.

---

## The audit pass — the anti-drift heartbeat

Re-reading SPEC.md at the top of every pass is the standing session ritual: it
picks the next task. It never audits the *accumulated completed work* against
intent — that is what drifts. So, on a **pass-count cadence**: every N
completed implementation passes (N from BACKLOG.json's run config, default 3,
counted in LOOP-STATE.md), **the next fresh-context iteration runs as a
dedicated audit pass instead of an implementation pass.** No wall-clock
trigger — clocks have no meaning across process restarts.

The audit pass, in order, all findings in writing:

1. Re-read `SPEC.md` in full.
2. Check the work completed since the last audit for the three drift
   signatures by name: **silent drift** (tests pass, wrong feature), **plan
   loss** (working, but not on any backlog item), and **repeated surrender**
   (a hard step got a TODO/mock instead of a fix).
3. Re-score and re-order the remaining items; promote from `needs_human` /
   `rejected` **only** if provenance justifies it; review `rejected[]` entries
   whose `review_after` condition has passed — re-arm them with a fresh reason
   or move them to `needs_human` (a stale rejection is context poisoning).
4. Record: findings and any drift verdict in `LOOP-STATE.md`; score/order and
   bucket changes in `BACKLOG.json`; reset the audit counter. If drift was
   found, fix the backlog *before* any further execution.

**Escalation is the harness's existing breaker, not a new one:** the audit
writes its drift verdict to the loop-state file; the same signature found by
two consecutive audits counts as no progress, and the run exits **STALLED**
with the repeating obstacle named. Do not build a second, session-internal
circuit breaker.
