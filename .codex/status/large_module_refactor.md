# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: planned-activity registry extraction.

Status:
Published.

Selected slice:
Move the planned-activity contract into
`Schema.PlannedActivityRegistryContracts`.

Why this slice:
It was the final inline contract in the facade's base registry and has direct
validation, JSON-schema, capability, and export coverage.

Current coupling/problem:
Resolved for the declarative registry: all executable contract definitions now
come from focused registry modules rather than an inline facade map.

Public facade preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Extraction target:
`OrbitalDynamics.Schema.PlannedActivityRegistryContracts.contracts/0`.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/planned_activity_registry_contracts.ex`

Behavior/schema changes:
None. Registry contents, planned-activity validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Planned-activity validation/schema, public capabilities, direct registry, and
  schema export tests passed: 16 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file review, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`84f633e9` (`Extract planned activity registry contract`).

Next candidate:
Assess the generic validation-helper tail beginning with `validate_rows/4` as a
cohesive internal support extraction now that the inline registry is exhausted.

Blocked:
No.

Notes:
- `schema.ex` decreased from 15,173 to 15,096 lines.
- `PlannedActivityRegistryContracts` is 82 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
