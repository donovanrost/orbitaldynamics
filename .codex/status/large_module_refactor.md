# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Execution-review row schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline-feedback schema-provider extraction, selected in `3f40aab2` and
implemented in `937ea42d`. The public `Schema` facade moved from 1,559 to 1,524
lines.

Next candidate:
Implement and verify the selected execution-review row provider extraction,
then re-rank the remaining public-facade provider clusters.

Blocked:
No.
