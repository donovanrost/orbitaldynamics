# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity execution-uncertainty input extraction.

Status:
Completed and pushed in `8aaca2ef`.

Selected boundary:
Extract execution-uncertainty map normalization, delta-v triplet validation,
numeric field normalization, and numeric-string parsing into
`OrbitalDynamics.MissionPlan.Activity.ExecutionUncertaintyInput`. Preserve the
existing private uncertainty, delta-v, and numeric parsing seams in the
Activity facade.

Selection evidence:
- Live re-ranking places `mission_plan/activity.ex` at 4,841 lines.
- The selected 4,365-4,443 helper family is pure input normalization used by
  map parsing and common option validation.
- Activity construction, field selection, option assembly, struct validation,
  and public constructors remain in the facade.
- Numeric parsing remains available to other facade validators through one
  private delegate rather than being duplicated.

Verification:
- Strict warnings-as-errors compile passed across 3,881 files.
- Focused MissionPlan.Activity coverage passed: 31 tests.
- Adjacent mission-plan, activity-fixture, and timeline-activity schema
  coverage passed: 44 tests.
- Exact old/new public constructor/map and error comparison against `4e424eee`
  passed for 7 list/tuple, numeric-string, malformed-field, and nil uncertainty
  cases plus 4 invalid-shape/value cases.
- Runtime xref found the new owner referenced only by the Activity facade;
  static single-ownership review and `git diff --check` passed.
- `mission_plan/activity.ex` moved from 4,841 to 4,770 lines; the dedicated
  owner is 78 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity execution-uncertainty input extraction, selected in
`4e424eee` and implemented in `8aaca2ef`. `mission_plan/activity.ex` moved from
4,841 to 4,770 lines; the dedicated owner is 78 lines.

Next candidate:
Re-inventory remaining MissionPlan.Activity scalar/list/map normalization
families after execution-uncertainty input has one owner.

Blocked:
No.
