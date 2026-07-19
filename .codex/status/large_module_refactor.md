# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity lifecycle-transition policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract status-transition review/category policy, approval-transition
review/category policy, and lifecycle-event token normalization into
`OrbitalDynamics.MissionPlan.Activity.LifecycleTransition`. Keep all public
`Activity` functions and struct mutations in the existing facade.

Selection evidence:
- Live re-ranking shows `mission_plan/activity.ex` is now the second-largest
  production module at 5,236 lines after `schema.ex` at 6,764 lines.
- The selected transition-policy helpers span 1,255-1,315 and 1,623-1,649 and
  are pure classification/normalization logic with no struct construction.
- Public mutation helpers, lifecycle dispatch, validation, and the Activity
  struct remain in the facade; the owner receives the facade-owned status and
  alias collections as data.
- `test/orbital_dynamics/mission_plan/activity_test.exs` has focused coverage
  for transition safety, categories, aliases, facade wrappers, and failures.

Verification:
Pending: focused Activity baseline, exact old/new public transition outputs
and errors, strict compile, adjacent timeline facade coverage, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback execution-uncertainty extraction, selected in `194959c0` and
implemented in `1c8213e6`. `timeline_feedback.ex` moved from 5,173 to 5,023
lines; the dedicated owner is 234 lines.

Next candidate:
Re-inventory remaining MissionPlan.Activity lifecycle/precondition and map
normalization families after transition policy has one production owner.

Blocked:
No.
