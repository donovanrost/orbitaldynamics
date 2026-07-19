# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy blocked-risk matcher extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract `blocked_risk_indicator?/2`, the blocked-type dispatch clauses, and
their pressure/value/count predicates into
`OrbitalDynamics.Policy.BlockedRiskMatcher`. Preserve one private Policy seam
used only by `fallback_status/3`.

Selection evidence:
- `policy.ex` is now 2,649 lines; the selected fallback-risk interpretation
  cluster spans 326 lines at 2,294-2,619.
- The cluster has one responsibility: decide whether a risk indicator matches
  any configured blocked-risk type, including derived pressure aliases.
- Its call inventory is self-contained map/list/value/count interpretation and
  has one production caller through `fallback_status/3`.
- Fallback thresholds, rule-match classification, decision assembly, bundle
  normalization, and public APIs remain outside the boundary.

Verification:
Pending: eight focused fallback blocked-risk baselines, exact old/new blocked
type/alias proofs, strict compile, full Policy tests, relevant schema/contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy rule-match evidence assembly extraction, selected in `ce942b7d` and
implemented in `136fc1ee`. `policy.ex` moved from 3,205 to 2,649 lines; the
dedicated builder is 549 lines.

Next candidate:
Re-inventory Policy decision-result assembly and bundle normalization after
blocked-risk interpretation has one production owner.

Blocked:
No.
