# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Ground-network row schema-provider expansion.

Status:
Selected; implementation pending.

Selected boundary:
Move the relay-data-path and provider-counteroffer row builders from the public
`Schema` facade into the existing `GroundNetworkSchemaProviders` owner. Expand
its lazy provider map while reusing the existing stable-ID and station-calendar
dependencies.

Selection evidence:
- The public `Schema` facade remains 1,511 lines.
- Both row builders are referenced only by the property provider registry and
  belong with the six ground-network providers already extracted.
- Relay-data-path fragments already have focused schema owners and need only
  the stable-ID pattern.
- Provider-counteroffer construction can reuse the existing lazy
  station-calendar capability callback.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Validation batch schema-provider expansion, selected in `f595c7b7` and
implemented in `08b4a9b0`. The public `Schema` facade moved from 1,513 to 1,511
lines.

Next candidate:
Implement and verify the selected ground-network provider expansion, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
