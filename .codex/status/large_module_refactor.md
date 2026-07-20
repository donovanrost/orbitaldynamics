# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common number-or-string primitive direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the zero-context, one-hop CommonJsonSchema number-or-string helper.
Route its ten eager and lazy consumers directly to
`CommonJsonSchema.number_or_string/0`. Keep array, probability, count-map, and
context-bearing helpers, schema composition, executable validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,001 lines.
- The helper calls the same-arity zero-context CommonJsonSchema API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Exact number-or-string schemas, callback timing, composed JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema common numeric-map primitive direct routing, selected in `32ff8955` and
implemented in `6fa1f6a9`.
`schema.ex` moved from 6,006 to 6,001 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
