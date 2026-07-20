# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema execution/reproducibility validation context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add an `ExecutionReproducibilityValidation` owner-default entry point for
`execution_report.v1` and `monte_carlo_reproducibility_report.v1`. Derive
requirements from `ExecutionReproducibilityRegistryContracts`, route both
direct `Schema` clauses, and keep both contract APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,864 lines; the other
  targeted public facades are now 164 to 524 lines.
- The two adjacent clauses repeat required-field setup and form the exact family
  owned by `ExecutionReproducibilityRegistryContracts`.
- `ExecutionReportContracts` and `MonteCarloReproducibilityContracts` own all
  artifact-specific validation.
- Neither route needs callbacks, recursive `Schema` lookup, model limits, or
  facade-local context.
- `result_artifact.v1` remains out of scope because its nested execution-report
  callback is a distinct recursive boundary.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema validation/migration/lint operations context extraction, selected in
`3f36e8da` and implemented in `fdda4147`.
`schema.ex` moved from 4,888 to 4,864 lines.

Next candidate:
Implement and verify the selected execution/reproducibility validation context,
then re-rank the remaining Schema responsibility clusters.

Blocked:
No.
