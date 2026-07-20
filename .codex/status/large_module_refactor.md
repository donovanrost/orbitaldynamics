# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline edge-row schema-provider extraction.

Status:
Completed and verified.

Selected boundary:
Move the ranked-timeline, candidate-rejection row, lifecycle-state row, and
transition-selected-activity builders from the public `Schema` facade into a
new `TimelineEdgeSchemaProviders` owner. Merge its four lazy providers into the
property context and pass facade-owned activity, context, protection,
capability, model-limit, and decision dependencies as explicit callbacks.

Selection evidence:
- The public `Schema` facade remains 1,491 lines.
- All four builders are referenced only by the property provider registry and
  form a cohesive set of timeline edge/row adapters.
- Common fragments and lifecycle-transition construction already have focused
  owners and can remain direct dependencies.
- Facade-owned activity, protection, capability, limit, and decision values can
  remain lazy through explicit callbacks.

Implementation:
Selected in `921b0798` and implemented in `58ecc07d`. Added the 48-line
`TimelineEdgeSchemaProviders` owner, merged its four lazy providers into the
schema property context, and retained facade-owned activity, context,
protection, capability, model-limit, and decision dependencies behind explicit
callbacks. The public `Schema` facade moved from 1,491 to 1,458 lines.

Verification:
- Exact comparison passed for all four provider keys and outputs with real
  timeline capability/limit/decision callbacks and sentinel recursive schemas.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `TimelineEdgeSchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,119 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline edge-row schema-provider extraction, selected in `921b0798` and
implemented in `58ecc07d`. The public `Schema` facade moved from 1,491 to 1,458
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
