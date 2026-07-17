---
name: verification-before-completion
description: >-
  Use when about to claim work is complete, fixed, or passing — before any
  commit, PR, "done", or expression of satisfaction. Requires running the full
  verification command fresh and reading its output before making any success
  claim. Evidence before assertions, always; a previous run, "should pass", or
  a subagent's success report never counts.
---

# Verification Before Completion

Claiming completion without verification is dishonesty, not efficiency.
**Iron Law:**

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

Violating the letter of this rule is violating its spirit. If you haven't run
the command in THIS message, you cannot claim it passes.

## The Gate (before any status claim or satisfaction)

1. **IDENTIFY** the command that proves the claim.
2. **RUN** it — fresh, complete, now.
3. **READ** the full output: exit code, failure count.
4. **VERIFY** it confirms the claim. No → state the actual status with
   evidence. Yes → state the claim WITH the evidence pasted.
5. Only then claim. Skipping any step = lying, not verifying.

## What each claim requires

| Claim | Requires | Not sufficient |
| --- | --- | --- |
| Tests pass | test command output: 0 failures | previous run, "should pass" |
| Lint clean | linter output: 0 errors | partial check |
| Build succeeds | build exit 0 | lint passing, "logs look good" |
| Bug fixed | original symptom's test passes | code changed, assumed fixed |
| Agent completed | the VCS diff + your own run | agent reports "success" |
| Requirements met | line-by-line checklist | tests passing |

## Red flags — stop

"Should/probably/seems to" · satisfaction before verification ("Great!",
"Done!") · about to commit/push/PR unverified · trusting agent reports ·
partial verification · "just this once" · tired and wanting it over.

| Excuse | Reality |
| --- | --- |
| "Should work now" | RUN the verification. |
| "I'm confident" | Confidence ≠ evidence. |
| "Linter passed" | Linter ≠ compiler ≠ tests. |

In the autonomy suite this gate is enforced mechanically: loop's independent
checker and Stop-hook wiring refuse a stop without surfaced evidence.
