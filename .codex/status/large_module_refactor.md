# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity scalar input extraction.

Status:
Selected; implementation not started.

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
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity execution-uncertainty input extraction, selected in
`4e424eee` and implemented in `8aaca2ef`. `mission_plan/activity.ex` moved from
4,841 to 4,770 lines; the dedicated owner is 78 lines.

Next candidate:
Implement and verify the selected scalar input extraction.

Blocked:
No.
