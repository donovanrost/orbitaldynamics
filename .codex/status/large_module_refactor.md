# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback link context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract link protocol, RF configuration, data rate, link-quality measurements,
lock flags, and link-quality status projection into
`OrbitalDynamics.TimelineFeedback.LinkContext`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,268 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  OperationalReadiness, ContactContention, LinkCapacity,
  RecommendationRiskContext, ContactAllocation, ResourceProjection, and
  StationCalendar.
- The selected family is one independent 15-field projection merged into both
  planned and realized feedback rows; it owns link-value path precedence and
  artifact normalization but not reconciliation or feedback aggregation.
- Throughput derivation remains owned by the existing
  `TimelineFeedback.Throughput` module. Planned/realized row assembly, station
  calendar, resource, pointing, attitude, command-authority, lighting,
  observation-quality, and thermal contexts remain outside this boundary.
- Existing top-level/nested/metadata path precedence, atom/string scalar
  normalization, numeric and boolean parsing, omission behavior, row shape,
  and deterministic output remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None planned. Existing link-value precedence and normalization, omission
behavior, feedback-row shape, artifact contracts, and deterministic output will
be preserved.

Last completed slice:
RecommendationRiskContext station-calendar context extraction, selected in
`3dbc476a` and implemented in `065a1b48`.
`recommendation_risk_context.ex` moved from 3,293 to 3,091 lines; the dedicated
station-calendar context owner is 147 lines.

Next candidate:
Implement and verify the selected link-context extraction.

Blocked:
No.
