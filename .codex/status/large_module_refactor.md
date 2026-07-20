# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-activity-precondition extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract timeline-activity-precondition context keys, risk selection, context
value projection, deduplication, and omission behavior into
`OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition`.
Preserve all RecommendationRiskContext public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,893 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext already delegates thirteen focused contexts,
  including timeline activity lifecycle state, while timeline activity
  preconditions remain inline at lines 144-172 and 954-1,047.
- The selected block has one responsibility: collect timeline activity
  precondition review evidence into its public risk-context map.
- Other recommendation risk domains, common facade helpers, and all public
  contracts remain outside the boundary.
- Exact atom-key normalization, risk selection, scalar/list collection,
  encounter-order deduplication, empty-field omission, public output, and
  non-list fallback behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ContactFilter station-state resolution extraction, selected in `3d523698` and
implemented in `bc495074`.
`contact_filter.ex` moved from 1,898 to 1,365 lines; the dedicated StationState
owner is 633 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `recommendation_risk_context.ex` is now the largest ordinary
eligible facade at 1,893 lines, followed by OrbitData and StationCalendar.

Blocked:
No.
