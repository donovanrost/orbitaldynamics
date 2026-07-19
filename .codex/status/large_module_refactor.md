# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped resource-planning test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the two now-contiguous candidate-refresh resource-planning wrapper tests
into one focused `cadence_import_wrapped_resource_planning_test.exs` module:
- wrapped `contact_allocation_report.v1` import rows;
- wrapped `resource_projection_report.v1` plus
  `resource_projection_flow_summary.v1` import rows.

Copy the pure `resource_projection_flow_summary/0` fixture helper exactly into
the focused module while retaining it in the original module, where its
standalone import test and supported-source fixture registry still call it.
Keep the preceding timeline-integrity wrapper test and following standalone
freshness/refresh-budget family in the original ledger.

Selection evidence:
- After the prior split, `cadence_import_test.exs` remains the repository's
  largest source file at 13,382 lines and contains 81 top-level tests.
- The selected family spans lines 3,065 through 3,384 and covers allocation,
  reduced-capacity packing, projected spacecraft resources, and correlated
  resource-flow summary handoff as one resource-planning import boundary.
- The tests use only `CadenceImport`, `Schema`, and one pure fixture builder;
  they have no setup, external fixtures, or cross-test state.
- The helper has three original callers, so copying its exact AST avoids
  changing the standalone import and supported-source fixture paths.
- The tests preserve capacity-pack, resource-pressure, policy, nested source,
  wrapper source-path, and schema-validation evidence.
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
CadenceImport wrapped link-capacity test family split, selected in `329cc431` and
implemented in `55ab3fdb`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map after
the wrapped resource-planning family is isolated.

Blocked:
No.
