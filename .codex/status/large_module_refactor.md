# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline edge-row schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Ground-network row schema-provider expansion, selected in `41412217` and
implemented in `a04b1e80`. The public `Schema` facade moved from 1,511 to 1,491
lines.

Next candidate:
Implement and verify the selected timeline edge-row provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
