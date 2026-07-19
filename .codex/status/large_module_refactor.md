# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped link-capacity test family split.

Status:
Complete and published in `55ab3fdb`.

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
- The pre-move focused baseline passed both selected tests from selection commit
  `329cc431`.
- Strict test compilation passed with warnings as errors across 3,804 files.
- The new focused module passed 2 tests; the reduced original passed 81 tests;
  the seven-file combined CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An exact AST comparison against `329cc431` proved that the new module contains
  only `use`, the `CadenceImport`/`Schema` alias, and the two selected test ASTs,
  while the original is exactly its former body minus those tests.
- Formatting, tracked and new-file diff checks, exact static test counts,
  temporary-checker absence, and the contact-allocation/resource-projection seam
  passed.
- Bounded local review found no assertion, fixture-value, production, public API,
  schema, deterministic-output, policy-evidence, throughput, or source-path
  change.
- The original ledger fell from 13,600 to 13,382 lines; the focused module is
  223 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped link-capacity test family split, selected in `329cc431` and
implemented in `55ab3fdb`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map, then
select another cohesive boundary with independent fixtures or exclusive helpers.

Blocked:
No.
