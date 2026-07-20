# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema approval-policy owner routing extraction.

Status:
Completed and pushed.

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
Added a registry-backed `PolicyValidation.validate_artifact/4` entry point and
routed the three selected direct `Schema` validation clauses through the
existing owner. `schema.ex` moved from 4,823 to 4,817 lines.

Verification:
- Strict focused baseline: 104 tests passed.
- Focused plus adjacent policy, validation, campaign-planner, operator-review,
  campaign-contract, resource-contract, and export coverage after extraction:
  117 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the three intended direct facade routes.
- `mix xref trace` confirmed all three runtime calls originate in `schema.ex`;
  a bounded production search found no other `validate_artifact/4` callers.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, owner-default model
  limits and field groups, contract routing, validation ordering, and paths
  remain unchanged.
- Implementation committed and pushed as `34877d2c`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `PolicyValidation` APIs, validation results, and checked-in exports
remain unchanged.

Last completed slice:
Schema approval-policy owner routing extraction, selected in `67647dcc` and
implemented in `34877d2c`.
`schema.ex` moved from 4,823 to 4,817 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
