# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback outcome-value interpretation extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract contact, station-throughput, observation, image-quality, maneuver, and
command feedback value interpretation plus weighted-average semantics into
`OrbitalDynamics.TimelineFeedback.OutcomeValue`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,776 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of
  RecommendationRiskContext, StationCalendar, LinkCapacity,
  ResourceProjection, and ContactAllocation.
- The selected helper family owns one normalized-row outcome interpretation
  responsibility used by feedback aggregates and model updates.
- Reconciliation, matching, grouping, demand, resource, target-priority,
  uncertainty, and artifact assembly remain outside this boundary.
- Existing public APIs, fallback precedence, terminal-status semantics,
  weighting, clamping, omission behavior, and deterministic output remain
  unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation throughput evidence extraction, selected in `7873709f` and
implemented in `5232aaf7`.
`contact_allocation.ex` moved from 3,782 to 3,593 lines; the dedicated
throughput owner is 220 lines.

Next candidate:
Implement and verify the selected TimelineFeedback outcome-value
interpretation extraction.

Blocked:
No.
