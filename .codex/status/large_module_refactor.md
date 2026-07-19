# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped station-report test family split.

Status:
Selected; implementation has not started.

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
Pending: two-test focused baseline, mechanical AST-preserving move, strict
compile, focused new/original/combined CadenceImport tests, relevant schema
contracts, structural/static checks, and bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport timeline-transition test family split, selected in `55413ac8` and
implemented in `8621886e`.

Next candidate:
Continue with another independently-fixtured CadenceImport responsibility or
return to production facade mapping after the wrapped station family is
isolated.

Blocked:
No.
