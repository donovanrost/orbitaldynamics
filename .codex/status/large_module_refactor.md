# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema non-negative integer property routing.

Status:
Completed and pushed.

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
Routed the sole non-negative integer property-map pipeline directly to
CommonJsonSchema and removed the zero-context facade helper. `schema.ex` moved
from 5,923 to 5,919 lines.

Verification:
- Strict focused JSON Schema export baseline before routing: 15 passed.
- The same strict focused suite after routing: 15 passed.
- Strict fixture-visibility, optimizer-objective, operator-review,
  timeline-report, and checked-in export coverage: 16 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms one direct owner pipeline and zero remaining
  facade helper references.
- `git diff --check` passed.
- Strict forced compile passed across 4,072 files.
- Implementation commit `4f08c41b` pushed to `main`.

Behavior/schema changes:
None. Input fields, non-negative integer property-map shape, public Schema
APIs, executable validation, and checked-in exports remain unchanged.

Last completed slice:
Schema non-negative integer property routing, selected in `c3a36307` and
implemented in `4f08c41b`.
`schema.ex` moved from 5,923 to 5,919 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
