# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext validation-refresh extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the validation-refresh context-key contract and deterministic
aggregation for model-acceptance, schema-validation, validation-safety-case,
refresh-budget, and refresh-freshness risks into
`OrbitalDynamics.RecommendationRiskContext.ValidationRefresh`.
Preserve the existing RecommendationRiskContext public API facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 3,582 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  OrbitalDynamics, Manifest, LinkCapacity, StationCalendar, TimelineFeedback,
  ResourceProjection, and ContactAllocation.
- The selected family owns one recommendation explanation responsibility:
  translating validation and refresh risk rows into the declared compact
  context vocabulary used by downstream recommendations.
- Approval, communications, timeline, resource, objective, and operational
  feedback context families remain outside this boundary.
- Existing risk matching, atom/string normalization, list flattening,
  deduplication, deterministic sorting, empty-value omission, invalid-input
  behavior, and public context-key ordering remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation reduced-capacity packing extraction, selected in `75c6e6fe`
and implemented in `54011624`.
`contact_allocation.ex` moved from 3,593 to 3,308 lines; the dedicated
capacity-packing owner is 304 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
