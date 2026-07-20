# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema relay-data-path assumptions direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop relay-data-path assumptions helper.
Route the report property-dispatch callback directly to
`RelayDataPathSummaryJsonSchema.assumptions/0`.
Keep property dispatch, relay row schema construction, validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,065 lines.
- The helper calls the same-arity RelayDataPathSummaryJsonSchema owner API
  and adds no guards, defaults, transformation, or caching.
- Its only consumer can capture the owner directly with unchanged lazy
  evaluation.
- Exact assumptions values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema resource-projection assumptions direct routing, selected in `3d0e062a`
and implemented in `35553807`.
`schema.ex` moved from 6,068 to 6,065 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
