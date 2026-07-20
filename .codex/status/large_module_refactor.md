# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operator-review row schema-provider completion.

Status:
Selected; implementation pending.

Selected boundary:
Move the operator-review row builder and schema-provider assembly from the
public `Schema` facade into the existing `OperatorReviewSchemaProviders` owner.
Merge its lazy row provider into the property context, keep common/focused
dependencies direct, and pass facade-recursive schema dependencies as explicit
callbacks.

Selection evidence:
- The public `Schema` facade remains 1,443 lines.
- The row builder and schema-provider assembler are private and used only by
  the operator-review registry provider.
- Common fragments and focused planning/ground-network/candidate-diff helpers
  already have stable direct owners.
- Capability values and facade-recursive schemas can preserve provider laziness
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
Operator-review property-provider extraction, selected in `51722a64` and
implemented in `ba053c59`. The public `Schema` facade moved from 1,455 to 1,443
lines.

Next candidate:
Implement and verify the selected operator-review row/schema-provider
completion, then re-rank the remaining public-facade clusters.

Blocked:
No.
