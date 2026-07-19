# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped timeline-guard test family split.

Status:
Complete and published in `726cdd8c`.

Selected boundary:
Move the two contiguous candidate-refresh timeline guard wrapper tests into one
focused `cadence_import_wrapped_timeline_guard_test.exs` module:
- wrapped `timeline_preservation_report.v1` import rows;
- wrapped `timeline_integrity_report.v1` import rows.

Copy the pure `timeline_preservation_report/0` and
`timeline_integrity_report/0` fixture helpers exactly into the focused module
while retaining them in the original module, where standalone import tests and
the supported-source fixture registry still call them. Keep the preceding
wrapped lifecycle-state test and following standalone freshness/refresh-budget
family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 13,062 lines and contains 79 top-level tests.
- The selected family spans lines 2,879 through 3,064 and covers preservation
  and dependency/exclusivity integrity as one timeline guard import boundary.
- The tests use only `CadenceImport`, `Schema`, `Timeline`, and two pure fixture
  builders;
  they have no setup, external fixtures, or cross-test state.
- Both helpers have other original callers, so copying their exact AST avoids
  changing standalone import and supported-source fixture paths.
- The tests preserve preservation decisions, invalid-input review, dependency
  and exclusivity issues, nested source rows, wrapper source paths, and schema
  validation.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  fixture values, schema validation, and all other test families remain outside
  this ownership-only boundary.

Verification:
- The pre-move focused baseline passed both selected tests from selection commit
  `d85b7417`.
- Strict test compilation passed with warnings as errors across 3,804 files.
- The new focused module passed 2 tests; the reduced original passed 77 tests;
  the nine-file combined CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An exact AST comparison against `d85b7417` proved that the original is exactly
  its former body minus the two selected tests, the focused module owns those
  exact test ASTs, and both timeline guard fixture helpers are exact copies.
- Formatting, tracked and new-file diff checks, exact static test/helper counts,
  temporary-checker absence, and the lifecycle-state/freshness seam passed.
- Bounded local review found no assertion, fixture-value, production, public API,
  schema, deterministic-output, preservation, integrity, or source-path change.
- The original ledger fell from 13,062 to 12,876 lines; the focused module is
  246 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped timeline-guard test family split, selected in `d85b7417`
and implemented in `726cdd8c`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map, then
select another cohesive boundary with independent fixtures or exclusive helpers.

Blocked:
No.
