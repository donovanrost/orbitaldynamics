# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state test family split.

Status:
Completed and published.

Selected boundary:
Move the seven contiguous lifecycle-state tests from reusable status/approval
transition helpers through lifecycle-state summary into one focused
`timeline_lifecycle_state_test.exs` module. Keep transition-decision and
transition-application tests in the original ledger.

Selection evidence:
- The selected seven tests are one contiguous lifecycle-state family covering
  transition construction, safe application, selected-integrity gating,
  status/approval state artifacts, combined lifecycle state, and summary
  aggregation.
- The family is self-contained: it uses only `Timeline` and `Schema`, with no
  private test helpers, setup, fixtures, or cross-test state.
- The next test begins the distinct reusable transition-decision/application
  family and remains in the original module.
- The current test ledger is 12,901 lines; the selected family spans about 1,337
  lines.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  schema validation, and all other test families remain outside the boundary.

Verification:
- Focused baseline passed the seven selected tests.
- Strict warnings-as-errors compile passed 3,804 modules.
- Focused lifecycle-state test module passed 7 tests.
- Reduced original Timeline test module passed 120 tests.
- Combined Timeline test modules passed 127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved all seven test bodies moved exactly and the other 120
  tests remained unchanged.
- Static checks confirmed the focused module has exactly seven tests, no private
  helpers, only its required aliases, formatting/diff/new-file checks pass, and
  no temporary extraction/checker remains.
- Bounded local review found no correctness or maintainability issues and
  confirmed the original family boundary now runs directly from source-window
  coverage into transition-decision coverage.
- The original test ledger decreased from 12,901 to 11,564 lines; the focused
  lifecycle-state module is 1,342 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
Timeline lifecycle-state test family split, selected in `274208f4` and
implemented in `047b6b90`.

Next candidate:
Continue matching large Timeline test families to the extracted production
boundaries, then return to production facade mapping.

Blocked:
No.
