# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: accepted planning-state registry extraction.

Status:
Published.

Selected slice:
Moved `accepted_planning_state.v1`, `spacecraft_state_estimate.v1`, and
`maneuver_execution_delta.v1` definitions into
`Schema.AcceptedStateRegistryContracts`.

Why this slice:
The three definitions form one accepted-state snapshot family with explicit
nesting and no runtime helper or shared-field coupling.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/accepted_state_registry_contracts.ex`

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
- Accepted-state contracts, registry capability, and schema export tests passed:
  15 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.AcceptedStateRegistryContracts`
  passed with the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`016060d3` (`Extract accepted state registry contracts`).

Next candidate:
Extract the adjacent `validation_record.v1`, `model_acceptance_report.v1`, and
`validation_safety_case_summary.v1` registry definitions into a focused
validation-acceptance registry module.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,883 to 18,830 lines.
- `AcceptedStateRegistryContracts` is 62 lines.
- Published candidate-refresh registry extraction: `104b0b34`.
