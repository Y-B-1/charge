---
name: test-driven-development
description: >-
  Use when implementing any feature or bugfix, BEFORE writing implementation
  code. Enforces red-green-refactor: write one failing test, watch it fail for
  the right reason, write minimal code to pass, refactor while green.
  Exceptions (throwaway prototypes, generated code, config) require the
  human's explicit permission.
---

# Test-Driven Development

If you didn't watch the test fail, you don't know it tests the right thing.
**Iron Law:**

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? Delete it — not "keep as reference", not "adapt
while writing tests". Delete, then implement fresh from the test. Thinking
"skip TDD just this once" is the rationalization itself; exceptions only with
the human's permission.

## Red → Green → Refactor

- **RED:** one minimal test for one behavior, clear name, real code (mocks
  only when unavoidable — and read
  [testing-anti-patterns.md](testing-anti-patterns.md) first: testing the mock
  instead of the behavior is the classic failure).
- **Verify RED (mandatory, never skip):** run it; confirm it fails for the
  RIGHT reason (feature missing — not a typo/import error). Wrong failure →
  fix the test first.
- **GREEN:** minimal code to pass — no extras, no "while I'm here."
- **Verify GREEN:** the new test AND the full suite pass, output pristine
  (zero new warnings/errors).
- **REFACTOR:** clean up while staying green. Then next behavior.

## Bug fixing

Never fix a bug without a test: failing test reproduces it → TDD cycle → the
test proves the fix and blocks regression.

## Completion checklist

Every new function has a test · watched each fail for the expected reason ·
minimal code per test · all green · pristine output · real code over mocks ·
edge cases and errors covered. Can't tick all → you skipped TDD; start over.

## When stuck

Don't know how to test → write the wished-for API, assertion first, or ask.
Test too complicated → the design is; simplify the interface. Must mock
everything → too coupled; inject dependencies. Huge setup → extract helpers,
then simplify the design.
