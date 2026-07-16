# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: objective analysis registry extraction.

Status:
Published.

Selected slice:
Moved `objective_tradeoff_report.v1`, `objective_satisfaction_report.v1`,
`ranking_comparison_report.v1`, and `pareto_frontier_report.v1` into
`Schema.ObjectiveAnalysisRegistryContracts`.

Why this slice:
The four adjacent definitions form one scoring/tradeoff analysis family with
shared optimizer/objective and JSON export coverage.

Current coupling/problem:
Declarative objective-analysis contract data remains embedded in the large
public `Schema` facade even though the facade only needs the merged registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.ObjectiveAnalysisRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/objective_analysis_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/optimizer_objective_contracts_test.exs`
- `test/orbital_dynamics/schema/validation_scoring_contracts_test.exs`
- `test/orbital_dynamics/schema/json_schema_export_contracts_test.exs`
- `test/orbital_dynamics/schema/fixture_visibility_contracts_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/export tests pass, and the exact contracts/bundle
fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/objective_analysis_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, objective-analysis validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Optimizer/objective, validation/scoring, JSON export, fixture visibility,
  registry capability, and schema export tests passed: 33 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, conflict-marker, and checked-in
  schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`089e3faa` (`Extract objective analysis registry contracts`).

Next candidate:
Assess strategy recommendation, maneuver recommendation/review, and execution
reports as the next bounded registry family.

Blocked:
No.

Notes:
- `schema.ex` decreased from 17,927 to 17,849 lines.
- `ObjectiveAnalysisRegistryContracts` is 84 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
