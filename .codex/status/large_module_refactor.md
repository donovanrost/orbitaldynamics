# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection activity delivery evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract collection/delivery timestamps, planned and actual latency, latency
requirement margin and status, basis selection, and normalized completion
fraction into `OrbitalDynamics.ResourceProjection.ActivityDeliveryEvidence`.
Preserve the existing ResourceProjection public API facade.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,827 lines, fourth
  behind Schema, Timeline, and MissionPlan.Activity and ahead of
  StationCalendar, ContactAllocation, TimelineFeedback, and
  RecommendationRiskContext.
- The selected helper family owns one activity delivery/progress evidence
  responsibility used during resource-flow row projection.
- Resource flow roll-forward, pressure classification, approval policy,
  contact allocation, station-capacity evidence, and report aggregation remain
  outside this boundary.
- Existing public APIs, row fields, numeric-string acceptance, omission
  behavior, ordering, and report/schema artifacts remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Manifest ground-track crossing input extraction, selected in `294e8ca0` and
implemented in `03ef30f0`.
`manifest.ex` moved from 3,836 to 3,638 lines; the dedicated input owner is 215
lines.

Next candidate:
Implement and verify the selected ResourceProjection activity delivery
evidence extraction.

Blocked:
No.
