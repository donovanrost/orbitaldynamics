# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection flow-summary stable aggregation ownership cleanup.

Status:
Complete and published.

Selected slice:
Move the exact stable-value sorting/grouping behavior into shared collection
aggregation support and remove the ignored/data-volume/latency callback bags.

Why this slice:
Three small aggregators receive only duplicated stable-value helpers from their
700-line parent, and focused resource-projection tests cover every derived field.

Current coupling/problem:
The parent count validator assembles three callback bags solely to expose its
private stable sorting/grouping helpers to cohesive child modules.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema/collection_aggregation.ex`
- `lib/orbital_dynamics/schema/resource_projection_flow_summary_count_contracts.ex`
- `lib/orbital_dynamics/schema/resource_projection_flow_summary_data_volume_contracts.ex`
- `lib/orbital_dynamics/schema/resource_projection_flow_summary_ignored_contracts.ex`
- `lib/orbital_dynamics/schema/resource_projection_flow_summary_latency_contracts.ex`

Definition of done:
The three callback bags and child wrappers are gone, the parent uses the same
shared exact aggregation behavior, focused projection/export tests and the
fingerprint pass, and xref shows direct collection dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/resource_projection_test.exs:1993 test/orbital_dynamics/resource_projection_test.exs:4937 test/orbital_dynamics/schema/resource_contracts_test.exs:746 test/orbital_dynamics/schema_export_test.exs`
  (6 passed, 52 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.CollectionAggregation`
- Focused `mix xref graph --source ... --format plain` for the parent and all
  three child aggregators
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`c3add983` (`Centralize flow summary aggregation`).

Next candidate:
Extract flow-summary pressure classification so station-calendar context can
drop its remaining callback bag; keep mixed activity-context deferred.

Blocked:
No.

Notes:
- Starting point: the flow-summary count validator is 694 lines; its three
  child aggregators total 98 lines.
- Ending point: the parent is 658 lines and the child aggregators total 81
  lines; exact stable aggregation now lives in `CollectionAggregation`.
- The generated schema export was byte-for-byte unchanged.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
