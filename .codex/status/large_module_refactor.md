# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-counteroffer review summary extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract `provider_counteroffer_review_summary.v1` construction and shared
counteroffer lock-deadline classification into
`OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReviewSummary`.
Preserve the existing StationCalendar public API facade.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 3,804 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of ContactAllocation,
  TimelineFeedback, RecommendationRiskContext, LinkCapacity, and
  ResourceProjection.
- The selected helper family owns one review-summary artifact plus the
  deadline classification used by downstream counteroffer summaries.
- Canonical counteroffer report projection remains in its dedicated owner;
  import-readiness and plan-impact summary assembly remain in the facade.
- Calendar ingestion, availability, reservation, contention, precedence,
  approval policy, and contact matching remain outside this boundary.
- Existing public APIs, review rows, deadline status, counts, routing ID sets,
  omission behavior, and deterministic ordering remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ResourceProjection activity delivery evidence extraction, selected in
`299d93df` and implemented in `d80e997a`.
`resource_projection.ex` moved from 3,827 to 3,720 lines; the dedicated
evidence owner is 117 lines.

Next candidate:
Implement and verify the selected StationCalendar provider-counteroffer review
summary extraction.

Blocked:
No.
