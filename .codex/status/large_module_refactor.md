# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence-import capability-context extraction.

Status:
Completed and pushed.

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
Added `OrbitalDynamics.Schema.CadenceImportCapabilityContext`, which now owns
the CadenceImport capability accessor, model-limit projection, and
supported-source accessor. The Schema facade routes all six former direct
capability dependencies through those three focused APIs.
`schema.ex` moved from 6,183 to 6,184 lines because the explicit import is one
line larger than the removed helper/direct-call surface; the dedicated owner
is 17 lines.

Verification:
- Strict focused Cadence-import/Cadence-row/export/validation-evidence baseline
  before extraction: 23 passed.
- The same strict focused suite after extraction: 23 passed.
- Strict schema and manifest export tasks plus adjacent operator-review,
  candidate-refresh provenance, and fixture-visibility coverage: 7 passed.
- `mix xref callers
  OrbitalDynamics.Schema.CadenceImportCapabilityContext` reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,059 files.
- Implementation commit `cf79b647` pushed to `main`.

Behavior/schema changes:
None. Public facades, per-call capability evaluation, model-limit conversion,
supported-source ordering, generated JSON Schema, validation behavior, and
checked-in exports remain unchanged.

Last completed slice:
Schema Cadence-import capability-context extraction, selected in `aa124857`
and implemented in `cf79b647`.
`schema.ex` moved from 6,183 to 6,184 lines; the dedicated
CadenceImportCapabilityContext owner is 17 lines and all six direct
CadenceImport capability dependencies moved behind it.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
