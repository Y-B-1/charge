# Task Reviewer Prompt Template

Use this template when dispatching a task reviewer subagent. The reviewer
reads the task's diff once and returns one machine-checkable JSON verdict
file plus a prose report. The controller gates on
`scripts/verdict-check VERDICT_FILE` — never on parsed prose.

**Purpose:** Verify one task's implementation matches its requirements
(nothing more, nothing less) and follows this repo's standards.

The quality rubric is the vendored code-review skill's Standards axis
(../code-review/SKILL.md, step 3): repo-documented standards plus the smell
baseline, repo overrides the baseline, every smell a labelled judgement
call. This template carries placeholders for it; do not substitute a
different rubric.

```
Subagent (general-purpose):
  description: "Review Task N (spec + standards)"
  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
         model silently inherits the session's most expensive one]
  prompt: |
    You are reviewing one task's implementation along two axes: spec
    compliance (does it match what was requested) and standards (is it
    well-built by this repo's rules). This is a task-scoped gate, not a
    merge review — a whole-branch review happens separately after all tasks
    are complete.

    ## What Was Requested

    Read the task brief: [BRIEF_FILE]

    Global constraints from the spec/design that bind this task:
    [GLOBAL_CONSTRAINTS]

    ## What the Implementer Claims They Built

    Read the implementer's report: [REPORT_FILE]

    ## Diff Under Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Read the diff file once — it contains the commit list, a stat summary,
    and the full diff with surrounding context, and it is your view of the
    change. The diff's context lines ARE the changed files: do not Read a
    changed file separately unless a hunk you must judge is cut off
    mid-function — and say so in your report. Do not re-run git commands.
    If the diff file is missing, fetch the diff yourself:
    `git diff --stat [BASE_SHA]..[HEAD_SHA]` and `git diff [BASE_SHA]..[HEAD_SHA]`.
    Do not crawl the broader codebase. Inspect code outside the diff only
    to evaluate a concrete risk you can name — one focused check per named
    risk, and name both the risk and what you checked in your report.
    Cross-cutting changes are legitimate named risks: if the diff changes
    lock ordering, a function or API contract, or shared mutable state,
    checking the call sites is the right method.

    Your review is read-only on this checkout. Do not mutate the working
    tree, the index, HEAD, or branch state in any way.

    ## Do Not Trust the Report

    Treat the implementer's report as unverified claims about the code. It
    may be incomplete, inaccurate, or optimistic. Verify the claims against
    the diff. Design rationales in the report are claims too: "left it per
    YAGNI," "kept it simple deliberately," or any other justification is the
    implementer grading their own work. Judge the code on its merits — a
    stated rationale never downgrades a finding's severity.

    ## Tests

    The implementer already ran the tests and reported results with TDD
    evidence for exactly this code. Do not re-run the suite to confirm their
    report. Run a test only when reading the code raises a specific doubt
    that no existing run answers — and then a focused test, never a
    package-wide suite, race detector run, or repeated/high-count loop. If
    heavy validation seems warranted, recommend it in your report instead of
    running it. If you cannot run commands in this environment, name the
    test you would run.

    Warnings or other noise in the implementer's reported test output are
    findings — test output should be pristine.

    ## Axis 1: Spec Compliance

    Compare the diff against What Was Requested:

    - **Missing:** requirements they skipped, missed, or claimed without
      implementing
    - **Extra:** features that weren't requested, over-engineering, unneeded
      "nice to haves"
    - **Misunderstood:** right feature built the wrong way, wrong problem
      solved

    If a requirement cannot be verified from this diff alone (it lives in
    unchanged code or spans tasks), record it in the verdict's
    `cannot_verify` array instead of broadening your search.

    ## Axis 2: Standards

    Judge the diff against this repo's documented standards and the smell
    baseline below. Three rules bind this axis: a documented repo standard
    always wins over the baseline; every baseline smell is a labelled
    judgement call ("possible Feature Envy"), never a hard violation; skip
    anything tooling already enforces.

    Standards sources in this repo: [STANDARDS_SOURCES]

    Smell baseline (match each against the diff):
    [SMELL_BASELINE]

    Tests are standards too: new and changed tests must verify real
    behavior, not mocks, and cover the task's edge cases.

    ## Severity Calibration

    Categorize findings by actual severity. Not everything is critical.
    **critical** — broken or dangerous behavior: this code cannot ship.
    **important** — this task cannot be trusted until it is fixed: incorrect
    or fragile behavior, a missed requirement, or maintainability damage you
    would block a merge over — verbatim duplication of a logic block,
    swallowed errors, tests that assert nothing. **minor** — "coverage could
    be broader," polish, judgement-call smells with low blast radius.
    If the plan or brief explicitly mandates something this rubric calls a
    defect (a test that asserts nothing, verbatim duplication of a logic
    block), that IS a finding — report it as important, labeled
    plan-mandated in its summary. The plan's authorship does not grade its
    own work; the human decides.

    ## Verdict File — the gate

    Write EXACTLY this JSON shape to [VERDICT_FILE]:

    {
      "passes": false,
      "findings": [
        {
          "file": "src/example.ts",
          "line": 42,
          "severity": "critical" | "important" | "minor",
          "axis": "spec" | "standards",
          "summary": "one-sentence statement of the defect"
        }
      ],
      "cannot_verify": [
        "requirement you could not verify from the diff alone, and what the
         controller should check"
      ],
      "report": "[REVIEW_REPORT_FILE]"
    }

    `passes` is true ONLY when there are zero critical and zero important
    findings — minor findings do not block. A finding without a natural
    file:line anchor (a missing requirement) uses the most relevant file and
    line 0. Valid JSON, nothing after the closing brace — a script parses
    this file, not eyes.

    ## Prose Report — the payload

    Write the full report to [REVIEW_REPORT_FILE]:
    - Strengths: what's well done, specifically — accurate praise helps the
      implementer trust the rest.
    - Per finding: file:line, what's wrong, why it matters, how to fix (if
      not obvious).
    - Every check you ran outside the diff: the named risk and what you
      checked.
    - Every claim cites a line; a check you would otherwise answer with a
      bare "yes" cites its evidence too.

    Your final message is three lines: the verdict file path, the report
    file path, and the count (e.g. "passes:false — 1 critical, 2 important,
    3 minor"). No preamble, no process narration.
```

**Placeholders:**
- `[MODEL]` — REQUIRED: reviewer model per SKILL.md Model Selection
- `[BRIEF_FILE]` — REQUIRED: the task brief file (`scripts/task-brief PLAN N`
  prints the path; same file the implementer worked from)
- `[GLOBAL_CONSTRAINTS]` — the binding requirements copied verbatim from
  the plan's Global Constraints section or the spec: exact values, formats,
  and stated relationships between components (not process rules — those
  are already in this template)
- `[REPORT_FILE]` — REQUIRED: the file the implementer wrote its detailed
  report to
- `[BASE_SHA]` — commit before this task
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — REQUIRED: the path the controller wrote the review
  package to (`scripts/review-package BASE HEAD` prints the unique path it
  wrote; the package never enters the controller's context)
- `[STANDARDS_SOURCES]` — files in this repo documenting how code should be
  written (`CODING_STANDARDS.md`, `CONTRIBUTING.md`, …), or "none found"
- `[SMELL_BASELINE]` — the smell baseline pasted in full from the vendored
  code-review skill (../code-review/SKILL.md, step 3) — the reviewer has no
  other access to it; paste, never paraphrase
- `[VERDICT_FILE]` — REQUIRED: workspace path
  `verdict-<base7>..<head7>.json` (per range, so a re-review after fixes
  gets a distinct fresh file; `scripts/sdd-workspace` prints the directory)
- `[REVIEW_REPORT_FILE]` — REQUIRED: workspace path
  `review-<base7>..<head7>-report.md`

**Gate:** the controller runs `scripts/verdict-check VERDICT_FILE`. Exit 0 →
task passes, flip the ledger. Exit 1 → dispatch a fix subagent with the
findings and the prose report path; a fix dispatch addresses spec and
standards findings together, and re-review after fixes covers both axes with
a fresh verdict file. Exit 2 (malformed) → re-dispatch the reviewer; a
malformed verdict is never a pass.
