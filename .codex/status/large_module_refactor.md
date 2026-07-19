# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext activity-lifecycle-state extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract timeline-activity lifecycle-state risk recognition, the ordered
context-key catalog, and lifecycle-state context projection into
`OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState`.
Preserve the existing RecommendationRiskContext public API facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 3,091 lines,
  seventh behind Schema, Timeline, MissionPlan.Activity, LinkCapacity,
  Manifest, and ContactContention and ahead of ContactAllocation,
  TimelineFeedback, ResourceProjection, StationCalendar, and
  OperationalReadiness.
- Higher-ranked LinkCapacity summary aggregation remains coupled to shared
  station-calendar normalization and reservation inference. The selected
  family is one closed 39-field projection reached through two stable facade
  calls.
- Timeline lifecycle artifact generation, recommendation assembly, Cadence
  import, replay summaries, schemas, and every unrelated risk-context family
  remain outside this boundary.
- Existing atom/string key normalization, type/feedback-scope recognition,
  list flattening, first-seen uniqueness, empty-field omission, invalid-input
  fallback, field order, and deterministic output remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None planned. Existing lifecycle-state risk recognition and context
projection, recommendation shape, schemas, and deterministic output will be
preserved.

Last completed slice:
ContactContention timing metrics extraction, selected in `ee124dce` and
implemented in `e03e56d2`.
`communications/contact_contention.ex` moved from 3,114 to 3,035 lines; the
dedicated timing-metrics owner is 91 lines.

Next candidate:
Implement and verify the selected activity-lifecycle-state extraction.

Blocked:
No.
