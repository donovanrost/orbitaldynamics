# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy decision-result builder extraction.

Status:
Completed and published in `c6b46cee`.

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
- Strict compile passed across 3,854 files with warnings as errors.
- Seven focused classification, ordering, escalation, and fallback baselines
  passed.
- All 89 Policy tests and the Policy schema-contract test passed with warnings
  as errors.
- Exact old/new executable comparison passed for 37 decisions spanning all 11
  bundles, three mixed scenarios, and four fallback cases.
- Static ownership confirms one `DecisionBuilder.build/6` production owner,
  one unchanged public `Policy.decide/5` facade, and no result helpers left in
  the facade.
- Runtime xref confirms `Policy` calls `DecisionBuilder`; format, diff checks,
  and bounded review passed.
- `policy.ex` moved from 2,324 to 2,119 lines; the new owner is 233 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy decision-result builder extraction, selected in `a0ef1d25` and
implemented in `c6b46cee`. `policy.ex` moved from 2,324 to 2,119 lines; the
dedicated builder is 233 lines.

Next candidate:
Re-inventory Policy bundle and action-rule normalization after decision-result
assembly has one production owner.

Blocked:
No.
