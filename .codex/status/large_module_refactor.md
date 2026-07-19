# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext station-calendar context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract station-calendar risk recognition, the station-calendar context-key
catalog, and station-calendar context projection into
`OrbitalDynamics.RecommendationRiskContext.StationCalendar`.
Preserve the existing RecommendationRiskContext public API facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 3,293 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  TimelineFeedback, Manifest, OperationalReadiness, ContactContention,
  LinkCapacity, ContactAllocation, ResourceProjection, and StationCalendar.
- The selected family is one independent 47-field projection reached through
  `station_calendar_context_keys/0` and `station_calendar_context/1`; it owns
  only station-calendar risk recognition and deterministic context collection.
- Strategy recommendation assembly, Cadence import assembly, schema contracts,
  and every unrelated recommendation-risk context family remain outside this
  boundary.
- Existing atom/string key normalization, type/risk-type/feedback-scope
  recognition, list flattening, first-seen uniqueness, empty-field omission,
  invalid-input fallback, field names, and field order remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None planned. Existing risk recognition, key normalization, value flattening,
first-seen uniqueness, omission behavior, field catalog, artifact shape, and
deterministic output will be preserved.

Last completed slice:
ContactAllocation general summary extraction, selected in `de0dc8d8` and
implemented in `6c3d18c4`.
`communications/contact_allocation.ex` moved from 3,308 to 3,071 lines; the
dedicated allocation-summary owner is 710 lines.

Next candidate:
Implement and verify the selected station-calendar context extraction.

Blocked:
No.
