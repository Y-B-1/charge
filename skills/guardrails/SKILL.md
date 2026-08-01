---
name: guardrails
description: >-
  Use when setting up charge on a machine or project, before any unattended or
  long autonomous run, when wiring budget limits, or when vetting a third-party
  skill before install. Installs charge's deterministic enforcement layer — the
  hooks that make skip-permissions-inside-isolation survivable: a PreToolUse
  guard that blocks destructive commands regardless of what the model decides,
  a daily budget halt backed by pinned ccusage cost tracking (fail-open,
  undercount caveats documented), explicit-timeout hygiene for every hook, and
  a supply-chain vetting checklist. Triggers: "set up guardrails/hooks,"
  "protect this repo," "add a budget cap," "is this skill safe to install,"
  "prepare for an overnight run."
disable-model-invocation: true
---

# Guardrails — deterministic enforcement, not polite requests

Skills, CLAUDE.md, and prompts are weighted inputs to a probabilistic engine —
they shape behavior, they do not enforce it. Anything that must **never**
happen needs a mechanism that fires regardless of what the model reasons: a
hook. Real incidents behind this rule: agents wiping home directories,
hard-resetting repos, and destroying production databases along with their
volume-level backups in seconds.

Isolation is spatial, not behavioral: a container controls *where* commands
run, not *what* runs — and mounted credentials walk right through the wall.
The autonomous posture is `--dangerously-skip-permissions` **inside**
whole-process isolation (container, VM, or sandbox-runtime), where permission
prompts don't exist. These hooks are what make that posture survivable:
guard-bash caps the destructive blast radius, budget-halt caps the financial
one. Install them inside the environment the loop runs in.

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
2. **`budget-halt`** (PreToolUse, matcher `*`) — the financial circuit
   breaker. If `CHARGE_DAILY_BUDGET_USD` is set, checks today's estimated
   spend via **ccusage** (pinned version, offline, reads
   `~/.claude/projects/` logs; 60s cache to stay fast) and denies **all**
   further tool calls once the ceiling is crossed — not just Bash. Caveat
   baked into the message: ccusage is an estimate and can undercount the real
   bill 10–30% on heavy tool use (it can't see server-side overhead) — set
   the ceiling below your true limit. **Isolation caveat:** inside
   `docker sandbox` or any container, ccusage reads the *container's*
   `~/.claude/projects/`, so the ceiling is per-environment, not per-account —
   mount the host logs into the container if you want an account-level
   ceiling; otherwise the estimate silently undercounts everything spent
   outside that environment. For richer monitoring: ccusage's daily/blocks
   views, or its MCP mode so a loop can check its own burn rate mid-run.
3. **Verification wiring** — for unattended runs, the default is the loop
   skill's fresh-context harness, which verifies harness-side (the completion
   sigil is gated on a real command, and EXHAUSTED/STALLED are
   harness-detected). For in-session runs, wire a Stop hook instead: the loop
   skill's `scripts/stop-check.sh` (deterministic checks) or the prompt/agent
   examples in the owner skill's `references/self-reprompting.md`.

## Hook hygiene: timeouts and recursion

- **Every hook entry carries an explicit `timeout`.** Defaults exist (600 s
  for `command`/`http`/`mcp_tool`, 30 s `prompt`, 60 s `agent`) — set
  explicit timeouts sized to the job rather than relying on them: a grep
  guard needs 20 s, not 600.
- **`prompt` and `agent` hooks are LLM calls billed per fire** — a prompt
  hook is a Haiku evaluation, an agent hook a tool-using subagent of up to 50
  turns. An LLM handler on a per-tool-call event multiplies cost by every
  tool call in the session; keep LLM handlers on per-turn or per-session
  events unless the per-call cost is deliberate. The timeout is a cost bound,
  not just a hang bound.
- **Recursion is doubly bounded — keep both bounds.** Stop-hook chains
  re-fire on every blocked stop; the harness caps the *depth* (override after
  ~8 consecutive blocks, `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`) while your
  `timeout` caps each firing's *duration and cost*. Two different bounds,
  both needed. Parse `stop_hook_active` in hook input so a verification hook
  doesn't re-trigger itself. (Single-author anecdote, low confidence: a hook
  chain left without explicit limits has been blamed for a four-figure
  overnight bill — unverified, but both bounds above are cheap.)

## Install

1. Copy this skill's `scripts/` somewhere stable (they ship executable):
   `~/.claude/skills/guardrails/scripts/` after a normal charge install.
2. Merge [assets/settings.example.json](assets/settings.example.json) into
   `~/.claude/settings.json` (or the project's `.claude/settings.json`),
   adjusting paths. It wires SessionStart (using-charge activation) +
   guard-bash (matcher `Bash`) + budget-halt (matcher `*`), every entry with
   an explicit timeout.
3. `export CHARGE_DAILY_BUDGET_USD=<n>` in your shell profile to arm the
   budget hook (unset = disarmed). budget-halt pins its ccusage version —
   bump the pin deliberately and diff the release first (vetting rule 6),
   never float `@latest` inside a hook.
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

Hooks enforce on this machine/project only; they are not a sandbox — MCP
servers and hooks themselves run unconstrained on the host, and the built-in
sandbox constrains only Bash. For consequential autonomy, run the full stack:
whole-process isolation (container/VM/sandbox-runtime) with skip-permissions
inside it, these hooks armed inside that environment, an iteration cap and
the budget ceiling set before the first pass, and approval-boundary actions
staged at NEEDS-APPROVAL — prepared by the loop, fired only by the human.
