# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity identifier input extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract required/optional identifier validation, stable-identifier validation,
ID-list normalization, dependency-reference validation, and dependency
activity-ID projection into
`OrbitalDynamics.MissionPlan.Activity.IdentifierInput`. Preserve the existing
private helper seams in the Activity facade while moving
`@stable_id_pattern` to its single production owner.

Selection evidence:
- Live re-ranking places `mission_plan/activity.ex` at 4,577 lines.
- The selected 4,181-4,250, 4,355-4,457, and 4,568-4,575 helper families share
  identifier validity and stable-ID policy across scalar and list forms.
- Activity construction, field selection, option assembly, struct validation,
  and public constructors remain in the facade.
- Dependency map preservation and activity-ID projection move together; no
  public dependency representation changes.
- The stable-ID regex has no remaining non-identifier consumer in the facade.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity collection input extraction, selected in `b9673591` and
implemented in `9defcde8`. `mission_plan/activity.ex` moved from 4,672 to 4,577
lines; the dedicated owner is 126 lines.

Next candidate:
Implement and verify the selected identifier input extraction.

Blocked:
No.
