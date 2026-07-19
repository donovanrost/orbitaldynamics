# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped timeline-guard test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the two contiguous candidate-refresh timeline guard wrapper tests into one
focused `cadence_import_wrapped_timeline_guard_test.exs` module:
- wrapped `timeline_preservation_report.v1` import rows;
- wrapped `timeline_integrity_report.v1` import rows.

Copy the pure `timeline_preservation_report/0` and
`timeline_integrity_report/0` fixture helpers exactly into the focused module
while retaining them in the original module, where standalone import tests and
the supported-source fixture registry still call them. Keep the preceding
wrapped lifecycle-state test and following standalone freshness/refresh-budget
family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 13,062 lines and contains 79 top-level tests.
- The selected family spans lines 2,879 through 3,064 and covers preservation
  and dependency/exclusivity integrity as one timeline guard import boundary.
- The tests use only `CadenceImport`, `Schema`, `Timeline`, and two pure fixture
  builders;
  they have no setup, external fixtures, or cross-test state.
- Both helpers have other original callers, so copying their exact AST avoids
  changing standalone import and supported-source fixture paths.
- The tests preserve preservation decisions, invalid-input review, dependency
  and exclusivity issues, nested source rows, wrapper source paths, and schema
  validation.
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
CadenceImport wrapped resource-planning test family split, selected in
`fb14d011` and implemented in `b25a3817`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map after
the wrapped timeline-guard family is isolated.

Blocked:
No.
