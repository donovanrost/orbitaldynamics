# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operator-review property-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the operator-review row property-provider assembly from the public
`Schema` facade into a new `OperatorReviewSchemaProviders` owner. Keep
branch-scoped, authority, and resource-variance properties with their focused
owners while passing facade-owned handoff/scoped properties as explicit
callbacks.

Selection evidence:
- The public `Schema` facade remains 1,455 lines.
- The property-provider assembler is private and used only by the
  operator-review row builder.
- Three property families already have focused owners and can become direct
  owner dependencies.
- The remaining facade-owned handoff/scoped properties can preserve laziness
  through explicit callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Execution-state plan-delta schema-provider expansion, selected in `b1408ab2`
and implemented in `28163ce7`. The public `Schema` facade moved from 1,458 to
1,455 lines.

Next candidate:
Implement and verify the selected operator-review property-provider
extraction, then assess the remaining row/schema-provider half.

Blocked:
No.
