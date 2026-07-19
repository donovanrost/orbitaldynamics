# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection test family split.

Status:
Complete and published in `39e58a20`.

Selected boundary:
Move the three contiguous candidate-rejection tests into one focused
`timeline_candidate_rejection_test.exs` module. Keep the preceding public-facade
smoke test and following timeline-diff family in the original ledger.

Selection evidence:
- The selected tests cover declared/derived rejection evidence plus nested
  station-calendar capacity and availability derivation as one complete family.
- The family is self-contained: it uses only `Timeline` and `Schema`, with no
  private helpers, setup, fixture files, or cross-test state.
- The preceding test is a general facade smoke test; the following test begins
  the distinct timeline-diff report family.
- The current original test ledger is 10,234 lines; the selected family spans
  about 253 lines.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  schema validation, and all other test families remain outside the boundary.

Verification:
- The pre-move focused baseline passed all three selected tests from selection
  commit `96f62b40`.
- Strict test compilation passed with warnings as errors across 3,804 files.
- The new focused module passed 3 tests; the reduced original passed 109 tests;
  the four-file combined Timeline proof passed all 127 tests.
- The four Timeline schema contract files passed all 36 tests.
- An exact AST comparison against `96f62b40` proved that the new module contains
  only `use`, the `Schema`/`Timeline` alias, and the three selected test ASTs,
  while the original module is exactly its former body minus those tests.
- Formatting, tracked and new-file diff checks, exact static test counts,
  temporary-checker absence, and the public-facade/timeline-diff seam passed.
- Bounded local review found no assertion, helper, fixture, production, public
  API, schema, or deterministic-output change.
- The original ledger fell from 10,234 to 9,981 lines; the focused module is
  258 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
Timeline candidate-rejection test family split, selected in `96f62b40` and
implemented in `39e58a20`.

Next candidate:
Refresh the live hotspot inventory and choose between a responsibility-focused
production facade extraction and the larger CadenceImport test ledger. Do not
isolate the remaining single public-facade smoke test merely for line count.

Blocked:
No.
