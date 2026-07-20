# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema approval-policy owner routing extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add a registry-backed `PolicyValidation.validate_artifact/4` entry point for
`approval_requirement.v1`, `policy_decision.v1`, and `policy_bundle.v1`.
Derive requirements from `ApprovalPolicyRegistryContracts`, route all three
direct `Schema` clauses, and preserve every existing `PolicyValidation` API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,823 lines; the other
  targeted public facades are now 164 to 524 lines.
- The three adjacent clauses repeat required-field setup and form the exact
  family owned by `ApprovalPolicyRegistryContracts`.
- `PolicyValidation` already owns all artifact-specific contract routing,
  model-limit defaults, and field-group defaults.
- No route needs callbacks, recursive `Schema` lookup, or facade-local context.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and `PolicyValidation` APIs, validation results, and checked-in exports must
remain unchanged.

Last completed slice:
Schema realized-state validation context extraction, selected in `121d60c9`
and implemented in `7afa123b`.
`schema.ex` moved from 4,826 to 4,823 lines.

Next candidate:
Implement and verify the selected approval-policy owner routing, then re-rank
the remaining Schema responsibility clusters.

Blocked:
No.
