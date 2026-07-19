# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped suppression-report test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the two contiguous candidate-refresh wrapped suppression report tests into
one focused `cadence_import_wrapped_suppression_reports_test.exs` module:
- wrapped `resource_filter_report.v1` import rows;
- wrapped `contact_filter_report.v1` import rows.

Keep the preceding wrapped resource-projection test and following
provider-reservation request-summary family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 14,402 lines and contains 88 top-level tests.
- The selected family spans lines 3,603 through 3,958 and covers both resource
  and contact candidate suppression as one typed import responsibility.
- Both tests build their fixtures inline and use only `CadenceImport` and
  `Schema`; they have no private helpers, setup, external fixtures, or
  cross-test state.
- The tests preserve invalid-input and suppression paths, policy evidence,
  typed review routing, nested source rows, and schema validation.
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
CadenceImport wrapped provider-counteroffer test family split, selected in
`b0e32756` and implemented in `4afdcafc`.

Next candidate:
Continue with another independently-fixtured CadenceImport responsibility or
return to production facade mapping after the suppression wrapper family is
isolated.

Blocked:
No.
