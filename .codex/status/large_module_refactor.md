# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: approval policy registry extraction.

Status:
Ready to publish.

Selected slice:
Moved `approval_requirement.v1` and `policy_decision.v1` into
`Schema.ApprovalPolicyRegistryContracts`.

Why this slice:
`policy_decision.v1` directly nests `approval_requirement.v1`; the much larger
operator review package has a separate focused suite and remains its own slice.

Current coupling/problem:
Declarative approval/policy contract data remains embedded in the large
public `Schema` facade even though the facade only needs the merged registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.ApprovalPolicyRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/approval_policy_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/policy_contracts_test.exs`
- `test/orbital_dynamics/schema/campaign_repair_strategy_contracts_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/export tests pass, and the exact contracts/bundle
fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/approval_policy_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, approval/policy validation, and generated schemas retain
the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Policy, campaign repair/strategy, registry capability, schema lint, and schema
  export tests passed: 24 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`73a2eba8` (`Update execution reproducibility handoff`).

Next candidate:
Assess `operator_review_package.v1` as the next standalone registry extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 17,725 to 17,683 lines.
- `ApprovalPolicyRegistryContracts` is 48 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
