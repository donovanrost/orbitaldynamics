# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Execution-state plan-delta schema-provider expansion.

Status:
Selected; implementation pending.

Selected boundary:
Move the plan-delta builder from the public `Schema` facade into the existing
`ExecutionStateSchemaProviders` owner. Expand its lazy provider map and pass
planned/realized activity, timeline-link, and activity-context dependencies as
explicit callbacks.

Selection evidence:
- The public `Schema` facade remains 1,458 lines.
- The plan-delta builder is referenced only by the property provider registry
  and belongs with the four execution-state providers already extracted.
- `CampaignRepairJsonSchema` already owns the plan-delta shape.
- Recursive facade-owned activity and timeline schemas can remain lazy through
  explicit callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline edge-row schema-provider extraction, selected in `921b0798` and
implemented in `58ecc07d`. The public `Schema` facade moved from 1,491 to 1,458
lines.

Next candidate:
Implement and verify the selected execution-state provider expansion, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
