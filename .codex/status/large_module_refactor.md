# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation general summary extraction.

Status:
Completed and pushed.

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
- Focused baseline before implementation:
  `test/orbital_dynamics/communications/contact_allocation_test.exs` passed
  70 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,934 files successfully.
- Focused regression:
  `test/orbital_dynamics/communications/contact_allocation_test.exs` passed
  70 tests.
- Adjacent regressions:
  `test/orbital_dynamics/operator_review/contact_allocation_test.exs` passed
  11 tests and
  `test/orbital_dynamics/campaign_planner/repair_contact_allocation_contention_test.exs`
  passed 1 test.
- Exact old/new comparison against selection commit `de0dc8d8` covered six
  allocation-report states with and without `now_s`; all 12 summary outputs
  matched exactly.
- The exact states covered empty and allocated rows, policy blocking,
  invalid/status/resource/duplicate blocking, station pressure, capacity
  packing, trust counts, and active/missing reservation expiration.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Communications.ContactAllocation.AllocationSummary` reports
  only the ContactAllocation facade as a runtime caller; compile-connected xref
  reports no unexpected coupling.
- Static review confirmed the owner exposes only `build/4`; allocation
  execution and the station-pressure, capacity-pack, reservation-conflict, and
  provider-request specialized summaries remain in the facade.

Behavior/schema changes:
None. Existing row normalization, count/group semantics, reservation
expiration rules, model limits, assumptions, omission behavior, artifact
shape, and deterministic output are preserved.

Last completed slice:
ContactAllocation general summary extraction, selected in `de0dc8d8` and
implemented in `6c3d18c4`.
`communications/contact_allocation.ex` moved from 3,308 to 3,071 lines; the
dedicated allocation-summary owner is 710 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
