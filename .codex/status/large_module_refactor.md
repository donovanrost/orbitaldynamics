# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema execution/reproducibility validation context extraction.

Status:
Completed and pushed.

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
Added `ExecutionReproducibilityValidation` as the registry-backed family owner
for the two selected artifacts and routed their direct `Schema` validation
clauses through it. `schema.ex` moved from 4,864 to 4,860 lines.

Verification:
- Strict focused baseline: 26 tests passed.
- Focused plus adjacent validation and export coverage after extraction:
  39 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the two intended direct facade routes.
- `mix xref trace` confirmed both runtime calls originate in `schema.ex`; a
  bounded production search found no other owner callers.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,081 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, contract routing,
  validation ordering, and validation paths remain unchanged.
- Implementation committed and pushed as `090c4b43`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema execution/reproducibility validation context extraction, selected in
`2564cb45` and implemented in `090c4b43`.
`schema.ex` moved from 4,864 to 4,860 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
