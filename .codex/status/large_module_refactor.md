# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy approval-policy normalizer extraction.

Status:
Completed and published in `b1d4a27a`.

Selected boundary:
Extract approval-policy bundle resolution, inline-bundle checks, action-rule
normalization, numeric/status/direction normalization, and policy/rule
validation into `OrbitalDynamics.Policy.ApprovalPolicyNormalizer`. Move the
rule-field schema constants with their sole consumer; preserve
`Policy.normalize_approval_policy/1` as the public facade, passing the built-in
bundle resolver and default blocked-risk types into the new owner.

Selection evidence:
- `policy.ex` is now 2,119 lines; the selected rule-field schemas occupy lines
  15-211 and their exclusive normalization/validation helpers span
  1,665-2,080 around the public facade.
- The cluster has one responsibility: resolve policy input into a deterministic,
  validated string-keyed approval policy.
- Its external call inventory is limited to the supplied built-in bundle
  resolver, `RequirementContext` normalization, and CadenceImport capability
  values.
- Built-in bundle definitions, organization/artifact wrappers, decision
  orchestration, match construction, capabilities, and public signatures remain
  outside.

Verification:
- Strict compile passed across 3,855 files with warnings as errors.
- Twelve focused normalization and validation baselines passed.
- All 89 Policy tests and the Policy schema-contract test passed with warnings
  as errors.
- Exact old/new executable comparison passed for 44 valid and invalid inputs,
  including every built-in bundle and validation error messages.
- Static ownership confirms one `ApprovalPolicyNormalizer.normalize/3`
  production owner and one unchanged public
  `Policy.normalize_approval_policy/1` facade.
- Runtime xref confirms `Policy` calls `ApprovalPolicyNormalizer`; format, diff
  checks, and bounded review passed.
- The separate Cadence-status capability accessor remains in `Policy` for its
  existing `capabilities/0` caller.
- `policy.ex` moved from 2,119 to 1,507 lines; the new owner is 656 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy approval-policy normalizer extraction, selected in `34b34b50` and
implemented in `b1d4a27a`. `policy.ex` moved from 2,119 to 1,507 lines; the
dedicated normalizer is 656 lines.

Next candidate:
Re-inventory the remaining Policy bundle/catalog facade after approval-policy
normalization has one production owner.

Blocked:
No.
