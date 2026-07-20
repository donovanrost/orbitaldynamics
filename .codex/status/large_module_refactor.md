# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-feedback schema-provider extraction.

Status:
Completed and verified.

Selected boundary:
Move the operational-feedback, timeline-feedback provenance, and
timeline-feedback row builders from the public `Schema` facade into a new
`TimelineFeedbackSchemaProviders` owner. Merge its three lazy providers into
the property context and pass facade-owned realized/planned activity,
timeline/activity context, protection, and capability dependencies as explicit
callbacks.

Selection evidence:
- The public `Schema` facade remains 1,559 lines.
- All three builders are referenced only by the property provider registry and
  form one cohesive operational/timeline-feedback schema cluster.
- Common JSON-schema fragments and timeline-context builders already have
  focused owners and can remain direct dependencies.
- Facade-owned recursive builders and imported capability metadata can remain
  lazy through explicit callbacks.

Implementation:
Selected in `3f40aab2` and implemented in `937ea42d`. Added the 57-line
`TimelineFeedbackSchemaProviders` owner, merged its three lazy providers into
the schema property context, and retained facade-owned realized/planned
activity, timeline/activity context, protection, and capability dependencies
behind explicit callbacks. The public `Schema` facade moved from 1,559 to
1,524 lines.

Verification:
- Exact comparison passed for all three provider keys and outputs using the
  real capability contract and sentinel recursive schemas.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `TimelineFeedbackSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,117 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline-feedback schema-provider extraction, selected in `3f40aab2` and
implemented in `937ea42d`. The public `Schema` facade moved from 1,559 to 1,524
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
