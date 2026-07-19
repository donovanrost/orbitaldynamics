# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped station-report test family split.

Status:
Complete and published in `92e43ac5`.

Selected boundary:
Move the two contiguous candidate-refresh wrapped station report tests into one
focused `cadence_import_wrapped_station_reports_test.exs` module:
- wrapped `station_calendar_report.v1` import rows;
- wrapped `station_reservation_report.v1` import rows.

Keep the preceding list-wrapped provider-counteroffer test and following
provider-reservation request-summary family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 14,831 lines and contains 92 top-level tests.
- The selected family spans lines 4,087 through 4,387 and covers the two wrapped
  station-scheduling report types as one import responsibility.
- Both tests build their data inline and use only `CadenceImport` and `Schema`;
  they have no private helpers, setup, external fixtures, or cross-test state.
- The tests preserve affected-contact and provider-contention paths, source
  evidence, typed review routing, and schema validation.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  fixture values, schema validation, and all other test families remain outside
  this ownership-only boundary.

Verification:
- The pre-move focused baseline passed both selected tests from selection commit
  `5db1ed60`.
- Strict test compilation passed with warnings as errors across 3,804 files.
- The new focused module passed 2 tests; the reduced original passed 90 tests;
  the three-file combined CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An exact AST comparison against `5db1ed60` proved that the new module contains
  only `use`, the `CadenceImport`/`Schema` alias, and the two selected test ASTs,
  while the original is exactly its former body minus those tests.
- Formatting, tracked and new-file diff checks, exact static test counts,
  temporary-checker absence, and the provider-counteroffer/provider-reservation
  seam passed.
- Bounded local review found no assertion, fixture-value, production, public API,
  schema, deterministic-output, or source-path change.
- The original ledger fell from 14,831 to 14,530 lines; the focused module is
  306 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped station-report test family split, selected in `5db1ed60`
and implemented in `92e43ac5`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map, then
select another cohesive boundary with independent fixtures or a bounded helper
surface.

Blocked:
No.
