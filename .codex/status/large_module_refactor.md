# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation specialized-summary ownership extraction.

Status:
Selected; implementation not started.

Selected boundary:
Move the station-pressure, capacity-pack, reservation-conflict, and provider
reservation-request summary builders into the existing
`OrbitalDynamics.Communications.ContactAllocation.AllocationSummary` owner.
Remove the facade's duplicate summary aggregation helpers while preserving all
existing `ContactAllocation` public summary clauses as compatibility delegates.

Selection evidence:
- Live re-ranking places `communications/contact_allocation.ex` at 3,071 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  TimelineFeedback, ContactContention, LinkCapacity, ResourceProjection,
  Manifest, StationCalendar, OrbitalDynamics, RecommendationRiskContext, and
  OperationalReadiness.
- The four private builders and their aggregation helpers form one closed
  summary responsibility from lines 1,149-1,843. Their normalization, status,
  ID grouping, capacity-total, station-pressure, reservation-expiration, and
  deterministic ordering helpers already exist in the extracted
  `AllocationSummary` owner because the general summary uses the same rules.
- The facade's public input-shape clauses, report construction, allocation
  pipeline, capabilities, contact validation, resource/status filtering,
  capacity packing, provider counteroffer handling, and returned-contact
  assembly remain outside this boundary.
- Existing schema contracts, option handling (including reservation-conflict
  `:now_s`), capability assumptions, model limits, row selection, identifier
  grouping, ordering, numeric normalization, and artifact-only execution
  boundary must remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity station-capacity evidence extraction, selected in `df538ba1` and
implemented in `638f1592`.
`communications/link_capacity.ex` moved from 3,113 to 3,016 lines; the
dedicated station-capacity owner is 121 lines.

Next candidate:
Implement and verify the selected ContactAllocation specialized-summary
ownership extraction.

Blocked:
No.
