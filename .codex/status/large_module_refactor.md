# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-planning schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the contact-intent-row and proposed-contact-row builders from the public
`Schema` facade into a new `ContactPlanningSchemaProviders` owner. Merge its
two lazy providers into the existing property context and pass timeline,
policy, source-window, and cadence-import dependencies as callbacks.

Selection evidence:
- The public `Schema` facade remains 1,629 lines.
- Both row builders are referenced only by the property provider registry and
  form one contact intent/proposal boundary.
- Their timeline identity, approval/policy, source-window, model-limit, and
  cadence-import dependencies can remain lazy through explicit callbacks.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Candidate-diff schema-provider extraction, selected in `5fe7d9ee` and
implemented in `36b93af7`. The public `Schema` facade moved from 1,648 to 1,629
lines.

Next candidate:
Implement and verify the selected contact-planning provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
