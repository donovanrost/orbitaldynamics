# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-planning schema-provider extraction.

Status:
Completed and pushed.

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
Selected in `a016943e` and implemented in `2616d693`.
The new `ContactPlanningSchemaProviders.build/2` returns two lazy provider
closures for contact-intent and proposed-contact rows. `Schema` removes the two
registry-local captures and private builders, then passes timeline, policy,
source-window, model-limit, and cadence-import dependencies as callbacks when
merging the focused provider map.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- Direct comparison confirmed the extracted provider map has the exact two
  keys and produces outputs exactly equal to the original builders.
- Xref reports one runtime edge from `Schema` to the new provider owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,115 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,629 to 1,619 lines; the new focused
  owner is 41 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Contact-planning schema-provider extraction, selected in `a016943e` and
implemented in `2616d693`. The public `Schema` facade moved from 1,629 to 1,619
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
