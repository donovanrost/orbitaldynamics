# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity collection input extraction.

Status:
Completed and pushed in `9defcde8`.

Selected boundary:
Extract scalar-list, non-negative-number-list, map-list, and optional-map
validation and normalization into
`OrbitalDynamics.MissionPlan.Activity.CollectionInput`. Preserve the existing
private helper seams in the Activity facade. Keep dependency and identifier
list handling in the facade because they participate in activity dependency
semantics and share stable-identifier policy.

Selection evidence:
- Live re-ranking places `mission_plan/activity.ex` at 4,672 lines.
- The selected 4,221-4,264 and 4,368-4,510 helper families are generic
  collection/map input normalization used by map parsing and validation.
- Activity construction, field selection, option assembly, struct validation,
  and public constructors remain in the facade.
- Numeric-string parsing remains single-owned by
  `ExecutionUncertaintyInput` and will be reused by the new owner.
- Dependency flattening, dependency activity-ID projection, and stable-ID list
  parsing remain together in the facade.

Verification:
- Strict warnings-as-errors compile passed across 3,883 files.
- Focused MissionPlan.Activity coverage passed: 31 tests.
- Adjacent mission-plan, activity-fixture, and timeline-activity schema
  coverage passed: 44 tests.
- Exact old/new public map construction and error comparison against
  `b9673591` passed for 11 valid scalar-list, numeric-list, map-list,
  optional-map, and nil cases plus 10 invalid value/shape cases.
- Runtime xref found the new owner referenced only by the Activity facade;
  static single-ownership review and `git diff --check` passed.
- `mission_plan/activity.ex` moved from 4,672 to 4,577 lines; the dedicated
  owner is 126 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity collection input extraction, selected in `b9673591` and
implemented in `9defcde8`. `mission_plan/activity.ex` moved from 4,672 to 4,577
lines; the dedicated owner is 126 lines.

Next candidate:
Re-inventory remaining MissionPlan.Activity identifier/dependency normalization
and switch focus if no facade-reducing boundary remains.

Blocked:
No.
