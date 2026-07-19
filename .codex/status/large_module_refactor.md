# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped timeline-summary test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the three contiguous candidate-refresh timeline summary wrapper tests into
one focused `cadence_import_wrapped_timeline_summaries_test.exs` module:
- wrapped `timeline_dependency_impact_summary.v1` import rows;
- wrapped `timeline_publication_summary.v1` import rows;
- wrapped `timeline_lifecycle_state_summary.v1` import rows.

Copy the three corresponding pure fixture helpers exactly into the focused
module while retaining them in the original module, where standalone import
tests and the supported-source fixture registry still call them. Keep the
preceding wrapped import-readiness quality-gate test and following standalone
freshness/refresh-budget family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 12,876 lines and contains 77 top-level tests.
- The selected family spans lines 2,611 through 2,878 and covers dependency
  impact, publication invalidation, and lifecycle review as one timeline summary
  handoff boundary.
- The tests use only `CadenceImport`, `Schema`, `Timeline`, and three pure fixture
  builders;
  they have no setup, external fixtures, or cross-test state.
- All three helpers have other original callers, so copying their exact AST avoids
  changing standalone import and supported-source fixture paths.
- The tests preserve dependency-impact scopes, downstream invalidation evidence,
  lifecycle transitions, nested source rows, wrapper source paths, and schema
  validation.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  fixture values, schema validation, and all other test families remain outside
  this ownership-only boundary.

Verification:
Pending: three-test focused baseline, mechanical AST-preserving move, exact
fixture-helper copy proof, strict compile, focused new/original/combined
CadenceImport tests, relevant schema contracts, structural/static checks, and
bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped timeline-guard test family split, selected in `d85b7417`
and implemented in `726cdd8c`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map after
the wrapped timeline-summary family is isolated.

Blocked:
No.
