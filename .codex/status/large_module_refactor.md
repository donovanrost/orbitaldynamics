# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema enum count-map callback routing.

Status:
Selected; implementation not started.

Selected boundary:
Route the three arity-one `enum_count_map_json_schema/1` callbacks directly to
`CommonJsonSchema.enum_count_map/1` and remove the zero-context facade helper.
Preserve callback timing, supplied enum values, public Schema APIs, generated
JSON Schema, executable validation, and checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,927 lines; the other
  targeted public facades are now 164 to 524 lines.
- Exact static inspection finds three lazy arity-one consumers and no eager
  calls.
- The helper forwards its sole argument unchanged to the owner with no facade
  state, guards, defaults, transformation, or caching.
- The direct owner callback has the same arity and evaluation timing.
- Context-bearing shared-schema helpers remain out of scope.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema trust-boundary status count-map routing, selected in `e71931de` and
implemented in `13ccc089`.
`schema.ex` moved from 5,934 to 5,927 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
