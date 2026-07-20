# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common number-array primitive direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the zero-context, one-hop CommonJsonSchema number-array helper. Route
its nine eager and lazy consumers directly to
`CommonJsonSchema.number_array/0`. Keep string-array, probability, count-map,
and context-bearing helpers, schema composition, executable validation, and
all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 5,997 lines.
- The helper calls the same-arity zero-context CommonJsonSchema API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Exact-name counting confirms nine consumers; two earlier substring matches
  were the distinct number-or-number-array provider key.
- Exact number-array schemas, callback timing, composed JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema common number-or-string primitive direct routing, selected in
`dcde91be` and implemented in `80b48d2c`.
`schema.ex` moved from 6,001 to 5,997 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
