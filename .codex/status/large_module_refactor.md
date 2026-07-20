# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common numeric-map primitive direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the two zero-context, one-hop CommonJsonSchema helpers for unconstrained
and non-negative numeric maps. Route their twelve consumers directly to the
same owner APIs. Keep count maps, higher-fanout array/scalar primitives,
context-bearing helpers, schema composition, executable validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,006 lines.
- Both helpers call same-arity zero-context CommonJsonSchema APIs and add no
  facade state, guards, defaults, transformation, or caching.
- Their eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Exact numeric-map schemas, callback timing, composed JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema low-fanout common primitive direct routing, selected in `a00982aa` and
implemented in `68269a68`.
`schema.ex` moved from 6,024 to 6,006 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
