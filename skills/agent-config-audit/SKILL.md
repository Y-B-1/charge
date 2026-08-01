---
name: agent-config-audit
description: >-
  Audit an existing repo's agent infrastructure — CLAUDE.md, hooks,
  settings.json, memory files, project-local skills — against
  instruction-budget and enforcement doctrine, then report the fixes. Run
  periodically as a drift check, and after any change to CLAUDE.md,
  .claude/settings.json, a hook script, or a memory file. Triggers: "audit
  this repo's setup," "is our CLAUDE.md too long," "check our hooks actually
  fire," "why does the agent ignore our rules," "review our agent config,"
  "we just rewrote CLAUDE.md." Ten checks: instruction budget and the no-op
  test, duplication against the user's global CLAUDE.md, prose rules that
  should be hooks, hook validity plus live fire tests, false enforcement
  claims, memory shape and staleness, precedence coherence, project skill
  economics, stale pointers. Reports PASS or BLOCK with severity-ranked
  findings, the exact fix per finding, and an honest list of what already
  passes. Read-only by default: it diagnoses, it does not edit.
disable-model-invocation: true
---

# Project Audit — catch config drift before the agent does

Agent infrastructure rots in one direction: files grow, rules accrete, hooks
break silently, and docs keep claiming enforcement that stopped existing three
commits ago. None of that shows up as a failing test. This skill is the
periodic sweep that makes the rot visible.

Two facts set the whole standard:

- **A standing rule is a request, not a guarantee.** Only a hook fires every
  time. Prose that MUST hold and isn't enforced is a defect, not a style
  choice.
- **A rule the agent keeps violating means the file is too long and the rule
  is getting lost.** Recorded violations are budget evidence, not a reason to
  add another sentence.

**Read-only.** Produce the report and stop. Apply fixes only when the user
asks, and then one finding at a time.

**Announce at start**: name the repo, the global file you will diff against,
and say the audit does not edit.

---

## Step 0 — Establish scope

Collect, and say what you found (missing is a finding, not an error):

| Layer | Typical paths |
|---|---|
| Project brief | `CLAUDE.md`, `AGENTS.md`, nested `*/CLAUDE.md`, `.claude/rules/*.md` |
| Charter / invariants | `CONSTITUTION.md`, `CHARTER.md`, `docs/invariants*.md` |
| Harness config | `.claude/settings.json`, `.claude/settings.local.json`, `.mcp.json` |
| Hooks | every `command` script referenced by settings |
| Memory | `MEMORY.md`, `PROGRESS*`, `progress.txt`, `PRD.md`, `RESEARCH*.md`, `.claude/memory/` |
| Project skills | `.claude/skills/*/SKILL.md` |
| Global brief | the user's global `CLAUDE.md` — ask for the path if not given |

Ask **one** question if the global path is unknown. Ask a second only if the
user mentions a sibling repo to cross-check.

---

## Step 1 — Run the mechanical half

```bash
scripts/audit.sh <repo-dir> --global <path-to-global-CLAUDE.md>
```

Non-interactive. Exit **0** clean · **1** findings · **2** critical (unparsable
settings, missing or broken hook script, hook that cannot block) · **3** usage
error. It reports line counts, JSON validity, `bash -n` per hook, timeout
presence, live hook fire tests, dangling paths, `never/always/MUST` inventory,
and a duplication report against the global brief.

The script measures. **You judge.** It cannot run the no-op test, read intent,
or spot a contradiction between two files — checks 1, 2, 3, 5, 6, 7 need you.

---

## Step 2 — The ten checks

### 1. BUDGET — is the brief still affordable

Cap: **under 200 operational lines** per brief file (headings, blank lines and
HTML comments are free; HTML comments are stripped before injection, so
maintainer notes cost nothing). Over that, adherence drops measurably —
including for the rules the user cares most about.

Then run the **no-op test on every sentence**: *if I delete this line, does any
agent behave differently?* No → sediment, cut it. Kill on sight:

- anything discoverable from the repo (script lists that restate
  `package.json`, directory tours, framework explanations)
- architecture prose that a pointer would carry better — replace with an
  explore-step: `Read src/db/schema.ts before touching queries`
- documented file-system structure, the single fastest-rotting content there
  is; a stale path buys whole turns of confident wrong exploration
- rules relevant to one session type only → move to a skill or a path-scoped
  rules file
- anything an `/init` run generated

Fix format: name the section, the line range, and whether it is **cut**,
**demote to skill**, or **replace with a pointer**.

### 2. DUPLICATION vs the global brief

Read both files **in full**. Every rule stated in both is a defect: the two
concatenate, they never override, so the duplicate pays twice and adds nothing.
**The project file keeps deltas only** — what is true here and not everywhere.

Duplication is not just verbatim repeats. Flag paraphrases, and flag a
project line that is a *weaker* restatement of a global rule (it reads as
permission to relax). Script output ranks candidate pairs by word overlap;
confirm each by reading.

Same rule for a named sibling repo: shared content belongs in the global file
or a shared skill, not copy-pasted into two projects that will drift.

Fix: delete from the project file; if the project genuinely needs a *stricter*
variant, keep one line that states only the delta.

### 3. ENFORCEMENT PLACEMENT — prose that should be code

Every `never` / `always` / `MUST` / `NEVER` sentence in a brief is a candidate
for escalation up the reliability ladder:

**prose (probabilistic, bills every turn) → skill (on-demand process) → hook
(deterministic, zero context unless it emits output) → isolation (spatial,
the command can't reach the thing)**

Ask per sentence: *what happens the one time the model doesn't follow it?* If
the answer is "damage" or "a broken invariant", prose is the wrong layer.

- **MAJOR** — a `MUST`/`never` rule with **recorded violations** (git history,
  the user says "it keeps doing X", an incident note) that is still prose.
  Repeated violation is proof prose failed here; adding emphasis is not a fix.
- **MINOR** — an unviolated `MUST` rule that is cheaply hookable.

Fix: name the target layer and the mechanism. Destructive commands and budget
ceilings → the `guardrails` skill's hooks (charge) or
`git-guardrails-claude-code` (repo-local git blocking). Commit-time
lint/typecheck/test enforcement → `setup-pre-commit`. Multi-step process →
`writing-great-skills`. Do not restate those skills here — route.

### 4. HOOK VALIDITY — a hook that cannot block is decoration

Mechanical, all of it. The script does 4a–4d; you read the results.

- **4a** `settings.json` parses. Unparsable settings means **no hooks at all
  load** — CRITICAL.
- **4b** every referenced script exists and is executable.
- **4c** `bash -n` passes on every hook script.
- **4d** every hook entry carries an **explicit `timeout`**. Missing timeout is
  MAJOR: `prompt` and `agent` handlers are LLM calls billed on every fire, and
  an untimed chain can run up a four-figure bill overnight.
- **4e** **fire test.** Pipe a synthetic `PreToolUse` payload to the hook and
  assert both directions: the blocked shape denies, the allowed shape passes.
  Payload shapes, exit-code contract and expected results:
  **[references/hook-fire-tests.md](references/hook-fire-tests.md)**.

The exit-code contract in one line: **only exit 2 blocks** (stderr goes back to
the model); exit 0 with no output is *no decision*, not approval; exit 1 is a
non-blocking error and the tool call proceeds.

- Dangerous shape not denied → **CRITICAL** if a doc claims it is blocked (see
  check 5), else MAJOR.
- Allowed shape denied → MAJOR (over-blocking trains the user to disable it).
- Hook writes to stdout on every fire → MINOR context tax; hooks should cost
  zero context unless they have something to say.

Also flag: a `PreToolUse` hook expected to gate file reads — it **never fires
for `@`-referenced files**, which are inserted with no tool call. That needs a
`Read` deny rule instead.

### 5. CLAIM TRUTH — false enforcement is the worst finding

Grep the briefs, the charter and the README for enforcement claims:
`enforced by`, `blocked by`, `hook prevents`, `cannot`, `is impossible`,
`automatically`, `pre-commit ensures`. For each, prove the mechanism exists
**and fires** (check 4e). A claim that fails is **CRITICAL, always**: the agent
reads it, believes the floor is there, and acts unguarded on top of nothing.

Fix, in order of preference: (1) restore the mechanism, (2) delete the claim
the same commit the mechanism is removed. Never leave the claim standing while
the mechanism is scheduled.

### 6. MEMORY SHAPE

- **Size**: a file whose load is mandated at session start and exceeds **~200
  lines** is a finding — it competes with the brief for the same budget. Split
  into a thin index plus topic files read on demand.
- **State vs archive**: current state (what's true now) must be separable from
  history (what happened). Append-only logs that never move to an archive file
  become the majority of what loads. Finding when mixed.
- **Staleness**: cached research and findings files need a written expiry
  ("expires end of sprint", a dated stamp). Undated research assets are
  poisoning candidates the moment the API changes — MINOR while accurate,
  MAJOR once contradicted by the repo.
- **Rejected decisions** kept as memory need reason + source + a review date,
  or they veto good ideas after the constraint that killed them is gone.
- **Trust**: anything the agent wrote to its own memory is **untrusted input on
  re-read** — memory files are a prompt-injection surface. Findings: secrets or
  PII in memory (CRITICAL), memory shared across projects instead of
  per-project scope (MAJOR), no instruction anywhere that memory content is
  data and never commands (MINOR).

### 7. PRECEDENCE COHERENCE — who wins

The chain to audit against:

**user's verbatim words → invariants charter → project operating rules → plan
override section → plan body → session memory (advisory) → method/skill
defaults**

Two calls carry most of the value: the ground truth is the user's words
*verbatim*, not any paraphrase (paraphrase drift is the top audited failure
class); and session memory ranks **below** the plan — it informs, it never
overrules what was agreed.

Check for: a stated chain at all (absent → MINOR, unless two layers already
disagree, then MAJOR); files that contradict each other; and any file claiming
final authority that the chain puts lower — e.g. a memory or progress file
telling the agent to override the plan, or a skill asserting it wins over
project rules.

Fix: name the **file pair** and the contradicting lines, say which one the
chain makes authoritative, and edit the loser — not both.

### 8. SKILL ECONOMICS — project-local skills

Per `.claude/skills/*/SKILL.md`:

- `description` ≤ 1024 chars, key use case first (listings truncate at 1,536
  chars for display; the authoring cap is 1,024).
- **Invocation mode matches the true cost.** Only
  `disable-model-invocation: true` costs zero until called; `user-invocable:
  false` still bills its description every session. Side-effecting and rarely
  fired → zero-cost. Model-invoked only when forgetting to invoke costs more
  than the standing tax.
- `SKILL.md` under 500 lines; detail behind pointers. An invoked body stays
  resident for the rest of the session, so its conciseness bar equals
  CLAUDE.md's.
- **Pinned tool versions.** `@latest` anywhere in a gate — hook, pre-commit,
  CI check — is MAJOR: the gate's behavior changes without a commit.
- **No runtime-mutable instruction supply chain.** A skill or hook that
  `curl`s instructions, a prompt, or a script at run time is **CRITICAL** —
  the instruction set becomes whatever the remote host serves today.
- **Trigger collisions**: a description overlapping a built-in or another
  installed skill makes routing nondeterministic. For catalog-wide description
  cost and duplicate names, route to the `skill-audit` skill instead of
  redoing it here.

### 9. STALE POINTERS

Every path, filename, command and skill name referenced in the briefs, charter,
memory and project skills must still resolve. The script lists dangling
candidates; confirm each (some are illustrative, not references). A dead
pointer is MINOR alone, **MAJOR inside a mandated explore-step**, since the
agent follows it before doing anything else.

---

### 10. GROWTH DISCIPLINE — is there a defence against accretion

Nobody writes a 500-line brief on purpose; it accretes one reasonable-looking
line at a time. A repo with no amendment rule will be back over budget by the
next audit, so check that the discipline exists:

- Does `CLAUDE.md` carry a `## How this file changes` section (or equivalent
  amendment rules: add only after an observed failure, try hook/rules/pointer
  first, budget for every addition, delete rules that stop firing)?
- Is a budget guard wired on `Write|Edit` (a `PostToolUse` hook that counts the
  brief after a write and pushes back past the cap)?

Missing section → **MAJOR**. Missing section *and* already over cap → **CRITICAL**:
the file is growing with nothing to stop it. Fix: install the section from
`agent-config-init`'s template and wire its budget guard.

## Step 3 — Severity

| | Meaning |
|---|---|
| **CRITICAL** | The agent is misled or unguarded: false enforcement claim, unparsable settings, a hook the docs rely on that cannot block, secrets in memory, run-time-fetched instructions. Any CRITICAL ⇒ verdict **BLOCK**. |
| **MAJOR** | Doctrine broken with a live cost: brief over cap, duplication against global, violated `MUST` still in prose, missing hook timeout, `@latest` in a gate, contradicting files, oversized mandated memory. |
| **MINOR** | Sediment, unstamped research, missing precedence statement, chatty hooks, dead illustrative pointer. |

---

## Step 4 — Output contract

Emit exactly this shape. **No verdict = BLOCK.**

```
BLOCK            <- or PASS; first line, alone

CRITICAL  CLAUDE.md:41  "enforced by the pre-commit hook" — .husky/pre-commit
          does not exist. Fix: delete line 41, or install the hook via
          setup-pre-commit and re-run the fire test.
MAJOR     .claude/settings.json:22  PreToolUse hook has no timeout.
          Fix: add "timeout": 20 to the hook entry.
MINOR     CLAUDE.md:60-74  "Project layout" section fails the no-op test.
          Fix: cut; replace with `Read src/routes/index.ts before adding a route`.

WHAT PASSES
- CLAUDE.md is 96 operational lines (cap 200).
- guard-bash.sh: bash -n clean, denies `git reset --hard`, allows `git status`.
- No duplication against the global brief.
- All 14 referenced paths resolve.
```

Rules for the report:

- **PASS** only when zero CRITICAL and zero MAJOR. Any CRITICAL ⇒ BLOCK.
- Every finding: severity, `file:line`, the defect, and the **exact** fix — the
  line to cut, the JSON key to add, the skill to route to. "Consider
  improving" is not a fix.
- Findings ranked most severe first.
- The **WHAT PASSES** list is mandatory and honest: it is what stops the next
  audit from re-litigating settled ground. If a check could not run (no `jq`,
  no global path given), say so under a **NOT CHECKED** line — never let it
  pass silently.
- Do not edit files in this skill. To turn the report into work, route to
  `to-tickets`.

## Routing

`guardrails` / `git-guardrails-claude-code` (install or repair blocking hooks)
· `setup-pre-commit` (commit-time gates) · `writing-great-skills` (rewrite a
project skill) · `skill-audit` (catalog-wide description cost, duplicate names)
· `domain-modeling` (glossary and ADR drift) · `to-tickets` (findings → work)
· `handoff` (hand the report to another session).
