---
name: subagent-driven-development
description: >-
  Use when executing an implementation plan with mostly independent tasks and
  subagents are available — the complete execution ritual from isolated
  workspace to integrated branch. Establishes worktree isolation (native tool
  first, git fallback, never both) and a clean test baseline at entry (red
  baseline stops for permission), dispatches a fresh implementer subagent per
  task — independent tasks batched in ONE message — gates every task on a
  machine-checkable JSON review verdict, conflict-checks parallel work and
  runs the full suite after integration, sends the whole branch to the
  vendored code-review skill, then finishes with exactly four options: merge
  locally / push + PR / keep / discard. Also the route for "run this plan
  with subagents", "parallelize these tasks", "set up a worktree", and
  "finish this branch".
disable-model-invocation: true
---

# Subagent-Driven Development

Workspace → baseline → per-task implement/review loop → integration checks →
whole-branch review → finishing ritual. Subagents never inherit your session
history — you construct exactly what each needs; that keeps them focused and
preserves your context for coordination. Narrate at most one short line
between dispatches; the ledger and tool results carry the record.

**Continuous execution:** never pause between tasks to check in. Stop only
for a red baseline, BLOCKED-you-can't-resolve, genuine ambiguity, or
all-tasks-complete.

## 1. Workspace — isolation substrate

Detect first → native tool → git fallback. Never both — `git worktree add`
alongside a native worktree tool creates phantom state the harness can't
manage; this is the #1 mistake.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
```

- `GIT_DIR != GIT_COMMON` → already isolated — but first rule out a
  submodule (`git rev-parse --show-superproject-working-tree` prints a path
  → submodule → treat as a normal repo). Already isolated → report path +
  branch, go to baseline.
- **Native tool first** (a `/worktree` command, `EnterWorktree`, a
  `--worktree` flag…): if one exists, use it. Full stop.
- **Git fallback** only when no native tool exists. Directory priority:
  explicit user preference > existing `.worktrees/` > existing `worktrees/`
  > default `.worktrees/`. Verify the location is ignored BEFORE creating
  (`git check-ignore -q .worktrees`; not ignored → add to .gitignore,
  commit). Then `git worktree add "$LOCATION/$BRANCH" -b "$BRANCH"`, branch
  named `claude/<feature>`.
- Normal repo, no declared worktree preference → ask: "Set up an isolated
  worktree? It protects your current branch." Declined → work in place.

Run project setup (install deps, copy env templates) before the baseline.

## 2. Baseline — the entry gate

Run the full test suite before Task 1. Failures now are pre-existing: report
them and STOP for explicit permission before any task work. Without a clean
baseline, new failures are indistinguishable from old and every review gate
downstream loses its meaning.

## 3. Per-task loop

Read the plan; note Global Constraints; create the todo ledger. Pre-flight
scan once: tasks contradicting each other or the constraints, or anything
the plan mandates that the review rubric treats as a defect — batch ALL
findings into one question before Task 1, not one interrupt each mid-run.
Clean scan → proceed silently.

For each task:

1. **Brief:** `scripts/task-brief PLAN_FILE N` extracts the task text to the
   workspace; record `BASE=$(git rev-parse HEAD)`.
2. **Implement:** dispatch an implementer from
   [implementer-prompt.md](implementer-prompt.md) (brief file, context,
   invitation to ask questions first). It implements with TDD, tests,
   commits, self-reviews, writes a report file.
3. **Escalation is success behavior:** BLOCKED and NEEDS_CONTEXT are
   first-class returns — bad work is worse than no work. Respond with more
   context, a more capable model, or a smaller task split; never pressure a
   subagent to push through uncertainty.
4. **Review gate:** `scripts/review-package BASE HEAD` writes the diff
   package (it never enters your context); dispatch a reviewer from
   [task-reviewer-prompt.md](task-reviewer-prompt.md). The reviewer writes a
   JSON verdict file; `scripts/verdict-check VERDICT_FILE` is the gate —
   exit 0 passes, exit 1 fails, exit 2 malformed. Malformed is a reviewer
   failure: re-dispatch the reviewer; never treat it as a pass.
5. **Fail → fix cycle:** dispatch a fix subagent with the verdict's findings
   and the prose report path → new review package over the fix range →
   re-review → `verdict-check` again. The ledger flips only on exit 0.
   `cannot_verify` entries are yours: check each yourself or carry it to the
   whole-branch review — never silently drop one.

## 4. Parallel dispatch

Truly independent tasks — no shared state, no sequential dependency,
disjoint files — may run concurrently: dispatch them ALL in ONE message.
Batching is a deliberate concurrency ceiling, and it forces the scope check
that keeps two agents out of the same code: each dispatch carries a specific
scope, a clear goal, the relevant Global Constraints, and an expected
output. Related failures → one agent investigates all. Shared state →
sequential. Every parallel task still gets its own review gate.

## 5. Integration checks — after parallel work

1. **Conflict check:** compare the tasks' diff stats — same file or same
   code touched by two agents → inspect and reconcile before anything else.
2. **Full suite, run by YOU:** a subagent reporting "success" is not
   evidence; agents make systematic errors. Read each diff, run the entire
   suite yourself, then mark the ledger.

## 6. Whole-branch review

The vendored code-review skill (../code-review/SKILL.md) is the final
review: two axes (Standards, Spec) over the branch's base as the fixed
point. Use it as written — no homegrown whole-branch rubric.

## 7. Finishing — the end ritual

Verify → detect → present → execute → clean up.

1. **Verify:** run the full suite again. Failing → show failures, stop. No
   options while red.
2. **Detect:** `GIT_DIR` vs `GIT_COMMON` (step 1): normal repo or
   named-branch worktree → four options; detached-HEAD worktree (externally
   managed) → three (no local merge), no cleanup.
3. **Base branch:** `git merge-base HEAD main || git merge-base HEAD master`
   — or ask: "This split from main, correct?"
4. **Present exactly these options (no added explanation):**
   1. Merge back to `<base>` locally  2. Push and create a Pull Request
   3. Keep the branch as-is  4. Discard this work
5. **Execute:** Merge → checkout base, merge, run tests ON THE RESULT, push
   only if the human confirms. PR → push, `gh pr create` with a real
   summary, return the URL. Keep → report branch name and how to resume.
   Discard → require the human to type `discard` — never delete work on a
   plain "yes".
6. **Cleanup (options 1 & 4 only):** only remove worktrees YOU created
   under `.worktrees/`/`worktrees/`; `cd` to the main repo root FIRST
   (removal fails silently from inside); `git worktree remove <path>`, then
   `git worktree prune`.

## Model selection (specify explicitly on EVERY dispatch)

An omitted model silently inherits your session's — usually the most
expensive. Turn count beats token price: the cheapest models take 2–3× the
turns on multi-step work, so use mid-tier as the floor for reviewers and for
implementers working from prose.

| Task | Model |
| --- | --- |
| Plan text contains the complete code (transcription + testing); single-file mechanical fix | cheapest tier |
| 1–2 files, complete spec | cheap |
| Multi-file integration, pattern matching, debugging | standard |
| Design judgment, broad codebase understanding | most capable |
| Reviews | scale to the diff's size and risk |

## Never

Create a worktree when detection found isolation · git fallback when a
native tool exists · skip the ignore check · proceed on a red baseline
without permission · dispatch related failures separately · let agents share
mutable state · skip the full-suite run because every agent reported green ·
mark a task done without `verdict-check` exit 0 · merge without testing the
result · delete without typed confirmation · force-push unrequested · remove
a worktree you didn't create.
