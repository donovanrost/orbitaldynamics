# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation plan-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract planned dependency/exclusivity, Cadence import, operator-action,
timeline-integrity, and invalid-input evidence projection into
`OrbitalDynamics.TimelineFeedback.ReconciliationPlanEvidence`. Preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,894 lines, ahead of
  Manifest and ContactAllocation and behind the three larger
  orchestration-heavy facades.
- The selected 27 output fields form one planned-governance evidence
  projection and depend only on the normalized planned row.
- Matching, lifecycle/protection decisions, source contexts, realized
  evidence, and report aggregation remain in the facade or their current
  owners.
- Four operator-action output names are intentional projections and remain
  explicitly mapped in the new owner.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback maneuver reconciliation ownership extraction, selected in
`a294e7d0` and implemented in `05c056c2`.
`timeline_feedback.ex` moved from 3,917 to 3,894 lines; the
ExecutionUncertainty owner moved from 220 to 251 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation
plan-evidence extraction.

Blocked:
No.
