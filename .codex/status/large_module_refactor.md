# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy blocked-risk matcher extraction.

Status:
Completed and published in `4936bedc`.

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
- Strict compile passed across 3,853 files with warnings as errors.
- Eight focused fallback blocked-risk baselines passed.
- All 89 Policy tests and the Policy schema-contract test passed with warnings
  as errors.
- Exact old/new executable comparison passed for 53 blocked and neutral
  decisions spanning every blocked-risk dispatch family.
- A byte-level mechanical comparison confirmed the new owner preserves the
  selected predicate cluster exactly apart from its public entrypoint.
- Static ownership confirms one `blocked?/2` production owner and one private
  `blocked_risk_indicator?/2` Policy seam.
- Runtime xref confirms `Policy` calls `BlockedRiskMatcher`; format, diff
  checks, and bounded review passed.
- `policy.ex` moved from 2,649 to 2,324 lines; the new owner is 331 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy blocked-risk matcher extraction, selected in `99bdf15f` and implemented
in `4936bedc`. `policy.ex` moved from 2,649 to 2,324 lines; the dedicated matcher
is 331 lines.

Next candidate:
Re-inventory Policy decision-result assembly and bundle normalization after
blocked-risk interpretation has one production owner.

Blocked:
No.
