# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy decision-result builder extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract rule-match provenance projection and canonical sorting, approval
requirement enrichment, strongest/fallback classification, escalation summary,
decision counts, and final decision-map assembly into
`OrbitalDynamics.Policy.DecisionBuilder`. Preserve `Policy.decide/5` as the
public orchestration facade that normalizes policy and builds raw rule matches.

Selection evidence:
- `policy.ex` is now 2,324 lines; the selected result assembly is the private
  decision body at 1,654-1,729 plus its exclusive helpers at 1,732-1,745 and
  2,176-2,295.
- Every selected helper is called only within this result-building path; the
  only production dependency is `BlockedRiskMatcher`.
- The cluster has one responsibility: turn raw rule matches and fallback inputs
  into the deterministic `policy_decision.v1` tuple returned by `decide/5`.
- Policy normalization, raw four-family rule-match construction, bundles,
  validation, capabilities, and public API signatures remain outside.

Verification:
Pending: focused classification/order/escalation/fallback baselines, exact
old/new bundle and fallback decision proofs, strict compile, full Policy tests,
relevant schema/contracts, static single ownership, runtime xref, and bounded
review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy blocked-risk matcher extraction, selected in `99bdf15f` and implemented
in `4936bedc`. `policy.ex` moved from 2,649 to 2,324 lines; the dedicated matcher
is 331 lines.

Next candidate:
Re-inventory Policy bundle and action-rule normalization after decision-result
assembly has one production owner.

Blocked:
No.
