<!-- Project instruction file. Target 40-80 lines, hard cap 200.
     Every line must be undiscoverable from the repo AND relevant in most
     sessions. HTML comments are stripped before injection, so maintainer
     notes like this one cost nothing. Delete the sections you do not earn. -->

# <PROJECT-NAME>

<ONE SENTENCE: what this is and who uses it.>

## Commands

<!-- Only non-obvious or non-standard commands. If the command is discoverable
     from package.json / Makefile in one read, delete the line. -->

- Install: `<COMMAND>`
- Test: `<COMMAND>`
- Typecheck: `<COMMAND>`
- Lint: `<COMMAND>`
- Run locally: `<COMMAND>`

Package manager: `<NAME>` — <REASON IT IS NOT THE DEFAULT>.

## Verification

<!-- WHICH TIER RUNS WHERE. The commands are discoverable; their placement is
     not. The policy below is the STANDING DEFAULT — change the commands,
     ports and durations, not the policy. These lines are not deletable.
     Deviating requires the user's explicit words, recorded under
     "Deviation from the standing default" at the end of this section. -->

The escape boundary is the merge where code reaches `<PROTECTED-BRANCH>`.
Everything below it is scoped; the full suite runs there and nowhere else.

| When | What runs | Where |
|---|---|---|
| Every edit | `<FAST-CHECK COMMANDS: types, lint, unit>` | whole repo |
| Every work unit inside a branch (`<WORK-UNIT: task/wave/subagent>`) | scoped `<INTEGRATION/E2E COMMAND>` — exactly the features that changed, never the full suite | `<ISOLATED PORT/ENV>` |
| Every PR that does NOT reach `<PROTECTED-BRANCH>` | scoped only, same rule as above | `<ISOLATED PORT/ENV>` |
| The merge that reaches `<PROTECTED-BRANCH>` (the escape boundary) | ONE authoritative full run: `<FULL-SUITE COMMAND>` (~<N> min) | `<PRIMARY PORT/ENV>`, on the FINAL commit |

Standing default — change the commands, not the policy:

- Scoped e2e per work unit and per PR inside a branch. It covers exactly the
  features that changed and runs on an isolated port. Never a full suite.
- The full suite runs ONCE, at the merge that reaches `<PROTECTED-BRANCH>`, on
  the final commit. Where PRs merge straight to `<PROTECTED-BRANCH>`, the PR is
  that boundary; where PRs stack onto an integration branch, the full run waits
  for that later merge and the stacked PRs stay scoped.
- Select the scoped set by grepping for what *traverses* the changed surface,
  not for what asserts it. A set chosen by assertions under-covers and the
  saving is fake.
- Redundant full runs belong in CI on `<PROTECTED-BRANCH>`, never in agent
  time. Hosted CI runs cost zero agent tokens and zero agent minutes.
- Any commit after a green run voids it as evidence — re-run before merging.

<!-- delete unless runs can collide --> Builds are serialised against any live
preview a check reads from: a build rewriting `<BUILD-OUTPUT-DIR>` under a
running preview produces mass false failures.

<!-- delete if the full run is fast --> During the full run's idle minutes:
`<PARALLEL WORK, e.g. draft the PR body from the evidence>`.

<!-- delete unless the user explicitly overrode the standing default -->
Deviation from the standing default: <WHAT CHANGED> — <THE USER'S REASON,
QUOTED>.

## Read before you touch

<!-- Pointers beat explanations. A pointer stays current; prose rots. -->

- `<PATH>` — read before <AREA OF WORK>.
- `<PATH>` — read before <AREA OF WORK>.

## Rules

<!-- Observed failures only. Add a rule the day an agent gets it wrong,
     not the day you imagine it might. Delete a rule that never fires.
     EXCEPTION: the first rule below is STANDING and not deletable — it is the
     one rule that governs whether any of the others reach the agent that is
     actually acting. -->

- Any rule that constrains a subagent must be restated inline in that
  subagent's brief, or enforced by a hook where the subagent acts —
  path-scoped rules and this file do not travel across a delegation boundary.
  <!-- STANDING. Not deletable. A subagent's context is fresh by construction:
       it never inherits this file, and a `.claude/rules/` file loads only when
       the subagent reads a matching path. Writing a brief is not reading that
       path, so the rule is invisible exactly where it binds. -->
- <RULE, ONE LINE, IMPERATIVE.>
- <RULE, ONE LINE, IMPERATIVE.>

## Never

<!-- Keep this list short and keep it enforced. Anything here that MUST hold
     also needs a PreToolUse hook - prose is a request, not a guarantee. -->

- <NEVER-DO ITEM.> <!-- enforced by .claude/hooks/<SCRIPT> -->

Guards can be bypassed deliberately: `bypassPermissions` mode, `CHARGE_YOLO=1`,
or `touch .claude/.bypass-guards`. <!-- delete this line if no T2 hooks -->

## Deploy boundary

<!-- Delete unless merge behaviour is surprising. -->

<WHAT HAPPENS ON MERGE TO <DEFAULT-BRANCH>. WHAT NEEDS HUMAN APPROVAL.>

## Agent files

<!-- One line per file that exists. Delete every line whose file you did not
     write - a pointer to a missing file is worse than no pointer. -->

- `docs/agents/rulings-<DATE>.md` — the user's verbatim decisions. Outranks everything below.
- `CONSTITUTION.md` — invariants. User-amendable only.
- `AGENT-MEMORY.md` — cross-session state. Advisory; read before starting, update in the same commit.
- `.claude/rules/` — path-scoped rules; load only when a matching file is read.

## Precedence

<!-- Delete unless two or more of the files above exist. -->

User's verbatim words → `docs/agents/rulings-*.md` → `CONSTITUTION.md` → this
file → the current plan → `AGENT-MEMORY.md` (advisory) → skill defaults.

## How this file changes

<!-- KEEP THIS SECTION. It is what stops this file growing into noise.
     It governs the file it sits in, so it must live here, not in a skill. -->

- A rule is added only after an agent got it wrong — cite the date and what
  broke. No speculative rules.
- Before adding, try three cheaper homes first: a **hook** if it must always
  hold, a **path-scoped rule** in `.claude/rules/` if it only applies to some
  files, or a **pointer** if the answer is already in the repo.
- Adding a line means budgeting for it: if the file is at its cap, something
  else is deleted in the same edit.
- A rule that has not fired in a sprint is deleted. Silence is the signal.
- Facts about the codebase never live here — they rot. Point at the file.

---

<!-- DEDUP CHECKLIST - run before saving, delete nothing but lines:

  [ ] Read the user's global instruction file. Delete every line here that it
      already says, in any wording. Global rules apply everywhere.
  [ ] No-op test per sentence: if removing it would not change agent behavior,
      remove it.
  [ ] No line restates something one `ls`, one `cat package.json`, or one
      `grep` would reveal.
  [ ] No section describes code. Replace descriptions with a path pointer.
  [ ] Line count under 200. Under 100 is better.
  [ ] Every "Never" item that MUST hold has a hook, not just this sentence.
  [ ] The standing delegation-boundary rule is still the first line of
      "## Rules". It is never edited away to save budget.
  [ ] Every rule here that binds a subagent is also restated in the subagent
      brief or wave template that binds it.
  [ ] No absolute path from any operator's machine appears anywhere.
  [ ] Never generated by /init.
-->
