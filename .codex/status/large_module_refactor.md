# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-counteroffer review summary extraction.

Status:
Completed and pushed in `bea811b2`.

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
- Strict test-environment compile passed with warnings as errors across 3,911
  files.
- Focused StationCalendar coverage passed: 42 tests.
- Adjacent operator-review, schema-contract, and wrapped Cadence-import
  counteroffer coverage passed: 5 tests.
- Exact public old/new comparison against selection commit `29995109` passed
  for eight artifacts covering canonical report projection, review summary,
  deadline classification, import readiness, and plan impact.
- `mix xref callers` reports only the StationCalendar facade as a runtime
  caller of the extracted review owner.
- Static ownership checks confirm review-summary construction and lock-deadline
  classification live in the dedicated owner while import-readiness and
  plan-impact assembly remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar provider-counteroffer review summary extraction, selected in
`29995109` and implemented in `bea811b2`.
`station_calendar.ex` moved from 3,804 to 3,728 lines; the dedicated review
owner is 157 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
