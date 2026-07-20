# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema JSON-property router extraction.

Status:
Implemented and verified.

Selected boundary:
Extract the complete `json_schema_property/3` clause set, generic fallback, and
embedded-contract recursion into a `JsonSchemaPropertyRouter`. Route
`JsonDocument` through the new owner using an explicit lazy provider context
for facade-owned schema builders. Preserve clause order, dispatch-owner calls,
literal contract identities, field-hint fallback, stable-ID decoration, and
recursive embedded-contract behavior.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 3,194 lines.
- Lines 443 through 1,773 are one contiguous property-dispatch responsibility;
  its specialized clauses already delegate to focused property owners.
- The facade still owns roughly 1,330 lines of mechanical contract and field
  routing even though its real ownership is the provider context used by those
  dispatchers.
- The existing `JsonDocument` callback boundary and lazy-provider convention
  allow extraction without changing the public `Schema` API or eagerly building
  unused nested schemas.

Implementation:
- Added `OrbitalDynamics.Schema.JsonSchemaPropertyRouter` as the owner of all
  76 ordered property-dispatch clauses, the field-hint fallback, and recursive
  embedded-contract routing.
- Added one lazy facade context with 99 captured schema providers; it is built
  once per JSON-schema document and does not materialize unused nested schemas.
- Removed property-routing-only aliases and contract attributes from the facade.
- `schema.ex` moved from 3,194 to 1,959 lines; the focused router is 1,326 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST-normalized route-head comparison: all 76 clauses matched the original
  contract/field patterns and order exactly.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the intended runtime property and fallback edges
  from `Schema` to `JsonSchemaPropertyRouter`.
- Formatting, `git diff --check`, provider/context review, and bounded
  source/schema diff review passed.
- Strict compile passed for 4,094 files with warnings as errors.

Behavior/schema changes:
None intended. Clause order, dispatch-owner calls, contract identities,
field-hint fallback, stable-ID decoration, lazy nested-schema construction,
embedded-contract recursion, public `Schema`, and checked-in exports must remain
unchanged.

Last completed slice:
Schema JSON-property router extraction, selected in `db973fb7` and implemented
in `b7196e25`. `schema.ex` moved from 3,194 to 1,959 lines.

Next candidate:
Re-rank the remaining facade-owned schema-builder/provider blocks against the
new 1,326-line property router, favoring cohesive provider families over
mechanical size movement.

Blocked:
No.
