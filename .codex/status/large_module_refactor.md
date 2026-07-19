# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
MissionPlan.Activity execution-uncertainty input extraction.

Status:
Selected; implementation has not started.

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
Pending: focused Activity baseline, exact old/new public constructors/maps and
errors, strict compile, adjacent mission-plan coverage, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback identity-value consolidation, selected in `6ddb46fc` and
implemented in `a02efa00`. `timeline_feedback.ex` moved from 4,882 to 4,766
lines; `RealizedIdentity` moved from 121 to 240 lines.

Next candidate:
Re-inventory remaining MissionPlan.Activity scalar/list/map normalization
families after execution-uncertainty input has one owner.

Blocked:
No.
