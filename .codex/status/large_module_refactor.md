# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation timing-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract planned/actual timing fields, start/end deltas, maximum absolute
variance, threshold projection, and timing status into
`OrbitalDynamics.TimelineFeedback.ReconciliationTimingEvidence`. Preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,122 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one planned-versus-realized
  timing-variance responsibility and depend only on the planned and realized
  row maps plus the public reconciliation threshold option.
- Generic delta math remains in the facade for throughput and maneuver
  comparisons. Identity, observation, communications, resource and
  station-calendar evidence, success outcomes, execution uncertainty,
  operational-feedback exclusion, and report aggregation remain with their
  current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation station-calendar-evidence extraction, selected
in `03b80371` and implemented in `9cebb4bf`.
`timeline_feedback.ex` moved from 4,180 to 4,122 lines; the dedicated owner is
51 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation
timing-evidence extraction.

Blocked:
No.
