# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema numeric-triplet primitive routing.

Status:
Completed and pushed.

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
Added `CommonJsonSchema.numeric_triplet/0`, routed six lazy callbacks and five
eager consumers directly to that owner, and removed the zero-context facade
helper. `schema.ex` moved from 5,919 to 5,913 lines.

Verification:
- Strict focused JSON Schema export, maneuver, feedback, and operator-review
  baseline before routing: 24 passed.
- The same strict focused suite after routing: 24 passed.
- Strict checked-in export, timeline-report, resource, and review/import
  handoff coverage: 21 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms six direct lazy callbacks, five direct eager
  calls, and zero facade helper references.
- `git diff --check` passed.
- Strict forced compile passed across 4,072 files.
- Implementation commit `1537a415` pushed to `main`.

Behavior/schema changes:
None. Numeric item type, three-item minimum and maximum, callback timing,
public Schema APIs, executable validation, and checked-in exports remain
unchanged.

Last completed slice:
Schema numeric-triplet primitive routing, selected in `01c64f0e` and
implemented in `1537a415`.
`schema.ex` moved from 5,919 to 5,913 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
