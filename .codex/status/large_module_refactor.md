# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy approval-requirement matcher extraction.

Status:
Completed and pushed in `856cf299`.

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
- Strict warnings-as-errors compile passed across 3,851 files.
- Eight focused requirement identity/review/station/resource/provider/timeline
  tests passed.
- All 89 Policy tests passed.
- The Policy schema-contract test passed.
- Exact old/new comparison passed for 110 built-in bundle/requirement decisions
  spanning identity, review/import, station/provider, reservation, resource,
  success-factor, timeline/protection, and provenance evidence.
- Static search confirms one requirement matcher owner and one private Policy
  orchestration seam; the final dead provider-token facade seam was retired.
- Runtime xref confirms Policy owns the dependency on RequirementMatcher.
- Formatting, diff checks, and bounded review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy approval-requirement matcher extraction, selected in `310fed8d` and
implemented in `856cf299`. `policy.ex` moved from 4,220 to 3,205 lines; the
dedicated matcher is 1,026 lines.

Next candidate:
Re-inventory Policy decision-evidence assembly after all four match families
have dedicated owners.

Blocked:
No.
