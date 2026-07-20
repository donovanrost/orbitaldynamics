# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema decision-support owner completion.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `DecisionSupportValidation` APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema station-calendar owner routing extraction, selected in `49ca11aa` and
implemented in `6fd05694`.
`schema.ex` moved from 4,771 to 4,761 lines.

Next candidate:
Implement and verify the selected decision-support owner completion, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.
