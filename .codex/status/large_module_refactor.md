# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: timeline-transition registry extraction.

Status:
Published.

Selected slice:
Moved `timeline_transition_application_report.v1` and
`timeline_transition_application_summary.v1` definitions into
`Schema.TimelineTransitionRegistryContracts`.

Why this slice:
The two definitions form one report/summary family, with the summary explicitly
nesting the report and shared focused schema coverage.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_transition_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, timeline-transition validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Timeline report/summary contracts, fixture visibility, registry capability,
  and schema export tests passed: 35 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.TimelineTransitionRegistryContracts`
  passed with the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`97d48028` (`Extract timeline transition registry contracts`).

Next candidate:
Assess the adjacent timeline preservation report/status and lifecycle summary
definitions as the next bounded registry family.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,506 to 18,429 lines.
- `TimelineTransitionRegistryContracts` is 86 lines.
- The inline registry remains substantial; this is not a completion claim.
