# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: station-calendar registry extraction.

Status:
Ready to publish.

Selected slice:
Move the station-calendar provider, report, and precedence summary into
`Schema.StationCalendarRegistryContracts`.

Why this slice:
The adjacent provider/report/precedence definitions form one complete nested
station-calendar family with direct station-provider/communications/export coverage.

Current coupling/problem:
Declarative station-calendar contract data remains embedded in the large
public `Schema` facade even though it can be merged as one focused registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.StationCalendarRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/station_calendar_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/station_provider_contracts_test.exs`
- `test/orbital_dynamics/schema/communications_contracts_test.exs`
- `test/orbital_dynamics/schema/communications_report_fixtures_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/export tests pass, and the exact contracts/bundle
fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/station_calendar_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, station-calendar validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Station-provider contracts, communications contracts/fixtures, registry
  capability, and schema export tests passed: 27 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`1f491725` (`Update station reservation handoff`).

Next candidate:
Assess the adjacent contact-contention resolution report and summary contracts
as one cohesive registry extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 16,032 to 15,947 lines.
- `StationCalendarRegistryContracts` is 85 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
