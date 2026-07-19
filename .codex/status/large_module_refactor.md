# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation throughput evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract explicit and data-rate-derived actual throughput, estimated throughput,
duration resolution, derivation metadata, and downlink-completion evidence into
`OrbitalDynamics.Communications.ContactAllocation.ThroughputEvidence`.
Preserve the existing ContactAllocation public API facade.

Selection evidence:
- Live re-ranking places `contact_allocation.ex` at 3,782 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of TimelineFeedback,
  RecommendationRiskContext, StationCalendar, LinkCapacity, and
  ResourceProjection.
- The selected helper family owns one contact throughput/downlink evidence
  responsibility used by invalid rows, base allocation rows, and provider
  contact detection.
- Capacity requirements, reduced-capacity packing, contact identity and input
  validation, station availability, contention, approval policy, and report
  aggregation remain outside this boundary.
- Existing public APIs, row fields, alias precedence, numeric-string
  acceptance, derivation formulas, omission behavior, and deterministic output
  remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar provider-counteroffer review summary extraction, selected in
`29995109` and implemented in `bea811b2`.
`station_calendar.ex` moved from 3,804 to 3,728 lines; the dedicated review
owner is 157 lines.

Next candidate:
Implement and verify the selected ContactAllocation throughput evidence
extraction.

Blocked:
No.
