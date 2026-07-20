# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Execution-state plan-delta schema-provider expansion.

Status:
Completed and verified.

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
Selected in `b1408ab2` and implemented in `28163ce7`. Expanded the existing
`ExecutionStateSchemaProviders` owner from four to five lazy providers and
retained planned/realized activity, timeline-link, and activity-context
construction behind explicit callbacks. The public `Schema` facade moved from
1,458 to 1,455 lines.

Verification:
- Exact comparison passed for the moved plan-delta output and confirmed all
  five execution-state provider keys.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref retains one direct `Schema` -> `ExecutionStateSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,119 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Execution-state plan-delta schema-provider expansion, selected in `b1408ab2`
and implemented in `28163ce7`. The public `Schema` facade moved from 1,458 to
1,455 lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
