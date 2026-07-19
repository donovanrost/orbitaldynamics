# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity lifecycle-transition policy extraction.

Status:
Completed and pushed in `5bad93be`.

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
- Strict warnings-as-errors compile passed across 3,875 files.
- Focused MissionPlan.Activity coverage passed: 31 tests.
- Adjacent mission-plan, timeline-activity schema, and candidate-refresh
  lifecycle replay coverage passed: 48 tests.
- Exact old/new public output/error comparison against `1c530694` passed for
  27 status, approval, lifecycle-event, and invalid-event cases.
- Runtime xref found the new owner referenced only by the `Activity` facade;
  static single-ownership review and `git diff --check` passed.
- `mission_plan/activity.ex` moved from 5,236 to 5,169 lines; the dedicated
  owner is 101 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity lifecycle-transition policy extraction, selected in
`1c530694` and implemented in `5bad93be`. `mission_plan/activity.ex` moved from
5,236 to 5,169 lines; the dedicated owner is 101 lines.

Next candidate:
Re-inventory remaining MissionPlan.Activity lifecycle/precondition and map
normalization families after transition policy has one production owner.

Blocked:
No.
