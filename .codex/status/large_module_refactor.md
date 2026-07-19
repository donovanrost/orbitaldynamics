# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-contention extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract provider-calendar pairwise station/direction/window conflict
detection, overlap identity/evidence, reservation/provider metadata, and
deterministic contention-group construction into
`OrbitalDynamics.Communications.StationCalendar.ProviderContention`.
Preserve the existing StationCalendar public API facade.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 3,487 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of TimelineFeedback,
  ResourceProjection, Manifest, ContactAllocation, RecommendationRiskContext,
  OperationalReadiness, and LinkCapacity.
- The selected family owns one independent review-evidence responsibility:
  detecting overlapping provider entries that compete for the same compatible
  station direction and producing deterministic contention groups.
- Provider artifact normalization, contact overlay/matching, reservation
  review/import summaries, approval policy, and counteroffer workflows remain
  outside this boundary.
- Existing pair ordering, command/uplink compatibility, open-window overlap
  behavior, group IDs, reservation/provider metadata, omission rules, and
  deterministic output remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
LinkCapacity relay data-path summary extraction, selected in `b3395bce` and
implemented in `2acd5177`.
`link_capacity.ex` moved from 3,520 to 3,113 lines; the dedicated relay
data-path owner is 506 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
