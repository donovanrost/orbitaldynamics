# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: timeline diff registry extraction.

Status:
Published.

Selected slice:
Moved `timeline_diff_report.v1` and `timeline_diff_summary.v1` definitions into
`Schema.TimelineDiffRegistryContracts`.

Why this slice:
The adjacent report/summary pair forms one nested contract family with direct
focused schema and export coverage.

Current coupling/problem:
Declarative timeline diff contract data remains embedded in the large
public `Schema` facade even though the facade only needs the merged registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.TimelineDiffRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_diff_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/timeline_report_contracts_test.exs`
- `test/orbital_dynamics/schema/timeline_summary_contracts_test.exs`
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
- `lib/orbital_dynamics/schema/timeline_diff_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, timeline diff validation, and generated schemas retain
the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Timeline report/summary contracts, fixture visibility, registry capability,
  and schema export tests passed: 35 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`7f50ce4e` (`Extract timeline diff registry contracts`).

Next candidate:
Assess the adjacent timeline integrity report and dependency impact summary as
the next bounded registry family.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,203 to 18,116 lines.
- `TimelineDiffRegistryContracts` is 96 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.
