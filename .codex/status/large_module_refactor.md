# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection projected-resource row callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace all projected-resource row callbacks with direct primitive and
stable-ID support.

Why this slice:
All seven callbacks map to existing support, with focused invalid stable-ID and
resource-projection row tests covering the moved behavior.

Current coupling/problem:
The schema facade assembles a seven-function bag for a cohesive leaf validator
that needs no facade-owned artifact-family behavior.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_flow_projected_resource_contracts.ex`

Definition of done:
The facade callback bag and leaf wrappers are gone, focused row/export tests and
the fingerprint pass, and xref shows direct primitive/stable-ID dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/schema/resource_contracts_test.exs:6 test/orbital_dynamics/resource_projection_test.exs:4099 test/orbital_dynamics/resource_projection_test.exs:4937 test/orbital_dynamics/schema_export_test.exs`
  (6 passed, 52 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.ResourceProjectionFlowProjectedResourceContracts`
- Focused xref graph for the projected-resource row validator
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`1d64ef3c` (`Collapse projected resource callbacks`).

Next candidate:
Remove primitive/stable callback wrappers from realized spacecraft-state rows;
keep campaign strategy and mixed activity-context deferred.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,130 lines; the projected-resource row
  validator is 63 lines.
- Ending point: `schema.ex` is 14,117 lines and the projected-resource row
  validator is 38 lines.
- The generated schema export was byte-for-byte unchanged.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
