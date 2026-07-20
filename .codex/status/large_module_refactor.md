# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-feedback schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Strategy schema-provider extraction, selected in `a27dfb35` and implemented in
`5aa56ba5`. The public `Schema` facade moved from 1,606 to 1,559 lines.

Next candidate:
Implement and verify the selected timeline-feedback provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
