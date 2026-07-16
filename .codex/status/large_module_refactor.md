# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: study/result registry extraction.

Status:
Ready to publish.

Selected slice:
Moved `study_benchmark.v1`, `manifest_field_reference.v1`, and
`result_artifact.v1` definitions into `Schema.StudyResultRegistryContracts`.

Why this slice:
The three definitions form the study-facing benchmark, manifest tooling, and
top-level result artifact family with explicit nested contracts.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/study_result_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, study/result validation, linting, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Result-artifact contracts, registry capability, schema export, schema lint,
  and manifest reference tests passed: 31 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.StudyResultRegistryContracts` passed
  with the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`9275e54a` (`Update strategy schema handoff`); current slice is not yet committed.

Next candidate:
Assess the adjacent `branch_comparison_report.v1` and `optimizer_contract.v1`
definitions as a possible optimization registry family before editing.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,621 to 18,549 lines.
- `StudyResultRegistryContracts` is 81 lines.
- The inline `@base_contracts` registry remains substantial; this is not a
  milestone-completion claim.
