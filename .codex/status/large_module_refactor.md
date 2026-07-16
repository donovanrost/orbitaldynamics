# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: validation-acceptance registry extraction.

Status:
Published.

Selected slice:
Moved `validation_record.v1`, `model_acceptance_report.v1`, and
`validation_safety_case_summary.v1` definitions into
`Schema.ValidationAcceptanceRegistryContracts`.

Why this slice:
The three definitions form one validation evidence and acceptance-summary family
with explicit nesting and no runtime helper coupling.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/validation_acceptance_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents and the complete generated JSON Schema bundle retain the
baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Validation evidence, policy, candidate-refresh resource provenance, registry
  capability, and schema export tests passed: 14 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.ValidationAcceptanceRegistryContracts`
  passed with the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`02e019ad` (`Extract validation acceptance registry contracts`).

Next candidate:
Extract the contiguous validation policy/catalog tail
(`validation_tolerance_policy.v1`, `backend_acceptance_policy.v1`, and
`capability_catalog.v1`) into a focused registry module.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,830 to 18,736 lines.
- `ValidationAcceptanceRegistryContracts` is 105 lines.
- Published accepted-state registry extraction: `016060d3`.
