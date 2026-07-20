# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema non-negative integer property routing.

Status:
Selected; implementation not started.

Selected boundary:
Route the sole `non_negative_integer_property_schemas/1` pipeline directly to
`CommonJsonSchema.non_negative_integer_properties/1` and remove the
zero-context facade helper. Preserve input fields, property-map shape, public
Schema APIs, generated JSON Schema, executable validation, and checked-in
exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,923 lines; the other
  targeted public facades are now 164 to 524 lines.
- Exact static inspection finds one eager piped consumer.
- The helper forwards its sole argument unchanged to the owner with no facade
  state, guards, defaults, transformation, or caching.
- Direct pipeline routing preserves the same field-list value and evaluation
  timing.
- Context-bearing shared-schema helpers remain out of scope.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema enum count-map callback routing, selected in `4942b4a7` and implemented
in `2a080032`.
`schema.ex` moved from 5,927 to 5,923 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
