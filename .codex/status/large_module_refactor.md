# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OrbitalDynamics activity-template catalog extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the baseline activity-template specifications, catalog capabilities,
artifact construction, lookup, override validation, normalized activity
instantiation, and template provenance into
`OrbitalDynamics.ActivityTemplateCatalog`.
Preserve the existing `OrbitalDynamics` public API facade.

Selection evidence:
- Live re-ranking places `orbital_dynamics.ex` at 3,572 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  LinkCapacity, StationCalendar, TimelineFeedback, ResourceProjection,
  ContactAllocation, and RecommendationRiskContext.
- The selected family is the root facade's only substantial private domain
  responsibility: owning the reusable baseline planning activity-template
  catalog and converting templates into normalized timeline activities.
- Capability catalog assembly and all propagation, planning, operations,
  review, import, readiness, validation, and reporting facades remain outside
  this boundary.
- Existing template vocabulary and ordering, lookup behavior, validation/error
  shapes, lifecycle/default merge precedence, provenance, normalization, and
  public return values remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
RecommendationRiskContext validation-refresh extraction, selected in
`bbc28b0e` and implemented in `cfae3494`.
`recommendation_risk_context.ex` moved from 3,582 to 3,293 lines; the dedicated
validation-refresh owner is 170 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
