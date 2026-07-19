# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped specialized quality-gate test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the two contiguous candidate-refresh specialized quality-gate wrapper tests
into one focused `cadence_import_wrapped_specialized_quality_gates_test.exs`
module:
- wrapped operator-training and schema-validation quality-gate summaries;
- wrapped import-readiness quality-gate summary.

Move the three corresponding pure summary fixture helpers into the focused
module. Keep the preceding wrapped operational import-eligibility test and
following standalone freshness/refresh-budget family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 12,608 lines and contains 74 top-level tests.
- The selected family spans lines 2,349 through 2,610 and covers operator
  training, schema validation, and import readiness as one specialized
  quality-gate handoff boundary.
- The tests use only `CadenceImport`, `Schema`, and three pure map fixture
  builders;
  they have no setup, external fixtures, or cross-test state.
- A post-move warnings-as-errors run proved all three helpers would be unused in
  the original module; repository-wide call search confirms the selected tests
  are their only callers, so their ownership moves rather than being duplicated.
- The tests preserve training requirements, schema failure counts, import
  readiness counts, nested source rows, wrapper source paths, and schema
  validation.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  fixture values, schema validation, and all other test families remain outside
  this ownership-only boundary.

Verification:
Pending: two-test focused baseline, mechanical AST-preserving test/helper move,
strict compile, focused new/original/combined
CadenceImport tests, relevant schema contracts, structural/static checks, and
bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped timeline-summary test family split, selected in `a6c6afcf`
and implemented in `9476ac96`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map after
the specialized quality-gate wrapper family is isolated.

Blocked:
No.
