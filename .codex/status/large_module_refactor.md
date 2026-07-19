# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport provider-reservation handoff test family split.

Status:
Selected; implementation has not started.

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
Pending: three-test focused baseline, mechanical AST-preserving test/helper move,
strict compile, focused new/original/combined CadenceImport tests, relevant
schema contracts, structural/static checks, and bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped suppression-report test family split, selected in
`0cb9a051` and implemented in `4fb90113`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map after
the provider-reservation handoff family and its exclusive helpers are isolated.

Blocked:
No.
