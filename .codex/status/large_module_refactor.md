# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common probability primitive direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the zero-context, one-hop CommonJsonSchema probability helper. Route
its twelve eager and lazy consumers directly to
`CommonJsonSchema.probability/0`. Keep string-array, count-map, and
context-bearing helpers, schema composition, executable validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 5,993 lines.
- The helper calls the same-arity zero-context CommonJsonSchema API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Consumer counting confirms twelve routes; three provider-map lines contain
  the identifier twice as both stable key and callback value.
- Exact probability schemas, callback timing, composed JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema common number-array primitive direct routing, selected in `dc5a34f8`,
boundary count corrected in `46c496f2`, and implemented in `3f6643ad`.
`schema.ex` moved from 5,997 to 5,993 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
