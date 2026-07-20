# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema maneuver decision-support owner routing extraction.

Status:
Completed and pushed.

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
Added registry-backed maneuver recommendation and review artifact entry points
to `DecisionSupportValidation` and routed both direct `Schema` clauses through
the existing owner. `schema.ex` moved from 4,745 to 4,741 lines.

Verification:
- Strict focused baseline: 21 tests passed.
- Focused plus adjacent maneuver, validation, operator-review, result-artifact,
  campaign-planner decision-support, contract, and export coverage after
  extraction: 41 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the two intended direct facade routes.
- `mix xref trace` confirmed both runtime calls originate in `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, owner-default
  model limits, maneuver recommendation/review contract routing, validation
  ordering, and paths remain unchanged.
- Implementation committed and pushed as `89ccd78e`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `DecisionSupportValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema maneuver decision-support owner routing extraction, selected in
`fa4dad79` and implemented in `89ccd78e`.
`schema.ex` moved from 4,745 to 4,741 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
