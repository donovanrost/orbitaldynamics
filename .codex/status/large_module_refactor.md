# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped provider-counteroffer test family split.

Status:
Complete and published in `4afdcafc`.

Selected boundary:
Move the two contiguous candidate-refresh provider-counteroffer wrapper tests
into one focused `cadence_import_wrapped_provider_counteroffer_test.exs` module:
- map-wrapped `provider_counteroffer_report.v1` import rows;
- list-wrapped `provider_counteroffer_report.v1` import rows.

Copy the pure `provider_counteroffer_report/0` fixture helper exactly into the
focused module while retaining it in the original module, where the standalone
provider-counteroffer test and supported-source fixture registry still call it.
Keep the preceding wrapped resource-filter test and following
provider-reservation request-summary family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 14,530 lines and contains 90 top-level tests.
- The selected family spans lines 3,959 through 4,086 and covers both supported
  candidate-refresh wrapper shapes for one provider-counteroffer responsibility.
- The tests use only `CadenceImport`, `Schema`, and one pure 21-line fixture
  builder; they have no setup, external fixtures, or cross-test state.
- The tests preserve source paths, typed review routing, counteroffer delta
  evidence, exact nested source rows, and schema validation.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  fixture values, schema validation, and all other test families remain outside
  this ownership-only boundary.

Verification:
- The pre-move focused baseline passed both selected tests from selection commit
  `b0e32756`.
- Strict test compilation passed with warnings as errors across 3,804 files.
- The new focused module passed 2 tests; the reduced original passed 88 tests;
  the four-file combined CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An exact AST comparison against `b0e32756` proved that the original is exactly
  its former body minus the two selected tests, the focused module owns those
  exact test ASTs, and `provider_counteroffer_report/0` is an exact helper copy.
- Formatting, tracked and new-file diff checks, exact static test/helper counts,
  temporary-checker absence, and the resource-filter/provider-reservation seam
  passed.
- Bounded local review found no assertion, fixture-value, production, public API,
  schema, deterministic-output, supported-source-registry, or source-path change.
- The original ledger fell from 14,530 to 14,402 lines; the focused module is
  155 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped provider-counteroffer test family split, selected in
`b0e32756` and implemented in `4afdcafc`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map, then
select another cohesive boundary with independent fixtures or a bounded helper
surface.

Blocked:
No.
