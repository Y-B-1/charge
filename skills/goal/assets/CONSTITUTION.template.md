<!-- Adapted from github/spec-kit's constitution template (MIT), thinned for
     the goal skill's readiness gate. Instantiate ONCE per project, and ONLY
     where no ADRs exist — existing ADRs and the domain glossary are the
     preferred source of standing principles (grill-with-docs produces both). -->
# [PROJECT_NAME] Constitution

Standing principles every contract and plan must honor. A GOAL contract that
contradicts an article is NOT-READY until the contract changes or the article
is amended with the user — the contract never silently overrides it.

## Principles

### I. [PRINCIPLE_NAME]  <!-- e.g. Test-First (NON-NEGOTIABLE) -->
[One or two prescriptive sentences. Checkable phrasing beats aspiration:
"every feature lands with a failing test first," not "we value quality."]

### II. [PRINCIPLE_NAME]
[...]

### III. [PRINCIPLE_NAME]
[...]

## Constraints  <!-- optional: stack, security, compliance, performance floors -->
- [e.g. no new runtime dependencies without approval; p95 < 200ms on /api/*]

## Governance
- Amendments: documented, approved by the owner, with a migration note.
- Once ADRs exist for an area, they supersede this file for that area.

**Version**: [X.Y.Z] | **Ratified**: [DATE] | **Last amended**: [DATE]
