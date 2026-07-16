# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: timeline-preservation registry extraction.

Status:
Published.

Selected slice:
Moved `timeline_preservation_report.v1`, `timeline_preservation_status.v1`, and
`timeline_lifecycle_state_summary.v1` definitions into
`Schema.TimelinePreservationRegistryContracts`.

Why this slice:
The three adjacent definitions form a bounded preservation/lifecycle summary
family with shared focused schema and export coverage.

Current coupling/problem:
Declarative timeline-preservation contract data remains embedded in the large
public `Schema` facade even though the facade only needs the merged registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.TimelinePreservationRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_preservation_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/timeline_summary_contracts_test.exs`
- `test/orbital_dynamics/schema/timeline_activity_state_contracts_test.exs`
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
- `lib/orbital_dynamics/schema/timeline_preservation_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, timeline-preservation validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Timeline summary/activity-state contracts, fixture visibility, registry
  capability, and schema export tests passed: 36 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.TimelinePreservationRegistryContracts`
  passed with the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`8b4b738d` (`Extract timeline preservation registry contracts`).

Next candidate:
Assess the adjacent timeline activity status, approval, and lifecycle state
definitions as the next bounded registry family.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,429 to 18,322 lines.
- `TimelinePreservationRegistryContracts` is 118 lines.
- The parent performed the bounded read-only review because subagent delegation
  is unavailable in the active collaboration mode; no must-fix findings remain.
- The parent will perform the exact mechanical publish for the same reason.
- The inline registry remains substantial; this is not a completion claim.
