# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common assumptions direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop boolean-constant and string-constant
assumptions helpers.
Route the two timeline-preservation callers and the lazy timeline-activity
callback directly to CommonJsonSchema.
Keep preservation contract selection, assumption input values, property
dispatch, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,114 lines.
- Both helpers forward their only argument to same-arity CommonJsonSchema
  owner APIs without guards, defaults, or transformation.
- The string helper has two preservation callers; the boolean helper has one
  lazy property-dispatch callback.
- Exact assumption keys/values and ordering, lazy callback timing, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema candidate-rejection model-limit ownership, selected in `86e3c44c` and
implemented in `bd871a8c`.
`schema.ex` moved from 6,123 to 6,114 lines; the candidate-rejection report
schema owner moved from 274 to 283 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
