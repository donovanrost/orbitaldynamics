# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence review row schema-provider completion.

Status:
Selected; implementation pending.

Selected boundary:
Move the cadence-import-manifest row, its private cadence-source-review row,
and both schema-provider assemblies from the public `Schema` facade into the
existing `CadenceReviewSchemaProviders` owner. Merge one lazy manifest provider
into the property context and share the common provider sequence internally
while preserving manifest-only additions.

Selection evidence:
- The public `Schema` facade remains 1,349 lines.
- The source-review row is referenced only by the manifest schema-provider
  assembly, and both private provider lists share most entries in the same
  order.
- Common/focused helpers already have stable direct owners.
- Capability values and facade-recursive schema dependencies can preserve
  laziness through explicit callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Cadence review property-provider deduplication, selected in `82c6235b` and
implemented in `2c854a8c`. The public `Schema` facade moved from 1,391 to 1,349
lines.

Next candidate:
Implement and verify the selected cadence row/schema-provider completion, then
re-rank the remaining public-facade clusters.

Blocked:
No.
