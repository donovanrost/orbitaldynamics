# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common count-map primitive direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the zero-context, one-hop CommonJsonSchema non-negative integer
count-map helper. Route its eleven eager and lazy consumers directly to
`CommonJsonSchema.non_negative_integer_count_map/0`. Keep enum count maps,
string arrays, stable-ID helpers, context-bearing helpers, schema composition,
executable validation, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 5,989 lines.
- The helper calls the same-arity zero-context CommonJsonSchema API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Direct call/capture counting confirms eleven consumers.
- Exact count-map schemas, callback timing, composed JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema common probability primitive direct routing, selected in `19648e06`,
boundary count corrected in `7513b2bc`, and implemented in `8237cb9a`.
`schema.ex` moved from 5,993 to 5,989 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
