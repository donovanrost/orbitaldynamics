# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema enum count-map callback routing.

Status:
Completed and pushed.

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
Routed all three arity-one enum count-map callbacks directly to
CommonJsonSchema and removed the zero-context facade helper. `schema.ex` moved
from 5,927 to 5,923 lines.

Verification:
- Strict focused JSON Schema export, communications, and timeline-report
  baseline before routing: 31 passed.
- The same strict focused suite after routing: 31 passed.
- Strict checked-in export, resource, and review/import handoff coverage:
  13 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms three direct owner callbacks and zero
  remaining facade helper references.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- `git diff --check` passed.
- Strict forced compile passed across 4,072 files.
- Implementation commit `2a080032` pushed to `main`.

Behavior/schema changes:
None. Supplied enum values, count-map shape, callback timing, public Schema
APIs, executable validation, and checked-in exports remain unchanged.

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
