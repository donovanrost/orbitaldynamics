# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema JSON-property router extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Clause order, dispatch-owner calls, contract identities,
field-hint fallback, stable-ID decoration, lazy nested-schema construction,
embedded-contract recursion, public `Schema`, and checked-in exports must remain
unchanged.

Last completed slice:
Schema artifact-validation router extraction, selected in `49196371` and
implemented in `2b8aebb6`. `schema.ex` moved from 3,818 to 3,194 lines.

Next candidate:
Implement and verify the selected JSON-property router, then re-rank the
remaining facade-owned schema-builder/provider blocks.

Blocked:
No.
