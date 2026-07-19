# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy risk-rule matcher extraction.

Status:
Selected; implementation has not started.

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
Pending: focused risk type/direction/station/spacecraft/target baselines, exact
old/new risk decision proofs, strict compile, full Policy tests, relevant
schema/contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy requirement-context extraction, selected in `56a7dfce` and implemented
in `44d83250`. `policy.ex` moved from 5,555 to 4,960 lines; the dedicated
resolver is 630 lines.

Next candidate:
Re-inventory the neighboring Policy event/activity match families after risk
matching has one production owner.

Blocked:
No.
