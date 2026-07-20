# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Common fragment schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Operational-readiness schema-provider extraction, selected in `7ceaedd3` and
implemented in `11b69418`. The public `Schema` facade moved from 959 to 947
lines.

Next candidate:
Implement and verify the selected common-fragment provider extraction, then
extract the remaining handoff-property trio.

Blocked:
No.
