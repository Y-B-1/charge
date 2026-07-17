---
name: finishing-a-development-branch
description: >-
  Use when implementation is complete and all tests pass, to integrate the
  work — verifies the suite, detects the workspace type, presents exactly four
  options (merge locally / push + PR / keep / discard), executes the choice,
  and cleans up worktrees safely. The exit ramp for executing-plans,
  subagent-driven-development, and a loop run's DONE state.
---

# Finishing a Development Branch

Verify tests → detect environment → present options → execute → clean up.
**Announce at start.**

## 1. Verify tests — the gate

Run the full suite. Failing → show failures, stop: "Cannot proceed with
merge/PR until tests pass." No options while red.

## 2. Detect environment

`GIT_DIR` vs `GIT_COMMON` (as in using-git-worktrees): normal repo or named-
branch worktree → 4 options; detached-HEAD worktree (externally managed) → 3
options (no local merge), no cleanup.

## 3. Base branch

`git merge-base HEAD main || git merge-base HEAD master` — or ask: "This split
from main, correct?"

## 4. Present exactly these options (no added explanation)

1. Merge back to `<base>` locally  2. Push and create a Pull Request
3. Keep the branch as-is  4. Discard this work

## 5. Execute

- **Merge:** checkout base → merge → run tests ON THE RESULT → push only if
  the human confirms.
- **PR:** push branch → `gh pr create` with a real summary → return the URL.
- **Keep:** report branch name and how to resume.
- **Discard:** require the human to type `discard` to confirm — never delete
  work on a plain "yes".

## 6. Cleanup (options 1 & 4 only)

Only remove worktrees YOU created under `.worktrees/`/`worktrees/`
(provenance); `cd` to the main repo root FIRST (removal fails silently from
inside); then `git worktree remove <path>` and `git worktree prune`.

## Never

Proceed with failing tests · merge without testing the result · delete without
typed confirmation · force-push unrequested · remove a worktree you didn't
create or before merge success is confirmed.
