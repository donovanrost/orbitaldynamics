# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped link-capacity test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the two contiguous candidate-refresh link-capacity wrapper tests into one
focused `cadence_import_wrapped_link_capacity_test.exs` module:
- map-wrapped `link_capacity_report.v1` import rows;
- list-wrapped `link_capacity_report.v1` import rows.

Keep the preceding wrapped contact-allocation test and following wrapped
resource-projection test in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 13,600 lines and contains 83 top-level tests.
- The selected family spans lines 3,213 through 3,430 and covers both supported
  candidate-refresh wrapper shapes for one link-capacity import responsibility.
- Both tests build their fixtures inline and use only `CadenceImport` and
  `Schema`; they have no private helpers, setup, external fixtures, or
  cross-test state.
- The tests preserve selected/ignored contact evidence, planned and actual
  throughput/shortfall fields, policy evidence, wrapper-specific source paths,
  nested source rows, and schema validation.
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
CadenceImport provider-reservation handoff test family split, selected in
`9ae8d12b` and implemented in `fc684963`.

Next candidate:
Continue with another independently-fixtured CadenceImport responsibility or
return to production facade mapping after the link-capacity wrapper family is
isolated.

Blocked:
No.
