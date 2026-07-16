# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: model capability registry extraction.

Status:
Ready to publish.

Selected slice:
Move `environment_model_capability.v1`, `environment_provider_capability.v1`,
and `subsystem_model_capability.v1` into `Schema.ModelCapabilityRegistryContracts`.

Why this slice:
The three remaining adjacent model/provider capability definitions form one
cohesive registry family with direct schema, validation, and export coverage.

Current coupling/problem:
Declarative model-capability contract data remains embedded in the large
public `Schema` facade even though the facade only needs the merged registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.ModelCapabilityRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/model_capability_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/optimizer_objective_contracts_test.exs`
- `test/orbital_dynamics/schema/resource_contracts_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/export tests pass, and the exact contracts/bundle
fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/model_capability_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, capability validation, and generated schemas retain the
baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Optimizer-objective contracts, resource contracts, registry capability, and
  schema export tests passed: 17 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`efc81b39` (`Update resource summary handoff`).

Next candidate:
Assess `constraint_report.v1` and `score_term_report.v1` as one cohesive
optimizer-report registry extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 16,906 to 16,836 lines.
- `ModelCapabilityRegistryContracts` is 79 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
