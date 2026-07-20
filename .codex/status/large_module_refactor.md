# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-planning schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the resource-projection row/flow, suppressed-candidate, and
resource-summary-row provider builders plus the private suppression-reason
combiner from the public `Schema` facade into a new
`ResourcePlanningSchemaProviders` owner. Merge its lazy provider map into the
existing property context.

Selection evidence:
- The public `Schema` facade remains 1,768 lines.
- The four schema builders are referenced only by the property provider
  registry; the suppression-reason combiner is used only inside this cluster.
- They form a cohesive resource planning/filtering boundary spanning
  projection, flow, suppression, and summary rows.
- Source-window, approval/policy, and filter-reason dependencies can remain
  lazy through explicit callbacks.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Execution-state schema-provider extraction, selected in `ce29ff10` and
implemented in `b6901070`. The public `Schema` facade moved from 1,813 to 1,768
lines.

Next candidate:
Implement and verify the selected resource-planning provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
