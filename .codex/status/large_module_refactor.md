# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: operational-readiness registry extraction.

Status:
Published.

Selected slice:
Move the operational-readiness report, import-eligibility summary, gate summary,
and execution-boundary summary into `Schema.OperationalReadinessRegistryContracts`.

Why this slice:
The four adjacent contracts form the core readiness report/summary family with
dedicated validator modules and shared operational/readiness/export coverage.

Current coupling/problem:
Declarative operational-readiness contract data remains embedded in the large
public `Schema` facade even though it can be merged as one focused registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.OperationalReadinessRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_readiness_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/operational_contracts_test.exs`
- `test/orbital_dynamics/schema/readiness_contracts_test.exs`
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
- `lib/orbital_dynamics/schema/operational_readiness_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, operational-readiness validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Operational contracts, readiness contracts, validation evidence, registry
  capability, and schema export tests passed: 23 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`b18b5a56` (`Extract operational readiness registry contracts`).

Next candidate:
Assess `cadence_import_manifest.v1` as the next bounded registry extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 16,544 to 16,420 lines.
- `OperationalReadinessRegistryContracts` is 135 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
