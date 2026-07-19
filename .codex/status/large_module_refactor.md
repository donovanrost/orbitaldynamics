# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation reduced-capacity packing extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract default capacity-requirement policy normalization, reduced-station
capacity group packing, fractional-fit decisions, row promotion/deferral, and
capacity-requirement evidence into
`OrbitalDynamics.Communications.ContactAllocation.CapacityPacking`.
Preserve the existing ContactAllocation public API facade.

Selection evidence:
- Live re-ranking places `contact_allocation.ex` at 3,593 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of
  RecommendationRiskContext, OrbitalDynamics, Manifest, LinkCapacity,
  StationCalendar, TimelineFeedback, and ResourceProjection.
- The selected family owns one deterministic allocation-policy responsibility:
  fitting contention-ordered contacts within declared reduced station capacity
  and recording the resulting row/group evidence.
- Contact normalization, station filtering, contention resolution, approval
  policy, provider counteroffers, report summaries, and returned-contact
  assembly remain outside this boundary.
- Existing option precedence and validation, contact ordering, fractional-fit
  tolerance, row status/reason transitions, evidence fields, omission behavior,
  and deterministic output remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback activity-state artifact extraction, selected in `3575f21a`
and implemented in `0e23963f`.
`timeline_feedback.ex` moved from 3,606 to 3,452 lines; the dedicated
activity-state owner is 183 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
