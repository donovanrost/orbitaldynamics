# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity identifier input extraction.

Status:
Completed and pushed in `292a84df`.

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
- Strict warnings-as-errors compile passed across 3,884 files.
- Focused MissionPlan.Activity coverage passed: 31 tests.
- Adjacent mission-plan, activity-fixture, and timeline-activity schema
  coverage passed: 44 tests.
- Exact old/new public map construction and error comparison against
  `9aded909` passed for 11 valid required/optional/stable identifier, ID-list,
  dependency-map, and nil cases plus 10 invalid value/shape cases.
- Runtime xref found the new owner referenced only by the Activity facade;
  static single-ownership review and `git diff --check` passed.
- `mission_plan/activity.ex` moved from 4,577 to 4,470 lines; the dedicated
  owner is 143 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity identifier input extraction, selected in `9aded909` and
implemented in `292a84df`. `mission_plan/activity.ex` moved from 4,577 to 4,470
lines; the dedicated owner is 143 lines.

Next candidate:
Re-rank all hotspots after the Activity input-normalization pass and select the
next facade-reducing responsibility boundary.

Blocked:
No.
