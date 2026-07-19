# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy approval-requirement matcher extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract `approval_rule_requirement_match?/2`, its 63 context-selector checks,
provider-result selectors, numeric threshold/range predicates, and all private
matcher helpers into `OrbitalDynamics.Policy.RequirementMatcher`. Preserve one
private Policy seam used by rule-match orchestration and reuse
`Policy.RequirementContext` as the sole context-normalization owner.

Selection evidence:
- `policy.ex` is now 4,220 lines; the selected continuous requirement matcher
  spans 1,020 lines at 2,730-3,749.
- The cluster has one responsibility: decide whether one normalized approval
  requirement satisfies one rule across identity, review, station, resource,
  timeline, provider-result, success-factor, and threshold selectors.
- Call inventory shows only six matcher-local helper families and
  RequirementContext access; only the top-level predicate is used outside the
  boundary.
- Policy bundles, risk/event/activity matching, decision orchestration,
  escalation, fallback classification, and public APIs remain outside the
  boundary.

Verification:
Pending: focused requirement identity/review/station/resource/provider/timeline
baselines, exact old/new requirement decision proofs, strict compile, full
Policy tests, relevant schema/contracts, static single ownership, runtime xref,
and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy activity-feasibility matcher extraction, selected in `8b078935` and
implemented in `2afb9c0b`. `policy.ex` moved from 4,378 to 4,220 lines; the
dedicated matcher is 168 lines.

Next candidate:
Re-inventory Policy decision-evidence assembly after all four match families
have dedicated owners.

Blocked:
No.
