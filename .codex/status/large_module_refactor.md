# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy rule-match evidence assembly extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract `approval_rule_matches/5`, all four requirement/risk/event/activity
evidence-row builders, escalation-field projection, and empty-list compaction
into `OrbitalDynamics.Policy.RuleMatchBuilder`. Preserve one private Policy seam
used by `decide/5`; call the four matchers and their evidence accessors directly
from the new owner.

Selection evidence:
- `policy.ex` is now 3,205 lines; the selected evidence assembly spans 510 lines
  at 2,163-2,672 plus its local escalation/list helpers.
- The cluster has one responsibility: convert successful matcher results into
  deterministic policy rule-match evidence rows for the four input families.
- Its call inventory is entirely the four dedicated matchers, their context
  accessors, map/list operations, and two local projection helpers.
- Policy bundles, match predicates, decision classification/sorting, fallback
  policy, and public APIs remain outside the boundary.

Verification:
Pending: focused four-family evidence/escalation baselines, exact old/new mixed
decision proofs, strict compile, full Policy tests, relevant schema/contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy approval-requirement matcher extraction, selected in `310fed8d` and
implemented in `856cf299`. `policy.ex` moved from 4,220 to 3,205 lines; the
dedicated matcher is 1,026 lines.

Next candidate:
Re-inventory Policy decision classification and bundle normalization after
rule-match evidence assembly has one production owner.

Blocked:
No.
