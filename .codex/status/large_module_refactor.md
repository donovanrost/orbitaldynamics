# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: optimizer report registry consolidation.

Status:
Ready to publish.

Selected slice:
Move `constraint_report.v1` and `score_term_report.v1` into the existing
`Schema.OptimizationRegistryContracts`.

Why this slice:
Both adjacent definitions are optimizer output reports, and the existing
optimization registry already owns optimizer and branch-comparison contracts.

Current coupling/problem:
Declarative optimizer-report contract data remains embedded in the large public
`Schema` facade instead of its already-merged family registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.OptimizationRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/optimization_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/optimizer_objective_contracts_test.exs`
- `test/orbital_dynamics/schema/validation_scoring_contracts_test.exs`
- `test/orbital_dynamics/schema/json_schema_export_contracts_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/export tests pass, and the exact contracts/bundle
fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/optimization_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, optimizer-report validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Optimizer-objective, validation-scoring, JSON-schema export-contract, and
  schema export tests passed: 27 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`751b7164` (`Update model capability handoff`).

Next candidate:
Assess `quality_gate_report.v1` as the next bounded registry extraction before
expanding into the larger operational-readiness summary family.

Blocked:
No.

Notes:
- `schema.ex` decreased from 16,836 to 16,803 lines.
- `OptimizationRegistryContracts` increased from 52 to 85 lines while absorbing
  the two reports.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
