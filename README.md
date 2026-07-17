# charge — take charge

A personal fork of [obra/superpowers](https://github.com/obra/superpowers)
merged with an original autonomy suite. One toolkit, 20 skills, one master
router.

**Two halves, one spine:**

- **Autonomy suite (original):** `owner` decides WHAT to build (kickoff
  interview → founder-grade research → scored backlog), `goal` contracts each
  item (mechanical done_when, guards, caps), `loop` drives it to a verified
  finish — self-reprompting after every completion until the backlog is
  provably empty or an honest terminal state fires.
- **Discipline skills (forked, adapted):** brainstorming, writing-plans,
  executing-plans, subagent-driven-development, dispatching-parallel-agents,
  systematic-debugging, test-driven-development, requesting-code-review,
  receiving-code-review, verification-before-completion, using-git-worktrees,
  finishing-a-development-branch, writing-skills.
- **Enforcement & tooling (v1.1):** `guardrails` (PreToolUse safety hooks +
  ccusage-backed budget halt + skill vetting), `mcp-builder` (Anthropic,
  Apache-2.0, verbatim), `skill-audit` (catalog footprint auditor, workflow
  from steipete's skill-cleaner), spec-kit constitution/templates inside
  `goal`, proven loop presets in `loop/assets/RECIPES.md`, and Anthropic's
  official validation scripts inside `writing-skills/scripts`.
- **`using-charge`** is the master skill: routing table, workflow chains,
  house rules, red-flag tables. It decides which skill fires when.

## Install (Claude Code)

```bash
cp -r skills/* ~/.claude/skills/          # user-level
# or per-project:  cp -r skills/* .claude/skills/
```

Do NOT install alongside obra/superpowers — folder names intentionally match;
this replaces it.

## Activation (make using-charge fire every session)

Add to `~/.claude/settings.json` (or project settings):

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Read and follow the using-charge skill before responding to anything.",
        "timeout": 30
      }]
    }]
  }
}
```

Or the zero-config route — one line in `CLAUDE.md`:

```
At session start, read skills/using-charge/SKILL.md and follow it for all work.
```

## Publish to GitHub (run yourself — takes two commands)

```bash
cd charge
gh repo create charge --private --source . --push
# or without gh:
# git remote add origin git@github.com:<you>/charge.git && git push -u origin main
```

Or hand this folder to Claude Code and say: "init and push this repo to my
GitHub as 'charge' (private)."

## Quick start

- "Take charge of this project and improve it" → owner (asks ≤5 questions,
  researches, backlogs, then works item after item).
- "Let's build X" → brainstorming → goal → writing-plans → execution.
- "Keep going until tests pass, stop after 10 turns" → loop.
- Any bug → systematic-debugging. Any "done" claim → verification gate.

See ATTRIBUTION.md and LICENSE (MIT).
