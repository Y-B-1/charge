# Attribution

charge's discipline skills (brainstorming, writing-plans, executing-plans,
subagent-driven-development, dispatching-parallel-agents, systematic-debugging,
test-driven-development, requesting-code-review, receiving-code-review,
verification-before-completion, using-git-worktrees,
finishing-a-development-branch, writing-skills, and the using-charge master
pattern) are a personalized fork of **Superpowers** by Jesse Vincent (obra) —
https://github.com/obra/superpowers — MIT License, Copyright (c) 2025 Jesse
Vincent. Supporting prompt/reference files are carried from that repository
with light adaptation. The autonomy suite (owner, goal, loop) is original to
this repository, informed by Anthropic's loops guidance, the Forward Future
Loop Library, Geoffrey Huntley's Ralph technique, and the June–July 2026 loop
engineering literature.

MIT License applies to this repository; see LICENSE.

## v1.1 integrations

- **anthropics/skills** (Apache-2.0): mcp-builder skill carried verbatim
  (skills/mcp-builder, LICENSE.txt retained); skill-creator validation
  scripts (quick_validate, package_skill, improve_description, utils) carried
  into writing-skills/scripts with LICENSE-anthropic.txt.
- **github/spec-kit** (MIT): constitution/spec/plan/tasks/checklist templates
  carried into goal/assets/speckit with source headers.
- **steipete/agent-scripts** (MIT): skill-audit's workflow adapted from
  skill-cleaner; reimplemented portably (no code carried).
- **Forward-Future/loopy** (MIT) and **serenakeyitan/awesome-agent-loops**
  (CC BY 4.0, attribution retained): loop recipe patterns adapted into
  loop/assets/RECIPES.md.
- **ryoppippi/ccusage** (MIT): used as an external tool by
  guardrails/scripts/budget-halt.sh; no code carried.
