---
name: using-git-worktrees
description: >-
  Use when starting feature work that needs isolation from the current
  workspace, or before executing an implementation plan — ensures an isolated
  workspace exists via the platform's native worktree tool first, manual git
  worktree as fallback, with ignore-verification and a clean test baseline.
---

# Using Git Worktrees

Detect existing isolation first → native tools → git fallback. Never fight the
harness. **Announce at start.**

## Step 0 — Detect

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
```
`GIT_DIR != GIT_COMMON` → already isolated (but first rule out a submodule:
`git rev-parse --show-superproject-working-tree` returns a path → submodule →
treat as normal repo). Already isolated → report path+branch, skip to Step 2.
Normal repo → honor any declared worktree preference; otherwise ask consent
("Set up an isolated worktree? It protects your current branch."). Declined →
work in place.

## Step 1 — Create

**1a. Native tool first** (a `/worktree` command, `EnterWorktree`,
`--worktree` flag…): if it exists, USE IT — `git worktree add` alongside a
native tool creates phantom state the harness can't manage. This is the #1
mistake.
**1b. Git fallback only if no native tool:** directory priority = explicit
user preference > existing `.worktrees/` > existing `worktrees/` > default
`.worktrees/`. **MUST verify ignored** before creating
(`git check-ignore -q .worktrees` — if not: add to .gitignore, commit). Then
`git worktree add "$LOCATION/$BRANCH" -b "$BRANCH"` — branch names
`claude/<feature>` per house rules.

## Step 2 — Setup + baseline

Auto-detect and run project setup (install deps, copy env templates). Then run
the test suite for a **clean baseline**: failures now are pre-existing —
report and get explicit permission before proceeding, or you can't tell new
bugs from old.

## Never

Create a worktree when Step 0 found isolation · use git fallback when a native
tool exists · skip the ignore check · skip the baseline · proceed on a failing
baseline without asking.
