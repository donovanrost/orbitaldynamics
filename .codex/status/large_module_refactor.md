# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped provider-counteroffer test family split.

Status:
Selected; implementation has not started.

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
Pending: two-test focused baseline, mechanical AST-preserving move, exact
fixture-helper copy proof, strict compile, focused new/original/combined
CadenceImport tests, relevant schema contracts, structural/static checks, and
bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped station-report test family split, selected in `5db1ed60`
and implemented in `92e43ac5`.

Next candidate:
Continue with another independently-fixtured CadenceImport responsibility or
return to production facade mapping after the provider-counteroffer wrapper
family is isolated.

Blocked:
No.
