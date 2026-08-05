# charge — the executable arm of the Orchestra brain

One plugin, 46 skills, three layers, one router. v2.6.

## Three-layer architecture

| Layer | Lives | Role |
|---|---|---|
| **Knowledge** | Orchestra vault (separate repo) | The brain: doctrine, concepts, verified mechanisms. Charge's revamped skills are re-anchored to it; it is not shipped here. |
| **Practice** | Matt Pocock's engineering chain, vendored **verbatim** | How attended work runs: grilling → to-spec → to-tickets → implement/tdd → code-review. Content and frontmatter untouched — see SYNC.md. |
| **Harness** | Autonomy suite (charge-origin) | What runs unattended: owner decides WHAT, goal contracts done_when, ralph-loop drives fresh-context iterations to an honest terminal state (DONE / BLOCKED / NEEDS-APPROVAL / EXHAUSTED / STALLED) — guarded by guardrails' deterministic hooks. |

`agent-config-init` is how the knowledge layer's payload reaches a new repo: it
lands the doctrine as a repo's own CLAUDE.md, settings, hooks and rules —
self-contained, no link back to the brain — and `agent-config-audit` checks that
payload for drift afterwards.

The router (`using-charge`) binds the layers: every intent routes either
into Matt's chain (human in the loop) or into the autonomy suite
(goal → ralph-loop, or owner for self-directed runs). Rubrics defer upward —
the harness never duplicates what the practice layer already does better.

## Skill inventory

### Vendored — Matt Pocock (35, verbatim, MIT)

Charge vendors Matt's catalog **whole** — every skill he publishes, including
the `in-progress/` and course-authoring ones. Content and frontmatter are
untouched; see SYNC.md.

| Skill | Purpose |
|---|---|
| ask-matt | Router over Matt's own skills — which flow fits this situation |
| code-review | Two-axis review (Standards vs Spec) of a diff |
| codebase-design | Codebase-level design guidance |
| diagnosing-bugs | Root-cause diagnosis before fixing |
| domain-modeling | Domain model before implementation |
| grill-with-docs | Interrogate a plan against real docs |
| implement | Attended implementation workflow (tdd → review → commit) |
| improve-codebase-architecture | Architecture improvement passes |
| prototype | Throwaway exploration mode |
| research | Codebase/ecosystem research |
| resolving-merge-conflicts | Merge-conflict resolution |
| tdd | Red-green cycle, seams, test anti-patterns |
| to-spec | Conversation → spec |
| to-tickets | Spec → sliced tickets with blocking edges |
| triage | Issue lifecycle states pre-execution |
| setup-matt-pocock-skills | Once-per-repo initializer: issue tracker, triage labels, domain-doc layout (vendored) |
| wayfinder | Codebase orientation |
| wizard | Generate an interactive bash wizard for steps only a human can do |
| grill-me | Get grilled on your own idea |
| grilling | Frontier-round alignment interview (design tree) |
| handoff | Compact a session into a handoff doc |
| teach | Teach a skill or concept inside this workspace |
| to-questionnaire | Turn an unanswerable decision into a questionnaire for someone else |
| wait-what | Stop — that message didn't land, re-pitch it |
| writing-for-agents | Doctrine for any document an agent consumes (skills, AGENTS.md, CLAUDE.md) |
| git-guardrails-claude-code | PreToolUse hook blocking destructive git |
| migrate-to-shoehorn | Replace `as` assertions in tests with @total-typescript/shoehorn |
| scaffold-exercises | Scaffold course exercise directories that pass linting |
| setup-pre-commit | Husky pre-commit setup |
| claude-handoff | Hand the session to a fresh background agent (in-progress) |
| loop-me | Grill out specs for workflows to build (in-progress) |
| setup-ts-deep-modules | dependency-cruiser entry-point boundaries for TS packages (in-progress) |
| writing-beats | Assemble raw material into a journey of beats (in-progress) |
| writing-fragments | Mine raw fragments, no structure yet (in-progress) |
| writing-shape | Shape raw material into an article, paragraph by paragraph (in-progress) |

### Charge-origin (11)

| Skill | Purpose |
|---|---|
| using-charge | THE router — the only model-invoked charge skill |
| agent-config-init | Once-per-repo agent infrastructure install: explore → grill → record verbatim rulings → write only the earned tiers (CLAUDE.md, settings, hooks, rules, memory, constitution, loop wiring) |
| agent-config-audit | Read-only drift audit of an existing repo's agent config across nine checks (budget, global duplication, prose-that-should-be-hooks, hook fire tests, false enforcement claims, memory, precedence, skill economics, stale pointers) |
| owner | Self-directed project ownership: kickoff, research, JSON backlog, drift audits |
| goal | done_when contracts: mechanical checks, guard pairing, approval boundaries, NOT-READY |
| ralph-loop | Fresh-context bash loop to a verified finish; sigil vocabulary, stall detection, JSON state |
| guardrails | Deterministic enforcement: PreToolUse denies, budget halt, hook timeouts, skill vetting |
| subagent-driven-development | Parallel dispatch with per-task reviewer gates and post-integration conflict checks |
| testing-skills | Adversarial skill pressure-testing (authoring defers to writing-for-agents) |
| skill-audit | Catalog footprint audit and pruning |
| mcp-builder | MCP server construction (Anthropic, Apache-2.0) |

## Invocation economics

Every skill's name + description is always-loaded context; bodies load on
invocation. Charge pays for exactly one model-invoked description of its
own: `using-charge`. Every other charge-origin skill carries
`disable-model-invocation: true` and fires only via the router or by
hand. Matt's vendored skills keep HIS frontmatter exactly — his
invocation design is doctrine, not ours to edit. Run `skill-audit` after
any catalog change.

Vendoring the catalog whole has a price: `wizard`, `migrate-to-shoehorn` and
`scaffold-exercises` are model-invoked, so their descriptions are always-loaded
context even in repos with no TypeScript tests and no course exercises. The
other eleven additions carry `disable-model-invocation: true` and cost nothing
until called. Editing that frontmatter here would break the verbatim rule —
disable the skills locally instead if the budget matters more than the breadth.

## Install (Claude Code)

```bash
cp -r skills/* ~/.claude/skills/          # user-level
# or per-project:  cp -r skills/* .claude/skills/
```

Do NOT install alongside the mattpocock-skills plugin or obra/superpowers
— folder names intentionally collide; charge replaces both.

## Attribution

- ATTRIBUTION.md — full provenance: Matt Pocock (MIT, vendored 1.2.2),
  superpowers fork remnants, Anthropic, spec-kit, and the rest.
- SYNC.md — how to diff and refresh the vendored skills against upstream.
- LICENSE — MIT for this repository.
