# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema maneuver decision-support owner routing extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add registry-backed artifact entry points to `DecisionSupportValidation` for
`maneuver_recommendation.v1` and `maneuver_review_report.v1`. Derive
requirements from `StrategyManeuverRegistryContracts`, route both direct
`Schema` clauses through the existing owner, and preserve every existing owner
API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,745 lines; the other
  targeted public facades are now 164 to 524 lines.
- Both clauses repeat required-field setup before delegating to
  `DecisionSupportValidation`.
- `StrategyManeuverRegistryContracts` owns both requirement sets.
- The owner already owns maneuver recommendation and review model-limit
  defaults and contract routing.
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
Schema campaign branch/recommendation owner routing extraction, selected in
`215d1587` and implemented in `b2dfd904`.
`schema.ex` moved from 4,751 to 4,745 lines.

Next candidate:
Implement and verify the selected maneuver decision-support owner routing, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.
