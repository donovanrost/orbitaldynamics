# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection report-count callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace all report-count callbacks with direct primitive, collection, and
pressure support while removing duplicated pressure/stable helpers.

Why this slice:
All six callbacks map to existing support, and the validator separately
duplicates the pressure and stable aggregation just extracted next door.

Current coupling/problem:
The schema facade still assembles a six-function bag for a cohesive count
validator whose helper ownership is now fully represented by internal modules.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_pressure_contracts.ex`
- `lib/orbital_dynamics/schema/resource_projection_report_count_contracts.ex`

Definition of done:
The facade callback bag and validator wrappers are gone, exact pressure/stable
derivation delegates to shared support, and focused report/export/fingerprint/
xref gates pass.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/resource_projection_test.exs:1689 test/orbital_dynamics/resource_projection_test.exs:2210 test/orbital_dynamics/resource_projection_test.exs:4676 test/orbital_dynamics/resource_projection_test.exs:4937 test/orbital_dynamics/schema/resource_contracts_test.exs:6 test/orbital_dynamics/schema_export_test.exs`
  (8 passed, 50 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.ResourceProjectionReportCountContracts`
- Focused xref graph for the report-count validator
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`7e015529` (`Collapse resource projection count callbacks`).

Next candidate:
Remove primitive/stable callback plumbing from the projected-resource row
validator; keep campaign strategy and mixed activity-context deferred.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,145 lines; the report-count validator is
  361 lines.
- Ending point: `schema.ex` is 14,130 lines and the report-count validator is
  262 lines; pressure first-kind priority remains explicit and unchanged.
- The generated schema export was byte-for-byte unchanged.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
