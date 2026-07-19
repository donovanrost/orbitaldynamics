# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport wrapped resource-planning test family split.

Status:
Complete and published in `b25a3817`.

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
- The pre-move focused baseline passed both selected tests from selection commit
  `fb14d011`.
- Strict test compilation passed with warnings as errors across 3,804 files.
- The new focused module passed 2 tests; the reduced original passed 79 tests;
  the eight-file combined CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An exact AST comparison against `fb14d011` proved that the original is exactly
  its former body minus the two selected tests, the focused module owns those
  exact test ASTs, and `resource_projection_flow_summary/0` is an exact helper
  copy.
- Formatting, tracked and new-file diff checks, exact static test/helper counts,
  temporary-checker absence, and the timeline-integrity/freshness seam passed.
- Bounded local review found no assertion, fixture-value, production, public API,
  schema, deterministic-output, policy-evidence, resource-flow, or source-path
  change.
- The original ledger fell from 13,382 to 13,062 lines; the focused module is
  362 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped resource-planning test family split, selected in
`fb14d011` and implemented in `b25a3817`.

Next candidate:
Refresh the reduced CadenceImport family seams and production facade map, then
select another cohesive boundary with independent fixtures or exclusive helpers.

Blocked:
No.
