# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operator-review row schema-provider completion.

Status:
Completed and verified.

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
Selected in `0d1049c0` and implemented in `b238573d`. Expanded
`OperatorReviewSchemaProviders` to own the lazy row provider and its ordered
schema/property provider assemblies, keeping focused dependencies direct and
facade-recursive schemas behind explicit callbacks. The public `Schema` facade
moved from 1,443 to 1,391 lines.

Verification:
- Provider registration retains exactly one operator-review row key and does
  not invoke callbacks during context construction.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export, including the composed operator-review
  package, regenerated with no diff.
- Runtime xref retains one direct `Schema` -> `OperatorReviewSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,120 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Operator-review row schema-provider completion, selected in `0d1049c0` and
implemented in `b238573d`. The public `Schema` facade moved from 1,443 to 1,391
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
