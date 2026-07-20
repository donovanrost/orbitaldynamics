# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence review row schema-provider completion.

Status:
Completed and verified.

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
Selected in `b23e0d78` and implemented in `9b951825`. Expanded
`CadenceReviewSchemaProviders` to own the lazy manifest row, its private
source-review row, shared source provider sequence, ordered manifest-only
insertions, and shared property providers. The public `Schema` facade moved
from 1,349 to 1,216 lines.

Verification:
- Provider registration retains exactly one cadence-import manifest row key and
  does not invoke callbacks during context construction.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export, including both nested cadence row shapes,
  regenerated with no diff.
- Runtime xref retains one direct `Schema` -> `CadenceReviewSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,121 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Cadence review row schema-provider completion, selected in `b23e0d78` and
implemented in `9b951825`. The public `Schema` facade moved from 1,349 to 1,216
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
