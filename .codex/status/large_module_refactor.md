# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy rule-match evidence assembly extraction.

Status:
Completed and published in `136fc1ee`.

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
- Strict compile passed across 3,852 files with warnings as errors.
- Five focused four-family evidence/escalation baselines passed.
- All 89 Policy tests and the Policy schema-contract test passed with warnings
  as errors.
- Exact old/new executable comparison passed for 33 mixed four-family decisions
  spanning all 11 policy bundles and three scenarios.
- Static ownership confirms one `approval_rule_matches/5` facade seam, one
  `RuleMatchBuilder.build/6` production owner, and only the required
  `non_empty_list/1` facade delegation for the remaining Policy caller.
- Runtime xref confirms `Policy` calls `RuleMatchBuilder`; format, diff checks,
  and bounded review passed.
- `policy.ex` moved from 3,205 to 2,649 lines; the new owner is 549 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy rule-match evidence assembly extraction, selected in `ce942b7d` and
implemented in `136fc1ee`. `policy.ex` moved from 3,205 to 2,649 lines; the
dedicated builder is 549 lines.

Next candidate:
Re-inventory Policy decision classification and bundle normalization after
rule-match evidence assembly has one production owner.

Blocked:
No.
