# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Execution-review row schema-provider extraction.

Status:
Completed and verified.

Selected boundary:
Move the maneuver-review and command-window row builders from the public
`Schema` facade into a new `ExecutionReviewSchemaProviders` owner. Merge its
two lazy providers into the property context and pass facade-owned activity
context and policy-decision dependencies as explicit callbacks.

Selection evidence:
- The public `Schema` facade remains 1,524 lines.
- Both row builders are referenced only by the property provider registry and
  form a cohesive execution-review schema cluster.
- Stable-ID and numeric-triplet fragments already have focused owners and can
  remain direct dependencies.
- Activity-context and policy-decision construction can remain lazy through
  explicit callbacks.

Implementation:
Selected in `0037d37c` and implemented in `6477c809`. Added the 26-line
`ExecutionReviewSchemaProviders` owner, merged its two lazy providers into the
schema property context, and retained facade-owned activity-context and
policy-decision construction behind explicit callbacks. The public `Schema`
facade moved from 1,524 to 1,513 lines.

Verification:
- Exact comparison passed for both provider keys and outputs with sentinel
  activity-context and policy-decision schemas.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `ExecutionReviewSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,118 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Execution-review row schema-provider extraction, selected in `0037d37c` and
implemented in `6477c809`. The public `Schema` facade moved from 1,524 to 1,513
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
