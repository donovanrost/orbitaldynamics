# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema decision-support owner completion.

Status:
Completed and pushed.

Selected boundary:
Add registry-backed `DecisionSupportValidation` entry points for
`pareto_frontier_report.v1` and `constraint_report.v1`, route both direct
`Schema` clauses through the existing owner, and preserve every existing owner
API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,761 lines; the other
  targeted public facades are now 164 to 524 lines.
- `DecisionSupportValidation` already owns three of four
  `ObjectiveAnalysisRegistryContracts` artifacts and three of four
  `OptimizationRegistryContracts` artifacts.
- Pareto frontier and constraint report are the only remaining members of those
  two registry families and repeat required-field setup in the facade.
- `ParetoFrontierContracts` and `ConstraintReportContracts` own all
  artifact-specific validation.
- No route needs recursive `Schema` lookup.

Implementation:
Added registry-backed pareto-frontier and constraint-report entry points to
`DecisionSupportValidation` and routed both direct `Schema` clauses through the
existing owner. `schema.ex` moved from 4,761 to 4,751 lines.

Verification:
- Strict focused baseline: 29 tests passed.
- Focused plus adjacent optimizer, validation, operator-review,
  candidate-refresh replay, campaign-planner source/pressure, result-artifact,
  contract, and export coverage after extraction: 55 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the two intended direct facade routes.
- `mix xref trace` confirmed both runtime calls originate in `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, pareto/constraint
  contract routing, validation ordering, and paths remain unchanged.
- Implementation committed and pushed as `62d2790e`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `DecisionSupportValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema decision-support owner completion, selected in `d817a431` and
implemented in `62d2790e`.
`schema.ex` moved from 4,761 to 4,751 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
