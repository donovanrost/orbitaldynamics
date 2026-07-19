# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity collection input extraction.

Status:
Selected; implementation not started.

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
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity scalar input extraction, selected in `0c45d036` and
implemented in `02dc170e`. `mission_plan/activity.ex` moved from 4,770 to 4,672
lines; the dedicated owner is 138 lines.

Next candidate:
Implement and verify the selected collection input extraction.

Blocked:
No.
