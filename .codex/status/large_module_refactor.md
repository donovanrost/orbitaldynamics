# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: quality-gate report registry extraction.

Status:
Published.

Selected slice:
Move `quality_gate_report.v1` into `Schema.QualityGateRegistryContracts`.

Why this slice:
The report already has a focused validator module and direct readiness/export
coverage, while its declarative registry definition remains inline.

Current coupling/problem:
Declarative quality-gate report data remains embedded in the large public
`Schema` facade even though the facade only needs a merged registry entry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.QualityGateRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/quality_gate_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/readiness_contracts_test.exs`
- `test/orbital_dynamics/schema/operational_contracts_test.exs`
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
- `lib/orbital_dynamics/schema/quality_gate_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, quality-gate validation, and generated schemas retain
the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Readiness contracts, operational contracts, validation evidence, registry
  capability, and schema export tests passed: 23 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`e395cf45` (`Extract quality gate registry contracts`).

Next candidate:
Assess the five adjacent operational quality-gate summary contracts as one
cohesive registry extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 16,803 to 16,761 lines.
- `QualityGateRegistryContracts` is 51 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
