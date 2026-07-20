# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema numeric-triplet primitive routing.

Status:
Selected; implementation not started.

Selected boundary:
Move the fixed three-number array schema into CommonJsonSchema, route the six
lazy and five eager facade consumers directly to that owner, and remove the
zero-context facade helper. Preserve callback timing, item type and bounds,
public Schema APIs, generated JSON Schema, executable validation, and
checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,919 lines; the other
  targeted public facades are now 164 to 524 lines.
- Exact static inspection finds six lazy callbacks and five eager consumers.
- The helper owns a primitive fixed-length numeric array with no facade state,
  guards, defaults, transformation, or caching.
- CommonJsonSchema already owns the adjacent reusable number-array and numeric
  map primitives.
- Pattern-bearing stable-ID and SHA helpers remain out of scope.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

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
