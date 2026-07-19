# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity scalar input extraction.

Status:
Completed and pushed in `02dc170e`.

Selected boundary:
Extract boolean, numeric, non-negative numeric/integer, unit-interval,
string/atom scalar, and number-or-scalar predicates and coercions into
`OrbitalDynamics.MissionPlan.Activity.ScalarInput`. Preserve the existing
private helper seams in the Activity facade. Keep stable-identifier validation
in the facade because its pattern is also used by later identifier-list
normalization.

Selection evidence:
- Live re-ranking places `mission_plan/activity.ex` at 4,770 lines.
- The selected 4,165-4,304 helper family is pure scalar input normalization
  used by map parsing and common option validation.
- Activity construction, field selection, option assembly, struct validation,
  and public constructors remain in the facade.
- Numeric-string parsing remains owned by the adjacent
  `ExecutionUncertaintyInput` helper and will be reused by the new owner.
- Stable-identifier predicates and coercions remain with the facade-owned
  identifier policy instead of duplicating `@stable_id_pattern`.

Verification:
- Strict warnings-as-errors compile passed across 3,882 files.
- Focused MissionPlan.Activity coverage passed: 31 tests.
- Adjacent mission-plan, activity-fixture, and timeline-activity schema
  coverage passed: 44 tests.
- Exact old/new public map construction and error comparison against
  `0c45d036` passed for 10 valid boolean, numeric, integer, interval, scalar,
  number-or-scalar, and nil cases plus 10 invalid value/shape cases.
- Runtime xref found the new owner referenced only by the Activity facade;
  static single-ownership review and `git diff --check` passed.
- `mission_plan/activity.ex` moved from 4,770 to 4,672 lines; the dedicated
  owner is 138 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity scalar input extraction, selected in `0c45d036` and
implemented in `02dc170e`. `mission_plan/activity.ex` moved from 4,770 to 4,672
lines; the dedicated owner is 138 lines.

Next candidate:
Re-inventory remaining MissionPlan.Activity list/map normalization families
after scalar input has one owner.

Blocked:
No.
