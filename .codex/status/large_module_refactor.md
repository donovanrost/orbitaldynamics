# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operator-review property-provider extraction.

Status:
Completed and verified.

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
Selected in `51722a64` and implemented in `ba053c59`. Added the 35-line
`OperatorReviewSchemaProviders` owner for the ordered property-provider
assembly, retaining eight facade-owned handoff/scoped property families behind
explicit callbacks. The public `Schema` facade moved from 1,455 to 1,443 lines.

Verification:
- Exact comparison passed for all 11 ordered property-provider keys and
  outputs, including eight callback-backed families.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `OperatorReviewSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,120 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Operator-review property-provider extraction, selected in `51722a64` and
implemented in `ba053c59`. The public `Schema` facade moved from 1,455 to 1,443
lines.

Next candidate:
Assess and extract the remaining operator-review row/schema-provider half in a
bounded callback-preserving slice.

Blocked:
No.
