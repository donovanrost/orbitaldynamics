# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection assumptions direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop resource-projection assumptions helper.
Route the report property-dispatch callback directly to
`ResourceProjectionReportJsonSchema.assumptions/0`.
Keep property dispatch, row/flow schema construction, validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,068 lines.
- The helper calls the same-arity ResourceProjectionReportJsonSchema owner API
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
Schema validation-acceptance metadata direct routing, selected in `526b9b0c`
and implemented in `5ec36956`.
`schema.ex` moved from 6,071 to 6,068 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
