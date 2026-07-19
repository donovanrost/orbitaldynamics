# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport provider-reservation handoff test family split.

Status:
Complete and published in `fc684963`.

Selected boundary:
Move the three contiguous candidate-refresh provider-reservation handoff tests
into one focused `cadence_import_provider_reservation_handoff_test.exs` module:
- provider-reservation request-summary handoff rows;
- station-reservation hold import-readiness handoff rows;
- wrapped station-reservation hold import-readiness rows.

Move the exclusively-owned pure `provider_reservation_request_summary/0` and
`station_reservation_hold_import_readiness_summary/0` fixture helpers with the
tests. Keep the preceding wrapped resource-projection test and following
standalone freshness/refresh-budget family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 14,046 lines and contains 86 top-level tests.
- The selected tests span lines 3,603 through 3,885 and cover request, readiness,
  and wrapped-readiness paths for one provider-reservation handoff
  responsibility.
- Repository-wide call search shows the two fixture helpers are called only by
  these three tests, so their ownership can move rather than be duplicated.
- The family uses only `CadenceImport` and `Schema`; it has no setup, external
  fixtures, or cross-test state.
- The tests preserve grouped reservation IDs, typed import routing, execution
  boundaries, nested source rows, and schema validation.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  fixture values, schema validation, and all other test families remain outside
  this ownership-only boundary.

Verification:
- The pre-move focused baseline passed all three selected tests from selection
  commit `9ae8d12b`.
- Strict test compilation passed with warnings as errors across 3,804 files.
- The new focused module passed 3 tests; the reduced original passed 83 tests;
  the six-file combined CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An exact AST comparison against `9ae8d12b` proved that the focused module owns
  the three exact test ASTs and both exact fixture-helper ASTs, while the original
  is exactly its former body minus those five expressions.
- Formatting, tracked and new-file diff checks, exact static test/helper counts,
  temporary-checker absence, and the resource-projection/freshness seam passed.
- Bounded local review found no assertion, fixture-value, production, public API,
  schema, deterministic-output, execution-boundary, or source-path change.
- The original ledger fell from 14,046 to 13,600 lines; the focused module is
  451 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport provider-reservation handoff test family split, selected in
`9ae8d12b` and implemented in `fc684963`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map, then
select another cohesive boundary with independent fixtures or exclusive helpers.

Blocked:
No.
