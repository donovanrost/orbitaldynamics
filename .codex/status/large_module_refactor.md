# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: approval-policy registry consolidation.

Status:
Ready to publish.

Selected slice:
Move `policy_bundle.v1` into the existing `Schema.ApprovalPolicyRegistryContracts`.

Why this slice:
The registry already owns the bundle's two nested approval-policy contracts,
and policy/export tests directly cover the complete family.

Current coupling/problem:
Declarative policy-bundle contract data remains embedded in the large public
`Schema` facade instead of its already-merged approval-policy registry.

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
- `test/mix/tasks/orbital_dynamics.policy.export_test.exs`
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
None. Registry contents, approval-policy validation, and generated schemas retain
the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Policy contracts, campaign repair/strategy contracts, policy export, and
  schema export tests passed: 10 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`7581958f` (`Update Cadence import handoff`).

Next candidate:
Assess the four adjacent provider-counteroffer report and summary contracts as
one cohesive registry extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 16,298 to 16,281 lines.
- `ApprovalPolicyRegistryContracts` increased from 48 to 65 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
