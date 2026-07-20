# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Common fragment schema-provider extraction.

Status:
Completed and verified.

Selected boundary:
Move SHA-256, stable-ID array, stable-ID array-map, and nested stable-ID
array-map registry adapters from the public `Schema` facade into a new
`CommonSchemaProviders` owner and merge its four lazy providers into the
property context.

Selection evidence:
- The public `Schema` facade remains 947 lines.
- All four helpers are now referenced only by the registry provider map.
- Their shapes already belong to `CommonJsonSchema`.
- The owner needs only stable-ID and SHA-256 pattern values, with no recursive
  facade callbacks.

Implementation:
Selected in `45170a81` and implemented in `8121e5bf`. Added the 21-line
`CommonSchemaProviders` owner with four lazy common-fragment registry adapters
and merged its provider context. The public `Schema` facade moved from 947 to
934 lines.

Verification:
- Exact comparison passed for all four common-provider keys and outputs.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `CommonSchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,128 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Common fragment schema-provider extraction, selected in `45170a81` and
implemented in `8121e5bf`. The public `Schema` facade moved from 947 to 934
lines.

Next candidate:
Extract the remaining link/feedback/thermal handoff-property trio.

Blocked:
No.
