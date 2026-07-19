# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity precondition-summary extraction.

Status:
Completed and pushed in `437652a8`.

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
- Strict warnings-as-errors compile passed across 3,876 files.
- Focused MissionPlan.Activity coverage passed: 31 tests.
- Adjacent operator-review, timeline-activity schema, candidate-refresh replay,
  and campaign-strategy coverage passed: 28 tests.
- Exact old/new public artifact comparison against `2bcf1229` passed for 13
  clear, review, blocked, authority, safety, template, and combined cases.
- Runtime xref found the new owner referenced only by the `Activity` facade;
  static single-ownership review and `git diff --check` passed.
- `mission_plan/activity.ex` moved from 5,169 to 4,841 lines; the dedicated
  owner is 367 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity precondition-summary extraction, selected in `2bcf1229`
and implemented in `437652a8`. `mission_plan/activity.ex` moved from 5,169 to
4,841 lines; the dedicated owner is 367 lines.

Next candidate:
Re-inventory remaining MissionPlan.Activity map normalization and validation
families after precondition summaries have one production owner.

Blocked:
No.
