---
name: using-charge
description: >-
  Use when starting any conversation or coding task in a charge-equipped
  project — the router that maps intent to the right skill before any
  response, exploration, or clarifying question. Routes: building or changing
  anything while direction is open (grilling or grill-with-docs to align,
  then domain-modeling → to-spec → to-tickets → implement with tdd inside →
  code-review); autonomy ("keep going until done," "run unattended," "own
  this project") to goal/loop/owner; unattended-run safety, budget caps, and
  skill vetting to guardrails; skill authoring, pressure-testing, and catalog
  audits to writing-great-skills/testing-skills/skill-audit; MCP work to
  mcp-builder; bugs, failing tests, regressions to diagnosing-bugs;
  architecture-scale refactors to wayfinder/improve-codebase-architecture.
  If any charge skill could apply, load this first.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute one specific brief, ignore
this router and execute your brief.
</SUBAGENT-STOP>

# Using charge

charge is three layers sharing one spine: Matt Pocock's practice chain
(vendored, MIT) for attended work, an autonomy suite (goal → loop, owner)
for unattended work, and guardrails underneath both. Route the intent below
BEFORE any response or action — including clarifying questions and codebase
exploration. Announce "Using <skill>", then follow it exactly. A routed skill
that is user-invoked can't be loaded by you: give the user its exact name to
run, and wait.

## Routing table

| Intent sounds like | Route |
| --- | --- |
| "Build X / add a feature / change behavior" — direction still open | **grilling** (align) → **domain-modeling** → **to-spec** → **to-tickets** → **implement** (tdd inside) → **code-review** |
| Same, but a PRD/docs exist to align against — or docs should fall out of the interview | **grill-with-docs**, then the same chain |
| "Define done / acceptance criteria / ready this for an autonomous run" | **goal** |
| "Keep going until X / run unattended / don't stop until done" | **loop** (consumes goal's contract) |
| "Own this project / take charge / improve it for hours" | **owner** (drives goal + loop per item) |
| Setup, budget caps, hook wiring, pre-unattended checks, "is this skill safe to install" | **guardrails** |
| "Execute this plan" — independent tasks, subagents available | **subagent-driven-development** |
| Any bug, failing test, regression, or "something's broken/slow" | **diagnosing-bugs** |
| Work too big for one session / "where do we even start" | **wayfinder** |
| "Improve the architecture / find deepening opportunities" | **improve-codebase-architecture** |
| Write or edit a skill | **writing-great-skills** |
| Pressure-test a skill before shipping | **testing-skills** |
| Catalog bloat, duplicate skill names, description budget | **skill-audit** |
| "Build an MCP server / wrap an API for agents" | **mcp-builder** (CLI-first gate inside) |
| Sanity-check a design with throwaway code | **prototype** |
| "Research this / gather docs or API facts" | **research** |
| Incoming issues/PRs to categorize and brief | **triage** |
| In-progress merge/rebase conflict | **resolving-merge-conflicts** |
| Ending a session another will continue | **handoff** |

## Rules

1. **Process before implementation** — when several apply, the earlier-chain
   skill wins and calls the rest.
2. **Attended vs unattended** — a human answering questions takes Matt's
   chain; "while I'm away" takes goal/loop/owner, with guardrails first.
3. **Precedence** — the user's direct instructions and project files
   (CLAUDE.md, AGENTS.md) override skills; skills override default behavior.
