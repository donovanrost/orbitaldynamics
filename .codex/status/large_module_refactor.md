# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: provider-counteroffer registry extraction.

Status:
Ready to publish.

Selected slice:
Move the provider-counteroffer report, review summary, import-readiness summary,
and plan-impact summary into `Schema.ProviderCounterofferRegistryContracts`.

Why this slice:
The four adjacent contracts form one provider-counteroffer lifecycle family with
dedicated validator modules and direct provider/station/export coverage.

Current coupling/problem:
Declarative provider-counteroffer contract data remains embedded in the large
public `Schema` facade even though it can be merged as one focused registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.ProviderCounterofferRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/provider_counteroffer_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/provider_counteroffer_contracts_test.exs`
- `test/orbital_dynamics/schema/station_provider_contracts_test.exs`
- `test/orbital_dynamics/schema/validation_evidence_contracts_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/export tests pass, and the exact contracts/bundle
fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/provider_counteroffer_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, provider-counteroffer validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Provider-counteroffer contracts, station-provider contracts, validation
  evidence, registry capability, and schema export tests passed: 19 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`03a804b3` (`Update approval policy handoff`).

Next candidate:
Assess the adjacent station-reservation hold summary and import-readiness summary
as one cohesive registry extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 16,281 to 16,155 lines.
- `ProviderCounterofferRegistryContracts` is 137 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
