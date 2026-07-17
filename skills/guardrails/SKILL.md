---
name: guardrails
description: >-
  Use when setting up charge on a machine or project, before any unattended or
  long autonomous run, when wiring budget limits, or when vetting a third-party
  skill before install. Installs charge's deterministic enforcement layer:
  PreToolUse hooks that block destructive commands regardless of what the model
  decides, a daily budget halt backed by ccusage cost tracking, Stop-hook
  verification wiring, and a supply-chain vetting checklist. Triggers: "set up
  guardrails/hooks," "protect this repo," "add a budget cap," "is this skill
  safe to install," "prepare for an overnight run."
---

# Guardrails — deterministic enforcement, not polite requests

Skills, CLAUDE.md, and prompts are weighted inputs to a probabilistic engine —
they shape behavior, they do not enforce it. Anything that must **never**
happen needs a mechanism that fires regardless of what the model reasons: a
hook or a permission rule. Real incidents behind this rule: agents wiping home
directories, hard-resetting repos, and destroying production databases along
with their volume-level backups in seconds. charge's discipline skills make
the model *want* to do the right thing; this skill makes the wrong thing
*impossible or gated*.

**Announce at start**, then walk the install in order.

## The starter set (three hooks)

1. **`guard-bash`** (PreToolUse on Bash) — hard-blocks destructive command
   patterns before execution: recursive deletes at dangerous roots,
   `git reset --hard` / `clean -f` / `checkout -- .` / `stash drop` /
   force-push or branch-delete on main, `DROP TABLE|DATABASE`, infra
   `destroy`, disk-level writes (`mkfs`, `dd of=/dev/`), `chmod -R 777 /`,
   pipe-to-shell installs (`curl … | bash`), shutdowns, and fork bombs. Deny
   returns a reason to Claude: ask the human to run it manually, or — for a
   genuinely intended operation — the human re-runs with
   `CHARGE_GUARD_ALLOW=1` in the environment. The override is for humans, not
   for the model to set.
2. **`budget-halt`** (PreToolUse on Bash) — if `CHARGE_DAILY_BUDGET_USD` is
   set, checks today's estimated spend via **ccusage** (offline, reads
   `~/.claude/projects/` logs; 60s cache to stay fast) and denies further tool
   calls once the ceiling is crossed. Caveat baked into the message: ccusage
   is an estimate and can undercount the real bill 10–30% on heavy tool use
   (it can't see server-side overhead) — set the ceiling below your true
   limit. For richer monitoring: `npx ccusage@latest` daily/blocks views, or
   its MCP mode so a loop can check its own burn rate mid-run.
3. **The Stop gate** — for unattended runs, wire a Stop hook so the session
   cannot end without proof: the loop skill's `scripts/stop-check.sh`
   (deterministic checks) or the prompt/agent-type JSON examples in the owner
   skill's `references/self-reprompting.md`. Always set a `timeout` on every
   hook — an unbounded hook chain has recursed into a four-figure overnight
   bill.

## Install

1. Copy this skill's `scripts/` somewhere stable (they ship executable):
   `~/.claude/skills/guardrails/scripts/` after a normal charge install.
2. Merge [assets/settings.example.json](assets/settings.example.json) into
   `~/.claude/settings.json` (or the project's `.claude/settings.json`),
   adjusting paths. It wires SessionStart (using-charge activation) +
   guard-bash + budget-halt with timeouts.
3. `export CHARGE_DAILY_BUDGET_USD=<n>` in your shell profile to arm the
   budget hook (unset = disarmed).
4. Restart the session and approve the hooks trust dialog. Verify: ask Claude
   to run `git reset --hard` on a scratch repo — it must be denied with the
   guard's reason.
5. Hook payload formats evolve — before relying on these unattended, verify
   the current PreToolUse/Stop JSON contract against the live hooks docs.

## Vetting third-party skills (before ANY install)

A skill is untrusted code running with your agent's permissions; the 2026
ecosystem was actively poisoned (a third of audited marketplace skills had
flaws; top-downloaded listings were confirmed malware). The checklist:

1. **Read the raw SKILL.md and every bundled script, fully.** Three lines of
   markdown can exfiltrate SSH keys.
2. **Hard no on egress/exec red flags:** `curl|wget … | sh`, base64-decoded
   payloads, auto-installers pulling arbitrary URLs, obfuscated one-liners.
3. **Lethal-trifecta test:** private-data access + untrusted-content exposure
   + external communication in one skill = high risk; demand a reason for
   each leg.
4. **Permissions sanity:** a formatter never needs Bash, network, or Docker.
5. **Named, reputable publishers only** (Anthropic, established maintainers);
   verify the exact repo — typosquats of popular tools are a confirmed attack
   path. Scanners help but catch code signatures, not prompt injection — a
   pass is necessary, never sufficient.
6. **Pin versions; diff every update** like any dependency.

## Scope honesty

Hooks enforce on this machine/project only; they are not a sandbox. For
consequential autonomy, keep the rest of the stack from loop's guardrails:
auto mode (never skip-permissions), worktree/`claude/`-branch isolation,
`--max-turns` + budget flags, and approval gates on anything irreversible.
