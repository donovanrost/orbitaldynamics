# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Ground-network row schema-provider expansion.

Status:
Completed and verified.

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
Selected in `41412217` and implemented in `a04b1e80`. Expanded the existing
`GroundNetworkSchemaProviders` owner from six to eight lazy providers by moving
the relay-data-path and provider-counteroffer row builders. The public `Schema`
facade moved from 1,511 to 1,491 lines.

Verification:
- Exact comparison passed for both moved outputs and confirmed all eight owner
  keys using the real station-calendar capability contract.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref retains one direct `Schema` -> `GroundNetworkSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,118 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Ground-network row schema-provider expansion, selected in `41412217` and
implemented in `a04b1e80`. The public `Schema` facade moved from 1,511 to 1,491
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
