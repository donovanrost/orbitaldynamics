# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention timing metrics extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract interval validation, contention-window duration, summed contact
duration, union overlap duration, maximum concurrency, and overlapping-pair
count into `OrbitalDynamics.Communications.ContactContention.TimingMetrics`.
Preserve the existing ContactContention public API facade.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 3,114
  lines, fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  LinkCapacity, Manifest, RecommendationRiskContext, ContactAllocation,
  TimelineFeedback, ResourceProjection, StationCalendar, and
  OperationalReadiness.
- The selected family is one independent five-field projection merged into
  both ground-station and spacecraft contention groups; it owns only interval
  arithmetic and not grouping or recommendation decisions.
- Contact normalization, identity validation, group formation, station
  calendar and feedback context, capacity inference, approval policy, and
  resolution policy remain outside this boundary.
- Existing invalid-interval omission, half-open overlap semantics,
  same-timestamp event coalescing, duration arithmetic, pair counting, empty
  output behavior, and deterministic output remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None planned. Existing timing arithmetic, contention-group shape, artifact
contracts, and deterministic output will be preserved.

Last completed slice:
TimelineFeedback thermal context extraction, selected in `4ccc5828` and
implemented in `c3190551`.
`timeline_feedback.ex` moved from 3,153 to 3,061 lines; the dedicated thermal
context owner is 113 lines.

Next candidate:
Implement and verify the selected timing-metrics extraction.

Blocked:
No.
