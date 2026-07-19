# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback throughput reconciliation ownership extraction.

Status:
Selected; implementation not started.

Selected boundary:
Move reconciliation throughput and data-volume evidence, denominator
selection, deltas, completion fractions, and required downlink assembly into
the existing `OrbitalDynamics.TimelineFeedback.Throughput` owner. Preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,099 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one planned-versus-realized
  throughput responsibility and depend only on planned and realized row maps.
- The fraction helper has no consumers outside this boundary. Generic delta
  math remains in the facade for thermal and maneuver comparisons, while
  maneuver evidence, success outcomes, execution uncertainty, operational-
  feedback exclusion, and report aggregation remain with their current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation timing-evidence extraction, selected in
`90ff1df4` and implemented in `c8ec267e`.
`timeline_feedback.ex` moved from 4,122 to 4,099 lines; the dedicated owner is
42 lines.

Next candidate:
Implement and verify the selected TimelineFeedback throughput reconciliation
ownership extraction.

Blocked:
No.
