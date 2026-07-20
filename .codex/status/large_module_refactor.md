# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common string-array eager routing.

Status:
Selected; implementation not started.

Selected boundary:
Route the ten remaining eager `string_array_schema/0` calls in Schema directly
to `CommonJsonSchema.string_array/0`, then remove the now-unused facade helper.
Keep the 34 lazy callbacks routed directly to the owner as completed in the
previous slice. Preserve property-provider keys, all public Schema APIs,
generated JSON Schema, executable validation, and checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,986 lines; the other
  targeted public facades are now 164 to 524 lines.
- The prior slice left exactly ten eager calls behind the same zero-arity
  pass-through helper, with no facade state, guards, defaults, transformation,
  or caching.
- Removing the final one-hop helper completes this narrow ownership cleanup
  without broadening into context-bearing Schema helpers.
- Exact string-array schemas, provider maps, composed schemas, validation, and
  checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema common string-array callback routing, selected in `cc4ba93d` and
implemented in `3f3d0363`.
`schema.ex` remains 5,986 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
