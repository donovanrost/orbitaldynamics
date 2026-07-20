# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence-import capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the CadenceImport capability accessor, model-limit projection, and
supported-source accessor into
`OrbitalDynamics.Schema.CadenceImportCapabilityContext`.
Route the Schema facade's existing property dispatch, manifest/source-review
schema builders, and manifest/row validation through those three focused
internal APIs.
Keep all consuming schema construction, property dispatch, validation
ownership, and public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,183 lines.
- CadenceImport capability data is fetched directly at six schema and
  validation call sites for the whole capability map, model limits, and
  supported source values.
- The selected code has one responsibility: expose schema-facing
  CadenceImport capability context to otherwise independent consumers.
- The three focused accessors replace repeated module coupling while
  preserving per-call capability evaluation. Operational-handoff property
  dispatch, manifest/source-review schema builders, and manifest/row validators
  remain in their current owners.
- Exact atom-to-string conversion, capability values and ordering, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema station-calendar capability-context extraction, selected in `297af482`
and implemented in `786b8553`.
`schema.ex` remains 6,183 lines; the dedicated
StationCalendarCapabilityContext owner is 21 lines and all eight direct
StationCalendar capability dependencies moved behind it.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
