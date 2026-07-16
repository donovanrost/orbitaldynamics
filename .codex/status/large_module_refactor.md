# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: optimization registry extraction.

Status:
Published.

Selected slice:
Moved `branch_comparison_report.v1` and `optimizer_contract.v1` definitions into
`Schema.OptimizationRegistryContracts`.

Why this slice:
The two definitions form the branch-comparison and optimizer selection family
and share one focused contract test surface.

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
None. Registry contents, optimizer/branch-comparison validation, and generated
schemas retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Optimizer/objective contracts, fixture visibility, registry capability, and
  schema export tests passed: 12 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.OptimizationRegistryContracts`
  passed with the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`4d270b02` (`Extract optimization registry contracts`).

Next candidate:
Assess the adjacent timeline-transition application report and summary registry
definitions as the next bounded family.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,549 to 18,506 lines.
- `OptimizationRegistryContracts` is 52 lines.
- The inline registry remains substantial; this is not a completion claim.
