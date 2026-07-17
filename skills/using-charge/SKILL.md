---
name: using-charge
description: >-
  Use when starting any conversation or task — establishes how to find and use
  the charge toolkit's skills, requiring skill invocation before ANY response
  or action, including clarifying questions and codebase exploration. It routes
  every intent to the right skill (owner, goal, loop, brainstorming,
  writing-plans, executing-plans, subagent-driven-development,
  systematic-debugging, test-driven-development, code review, verification,
  worktrees, finishing) and defines the workflow chains that connect them.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute one specific task, ignore this
skill and execute your brief.
</SUBAGENT-STOP>

# Using charge

charge is one toolkit with two halves that share a spine: an **autonomy suite**
(owner → goal → loop) that decides, contracts, and drives work to a verified
finish with self-reprompting, and a set of **discipline skills** (forked and
adapted from obra/superpowers, MIT) that govern how any piece of work is
designed, planned, executed, debugged, tested, reviewed, verified, and shipped.

<EXTREMELY-IMPORTANT>
If there is even a 1% chance a charge skill applies to what you are doing, you
MUST invoke it — before any response or action, including clarifying questions
or exploring the codebase. If it turns out to be wrong for the situation, you
may set it aside. You cannot rationalize your way out of checking.
</EXTREMELY-IMPORTANT>

Then announce — "Using charge:<skill> to <purpose>" — and follow the skill
exactly. If it has a checklist, create a todo per item.

## The routing table (intent → skill)

| The user's intent sounds like | Invoke |
| --- | --- |
| "Take charge / own this project / improve it on your own / keep working for hours" | **owner** (it will call goal + loop per item) |
| "Let's build X / add a feature / change behavior" (direction still open) | **brainstorming** → goal → writing-plans → execution |
| "Define done / spec this / write acceptance criteria" | **goal** |
| "Here's a spec — plan the implementation" | **writing-plans** |
| "Execute this plan" (independent tasks, this session, subagents available) | **subagent-driven-development** |
| "Execute this plan" (no subagents / batch with checkpoints) | **executing-plans** |
| "Keep going until X is true / run unattended / don't stop until done" | **loop** |
| "2+ independent failures or tasks at once" | **dispatching-parallel-agents** |
| Any bug, test failure, or unexpected behavior | **systematic-debugging** |
| Writing any production code or bugfix | **test-driven-development** |
| Task/feature complete, or before merge | **requesting-code-review** |
| Feedback arrived on your work | **receiving-code-review** |
| About to say "done", "fixed", "passing", or commit/PR | **verification-before-completion** |
| Starting feature work that needs isolation | **using-git-worktrees** |
| All tests pass; deciding merge/PR/keep/discard | **finishing-a-development-branch** |
| Machine/project setup, hooks, budget caps, pre-unattended checks, "is this skill safe to install" | **guardrails** |
| "Build an MCP server / wrap an API as agent tools" | **mcp-builder** |
| Catalog bloat, duplicate skills, description/token budget audit | **skill-audit** |
| "Create or edit a skill" | **writing-skills** |

## The workflow chains (how skills hand off)

**Feature chain (human-driven):**
brainstorming → (design approved) → goal (SPEC.md + GOAL.md contract) →
writing-plans (bite-sized tasks) → subagent-driven-development *or*
executing-plans → verification-before-completion →
finishing-a-development-branch. TDD and systematic-debugging apply inside every
execution step; requesting-code-review gates every task.

**Autonomy chain (Claude-driven):**
owner (kickoff interview → research → backlog) → per item: goal (contract) →
loop (self-reprompting execution with independent checker) → verification →
record in LOOP-STATE.md → next item, until a named terminal state. owner
absorbs brainstorming's job at kickoff; don't run both.

**Debug chain:** systematic-debugging (root cause first) →
test-driven-development (failing test reproduces bug) → fix →
verification-before-completion.

**Process skills come first** — they set the approach (brainstorming, owner,
systematic-debugging); implementation skills carry it out. When multiple
apply, invoke the process skill, which will call the others.

## House rules (apply across every skill)

1. **Evidence before claims, always** — the Iron Law. No "done/fixed/passing"
   without fresh verification output pasted. A subagent's success report is
   not evidence; the diff and command output are.
2. **Root cause before fixes; failing test before production code.**
3. **Isolation by default:** worktree or `claude/`-prefixed branch; never work
   on main without explicit consent; never push to main from automation.
4. **One question at a time,** and only questions whose answers change the
   plan; infer from the repo first. Interview once, then commit — don't drip
   questions into a run.
5. **Complete drop-in deliverables** — full files over diffs, exact paths,
   real code in plans, no placeholders ("TBD", "handle errors appropriately").
6. **Conservative, defensible estimates** — better to outperform than
   underdeliver; never invent numbers, sources, or stats.
7. **Cheapest capable model per role** — mechanical work on cheap models,
   judgment and final review on the most capable; always specify the model
   when dispatching (an omitted model silently inherits the most expensive).
8. **YAGNI ruthlessly.** No speculative features; grep for real usage before
   "implementing properly".
9. **Deterministic before probabilistic.** Anything that must NEVER happen
   gets a hook or permission rule (guardrails skill), not a sentence in a
   prompt — prompts shape behavior; hooks enforce it.

## Red flags — you're rationalizing (stop and check the table)

| Thought | Reality |
| --- | --- |
| "This is too simple for the process" | Simple work is where unexamined assumptions burn the most time. |
| "I need context first" | Skill check comes before exploration; skills tell you HOW to explore. |
| "I remember this skill" | Skills evolve. Read the current version. |
| "Just this once" | No exceptions without the human's permission. |
| "The skill is overkill" | If a skill exists, use it. |
| "It should work now" | Run the verification. |

## Precedence

The user's direct instructions and project instruction files (CLAUDE.md,
AGENTS.md) override skills; skills override default behavior. Skip a skill's
workflow only when the human has explicitly said to.
