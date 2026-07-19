# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy risk-rule matcher extraction.

Status:
Completed and pushed in `bd14ec63`.

Selected boundary:
Extract `approval_rule_risk_match?/2`, all risk direction/identity/context
matching and evidence accessors, and the shared normalized direction-selector
predicate into `OrbitalDynamics.Policy.RiskMatcher`. Preserve the private
Policy seams used by decision matching and rule-match evidence construction;
keep generic direction normalization in `Policy.RequirementContext`.

Selection evidence:
- `policy.ex` is now 4,960 lines; the selected continuous risk matcher spans
  roughly 306 lines at 3,778-4,083.
- The cluster has one responsibility: decide whether one normalized risk
  satisfies one rule and expose the exact risk fields recorded in match
  evidence.
- It depends only on maps/lists and the newly owned direction normalization
  helpers; event and activity matching remain separate neighboring families.
- Policy bundles, requirement/event/activity matching, decision orchestration,
  escalation, fallback classification, and public APIs remain outside the
  boundary.

Verification:
- Strict warnings-as-errors compile passed across 3,848 files.
- Five focused risk type/direction/station/spacecraft/target tests passed.
- All 89 Policy tests passed.
- The Policy schema-contract test passed.
- Exact old/new comparison passed for 55 built-in bundle/risk decisions spanning
  direction, station identity/status, spacecraft, target, provider calendar,
  and reservation evidence.
- Static search confirms one risk matcher owner with seven explicit private
  Policy seams plus one shared direction-selector predicate.
- Runtime xref confirms Policy owns the dependency on RiskMatcher.
- Formatting, diff checks, and bounded review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy risk-matcher extraction, selected in `27fba3ea` and implemented in
`bd14ec63`. `policy.ex` moved from 4,960 to 4,652 lines; the dedicated matcher
is 326 lines.

Next candidate:
Re-inventory the neighboring Policy event/activity match families after risk
matching has one production owner.

Blocked:
No.
