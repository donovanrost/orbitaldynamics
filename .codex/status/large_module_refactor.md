# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema relay-data-path status ownership.

Status:
Selected; implementation not started.

Selected boundary:
Move the relay custody, latency, and risk status enum functions from the Schema
facade into `OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema`.
Route the relay row builder's three callback captures directly to that owner.
Keep relay property dispatch, row composition, assumptions/model limits,
validation, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,145 lines.
- The three constant enum functions are used only as callbacks for
  RelayDataPathSummaryJsonSchema row construction.
- The row-schema owner already interprets these values and is the cohesive
  location for their schema-facing definitions.
- Exact callback timing, enum values and ordering, generated JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema resource-projection metadata direct routing, selected in `95a1349a`
and implemented in `e188b381`.
`schema.ex` moved from 6,151 to 6,145 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
