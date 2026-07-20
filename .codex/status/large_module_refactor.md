# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema relay-data-path status ownership.

Status:
Completed and pushed.

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
Moved the three relay custody/latency/risk status enum functions into
RelayDataPathSummaryJsonSchema and routed the facade's row-builder captures
directly to that owner.
`schema.ex` moved from 6,145 to 6,141 lines; the relay schema owner moved from
263 to 267 lines.

Verification:
- Strict focused communications/report-fixture/export baseline before move:
  27 passed.
- The same strict focused suite after move: 27 passed.
- Strict full schema-export task plus adjacent fixture-visibility,
  candidate-refresh provenance, and validation coverage: 5 passed.
- `mix xref callers
  OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema` reports the expected
  `schema.ex` and standalone communications property-dispatch callers.
- Static search confirms all three facade enum definitions and indirect
  captures are gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `2e5c6ea9` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback timing, enum values and ordering, generated JSON
Schema, validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema relay-data-path status ownership, selected in `90b69684` and
implemented in `2e5c6ea9`.
`schema.ex` moved from 6,145 to 6,141 lines; the relay schema owner moved from
263 to 267 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
