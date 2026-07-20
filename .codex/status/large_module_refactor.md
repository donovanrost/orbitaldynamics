# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Approval-requirement JSON-property family routing.

Status:
Selected; implementation pending.

Selected boundary:
Move the approval-requirement property body from
`JsonSchemaPropertyRouter` into the existing
`ReferencePolicyPropertyRouter`. Keep the parent router's exact literal clause
head/order as a delegation.

Selection evidence:
- Only approval requirement and callback-bearing candidate refresh remain as
  domain property bodies in the 572-line parent router.
- The roughly 15-line approval body is part of the policy artifact family
  already owned by `ReferencePolicyPropertyRouter`.
- It reuses that owner's existing shared
  provider/context/fallback support.
- No recursive parent callback, embedded-schema callback, or cross-family
  property lookup is required.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Provider-counteroffer JSON-property family routing, selected in `caa5f091` and
implemented in `37c6d3a7`. The parent router moved from 581 to 572 lines.

Next candidate:
Implement and verify the selected approval family move, then assess the
callback-bearing candidate-refresh route against the public `Schema` facade's
provider-helper boundaries.

Blocked:
No.
