# Attribution

charge's discipline skills (brainstorming, writing-plans, executing-plans,
subagent-driven-development, dispatching-parallel-agents, systematic-debugging,
test-driven-development, requesting-code-review, receiving-code-review,
verification-before-completion, using-git-worktrees,
finishing-a-development-branch, writing-skills, and the using-charge master
pattern) were, through v1.x, a personalized fork of **Superpowers** by Jesse
Vincent (obra) — https://github.com/obra/superpowers — MIT License, Copyright
(c) 2025 Jesse Vincent. Eleven of the forked skills were removed in v2.0.0
(superseded by the vendored Matt Pocock skills below); the surviving fork,
writing-skills, was renamed testing-skills. Supporting prompt/reference files
were carried from that repository with light adaptation. The autonomy suite
(owner, goal, loop) is original to
this repository, informed by Anthropic's loops guidance, the Forward Future
Loop Library, Geoffrey Huntley's Ralph technique, and the June–July 2026 loop
engineering literature.

MIT License applies to this repository; see LICENSE.

## v1.1 integrations

- **anthropics/skills** (Apache-2.0): mcp-builder skill carried verbatim
  (skills/mcp-builder, LICENSE.txt retained); skill-creator validation
  scripts (quick_validate, package_skill, improve_description, utils) carried
  into testing-skills/scripts with LICENSE-anthropic.txt.
- **github/spec-kit** (MIT): constitution/spec/plan/tasks/checklist templates
  carried into goal/assets/speckit with source headers.
- **steipete/agent-scripts** (MIT): skill-audit's workflow adapted from
  skill-cleaner; reimplemented portably (no code carried).
- **Forward-Future/loopy** (MIT) and **serenakeyitan/awesome-agent-loops**
  (CC BY 4.0, attribution retained): loop recipe patterns adapted into
  loop/assets/RECIPES.md.
- **ryoppippi/ccusage** (MIT): used as an external tool by
  guardrails/scripts/budget-halt.sh; no code carried.

## v2.0 vendoring — Matt Pocock skills

**mattpocock/skills** (MIT, Copyright (c) 2026 Matt Pocock) —
https://github.com/mattpocock/skills — vendored **verbatim** (content and
frontmatter untouched) from plugin version **1.2.0**, on **2026-08-01**.
Each skill's entire directory is carried into `skills/<name>/`. See SYNC.md
for the refresh procedure.

Vendored skills:

- engineering: code-review, codebase-design, diagnosing-bugs,
  domain-modeling, grill-with-docs, implement,
  improve-codebase-architecture, prototype, research,
  resolving-merge-conflicts, tdd, to-spec, to-tickets, triage, wayfinder, setup-matt-pocock-skills
- productivity: grill-me, grilling, handoff, writing-great-skills
- misc: git-guardrails-claude-code, setup-pre-commit

As of v2.0 these supersede and replace the former superpowers-forked
discipline skills (brainstorming, writing-plans, executing-plans,
dispatching-parallel-agents, using-git-worktrees,
finishing-a-development-branch, requesting-code-review,
receiving-code-review, verification-before-completion,
systematic-debugging, test-driven-development), which are removed. The
superpowers attribution above is retained for the remaining forked
material (testing-skills — formerly writing-skills — and the using-charge
router pattern).
