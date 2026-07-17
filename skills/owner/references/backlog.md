# The backlog — the owner's product judgment, made auditable

`BACKLOG.md` is where founder thinking becomes executable work. Its two laws:

1. **Every item traces to a source** (SPEC.md §, RESEARCH.md line, or a user
   answer). No source, no item — it goes to *needs human* or *rejected*.
2. **An item without a mechanical `done_when` is not executable.** Tighten it
   using the goal skill's fuzzy→mechanical table, or bucket it. A loop pointed
   at a subjective item ("improve the UX") has no exit condition and burns the
   budget — decompose the ambition into checkable pieces first.

## Item schema (see ../assets/BACKLOG.template.md)

- **hypothesis** — "we believe <change> will <outcome> because <source>". This
  is the auditable why.
- **score = Impact (1–5) × Confidence (0–1) ÷ Effort (1–5)** — RICE-lite. Score
  honestly and conservatively; the point is defensible *ordering*, not
  precision. Ties break toward lower effort (ship learning sooner).
- **done_when + guards** — the mechanical check *and* what must not regress
  ("lint clean **and** tests still pass **and** no public behavior change").
- **evidence required** — what proof the item must produce (command output,
  contract test, before/after screenshot with end-to-end interaction).
- **gates** — flag now if completing it will need approval (deploy, send,
  delete, spend, schema/access change), so the run stages it instead of firing.

## Ceilings and buckets (scope discipline)

- **In-scope ceiling per run** — set at kickoff (default: 5–7 items, fewer for
  Stage 1). The run may *finish early*; it may not *expand* past the ceiling.
  New ideas mid-run go to a bucket for the next run.
- **New-surface-area ceiling** — cap how much of the run is *new* user-facing
  capability vs. improving what exists (default: at most 1 in 5 items). An
  owner that mostly invents features is drifting; most compounding value is in
  quality, reliability, performance, tests, and docs of what's already there.
- **needs human** — items requiring a product decision or missing access/tools.
- **rejected (with reason)** — so future fresh-context passes don't re-add the
  same tempting bad idea. This list is load-bearing.

## Sequencing

Default: score order within dependency order. Alternative when the project is
early and assumptions are shaky: **riskiest-assumption-first** — execute the
item that most cheaply tests whether the plan's biggest bet is true, so a wrong
direction dies in one item instead of seven.

## The red-team review (before anything executes)

Dispatch a **fresh-context reviewer** (subagent — never the author's context;
ideally a stronger model or the advisor) with SPEC.md, RESEARCH.md, and the
draft backlog, asking exactly:

1. Does every item trace to a real source, and does the source actually support
   the hypothesis?
2. Is every `done_when` mechanical, and do the guards protect the intent from
   letter-of-the-law gaming?
3. Is anything here scope creep, direction invention, or a worse use of the run
   than something in the buckets?
4. What's missing that the intent obviously implies (tests before refactors,
   migration guards, rollback paths)?

Apply the findings, record the review verdict in `LOOP-STATE.md`, then execute.
Repeat a lightweight version of this review at every re-alignment heartbeat.

## Re-scoring

At each heartbeat: mark done items with their evidence link, fold in what
execution taught (real effort vs. estimated, new findings), re-score and
re-order what remains, and promote from buckets **only** with a source. The
backlog is a living record of judgment — a human should be able to read it cold
and see exactly why the run did what it did, in what order.
