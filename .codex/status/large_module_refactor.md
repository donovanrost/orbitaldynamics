# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-counteroffer report projection extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract canonical provider-counteroffer report construction, row projection,
generated report identity, reviewability, preserved source entry, and numeric
report aggregates into
`OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReport`.
Preserve the existing StationCalendar public API facade.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 3,924 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  ResourceProjection, ContactAllocation, and TimelineFeedback.
- The selected helper family owns one `provider_counteroffer_report.v1`
  projection responsibility and consumes the dedicated normalization owner
  selected in the previous slice.
- Review, import-readiness, and plan-impact summary assembly remain in the
  facade as separate downstream artifact responsibilities.
- Calendar ingestion, station availability, reservations, contention,
  precedence, approval policy, and contact matching remain outside this
  boundary.
- Existing public APIs, normalized rows, report shapes, omission behavior, and
  deterministic ordering remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar provider-counteroffer normalization extraction, selected in
`a0dbc00c` and implemented in `46e8ddb5`.
`station_calendar.ex` moved from 4,012 to 3,924 lines; the dedicated owner is
195 lines.

Next candidate:
Implement and verify the selected StationCalendar provider-counteroffer report
projection extraction.

Blocked:
No.
