# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy approval-policy normalizer extraction.

Status:
Selected; implementation has not started.

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
Pending: focused normalization/validation baselines, exact old/new valid and
invalid input proofs, strict compile, full Policy tests, relevant
schema/contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy decision-result builder extraction, selected in `a0ef1d25` and
implemented in `c6b46cee`. `policy.ex` moved from 2,324 to 2,119 lines; the
dedicated builder is 233 lines.

Next candidate:
Re-inventory the remaining Policy bundle/catalog facade after approval-policy
normalization has one production owner.

Blocked:
No.
