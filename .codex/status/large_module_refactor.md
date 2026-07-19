# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback throughput extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract numeric path lookup, planned/actual data-volume selection, data-rate
unit selection, actual-throughput derivation, duration fallback, derivation
evidence, and throughput completion fraction into
`OrbitalDynamics.TimelineFeedback.Throughput`. Preserve the existing private
numeric and throughput seams in the TimelineFeedback facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,766 lines, above the
  4,470-line Activity facade after its input-normalization pass.
- The selected 4,394-4,608 helper family is one throughput interpretation
  pipeline used by row construction and operational feedback.
- Generic numeric conversion remains single-owned by
  `TimelineFeedback.ExecutionUncertainty`; the new owner reuses it.
- Report assembly, matching, success-factor policy, resource feedback, and
  public report APIs remain in the facade.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity identifier input extraction, selected in `9aded909` and
implemented in `292a84df`. `mission_plan/activity.ex` moved from 4,577 to 4,470
lines; the dedicated owner is 143 lines.

Next candidate:
Implement and verify the selected TimelineFeedback throughput extraction.

Blocked:
No.
