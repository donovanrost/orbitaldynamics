# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation general summary extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract normalized row aggregation, allocation/blocking/duplicate counts,
station-pressure grouping, capacity-pack rollups, reservation-expiration
rollups, review identity collection, and `contact_allocation_summary.v1`
artifact assembly into
`OrbitalDynamics.Communications.ContactAllocation.AllocationSummary`.
Preserve the existing ContactAllocation public API facade.

Selection evidence:
- Live re-ranking places `communications/contact_allocation.ex` at 3,308
  lines, fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  RecommendationRiskContext, TimelineFeedback, Manifest,
  OperationalReadiness, ContactContention, LinkCapacity, ResourceProjection,
  and StationCalendar.
- The selected family owns the general derived summary responsibility reached
  through `summary/1-3`; it consumes completed allocation rows and does not
  participate in allocation decisions.
- Contact normalization and validation, allocation execution, resource/station
  filtering, contention resolution, capacity packing, approval policy, and the
  station-pressure, capacity-pack, reservation-conflict, and provider-request
  specialized summaries remain outside this boundary.
- Existing row normalization, count/group semantics, reservation expiration
  rules, model limits, assumptions, omission behavior, and deterministic output
  remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar calendar-input normalization extraction, selected in
`8c62649c` and implemented in `31df3bf1`.
`communications/station_calendar.ex` moved from 3,346 to 2,981 lines; the
dedicated calendar-input owner is 449 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
