# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity precondition-summary extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract resource, command-authority, command-safety, activity-template, and
activity-type precondition classification into
`OrbitalDynamics.MissionPlan.Activity.PreconditionSummary`. Keep
`precondition_summary/1` as the public `Activity` facade and pass the
facade-owned unit-interval field list into the dedicated owner.

Selection evidence:
- `mission_plan/activity.ex` remains the second-largest production module at
  5,169 lines after the transition-policy extraction.
- The selected public builder and private helper family spans 1,058-1,085 and
  1,276-1,579 and has one responsibility: deterministic precondition artifact
  construction.
- The helpers have no callers outside `precondition_summary/1`; capability
  metadata, the Activity struct, and all validation/mutation stay in the
  facade.
- Focused Activity coverage exercises clear, review-required, blocked,
  command-authority, command-safety, template-state, and facade-wrapper cases.

Verification:
Pending: focused Activity baseline, exact old/new public precondition artifacts,
strict compile, adjacent timeline/operator-review/schema coverage, static
single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity lifecycle-transition policy extraction, selected in
`1c530694` and implemented in `5bad93be`. `mission_plan/activity.ex` moved from
5,236 to 5,169 lines; the dedicated owner is 101 lines.

Next candidate:
Re-inventory remaining MissionPlan.Activity map normalization and validation
families after precondition summaries have one production owner.

Blocked:
No.
