# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection pressure classification extraction.

Status:
Complete and published.

Selected slice:
Extract flow-row pressure classification behind a focused internal module and
remove the station-calendar context callback bag.

Why this slice:
The cohesive pressure-kind cluster is used throughout the 658-line parent and
forwarded into the station-calendar child solely through callbacks.

Current coupling/problem:
Station-calendar context derivation cannot classify rows without a parent-owned
callback, while the same private classification is repeated across parent paths.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema/resource_projection_flow_summary_count_contracts.ex`
- `lib/orbital_dynamics/schema/resource_projection_pressure_contracts.ex`
- `lib/orbital_dynamics/schema/resource_projection_station_calendar_context_contracts.ex`

Definition of done:
The parent delegates pressure row/type/kind classification, station-calendar
context has direct pressure/aggregation dependencies, its callback bag is gone,
and focused projection/export/fingerprint/xref gates pass.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/resource_projection_test.exs:2210 test/orbital_dynamics/resource_projection_test.exs:4099 test/orbital_dynamics/resource_projection_test.exs:4937 test/orbital_dynamics/schema/resource_contracts_test.exs:746 test/orbital_dynamics/schema_export_test.exs`
  (7 passed, 51 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.ResourceProjectionPressureContracts`
- Focused xref graphs for the parent and station-calendar child
- `mix format --check-formatted`
- `git diff --check`
- `git diff --no-index --check -- /dev/null lib/orbital_dynamics/schema/resource_projection_pressure_contracts.ex`

Verification gaps:
- Full suite not run.

Last commit:
`6028bf2e` (`Extract resource projection pressure contracts`).

Next candidate:
Adopt the shared pressure and stable aggregation contracts in
`ResourceProjectionReportCountContracts`; keep mixed activity-context deferred.

Blocked:
No.

Notes:
- Starting point: the flow-summary count validator is 658 lines; the
  station-calendar context validator is 60 lines.
- Ending point: the parent is 596 lines, the child is 54 lines, and the new
  pressure classifier is 59 lines.
- The generated schema export was byte-for-byte unchanged.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
