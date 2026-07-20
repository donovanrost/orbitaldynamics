# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the OperatorReview capability accessor, model-limit projection,
source-artifact-type accessor, and review-type accessor into
`OrbitalDynamics.Schema.OperatorReviewCapabilityContext`.
Route the Schema facade's existing operational-handoff property dispatch,
operator-review row schema, and package/row validation through those four
focused internal APIs.
Keep all consuming schema construction, property dispatch, validation
ownership, and public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,184 lines.
- OperatorReview capability data is fetched directly at five schema and
  validation call sites plus the model-limit helper for the whole capability
  map, known limits, source artifact types, and review types.
- The selected code has one responsibility: expose schema-facing
  OperatorReview capability context to otherwise independent consumers.
- The four focused accessors replace repeated module coupling while preserving
  per-call capability evaluation. Operational-handoff dispatch,
  operator-review row schema construction, and package/row validators remain
  in their current owners.
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
Schema Cadence-import capability-context extraction, selected in `aa124857`
and implemented in `cf79b647`.
`schema.ex` moved from 6,183 to 6,184 lines; the dedicated
CadenceImportCapabilityContext owner is 17 lines and all six direct
CadenceImport capability dependencies moved behind it.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
