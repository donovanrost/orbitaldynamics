# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Activity schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move candidate/campaign/planned/realized activity and target/ground-station/
spacecraft identity schema builders from the public `Schema` facade into a new
`ActivitySchemaProviders` owner. Build one lazy activity context, merge its
seven registry providers, pass shared closures downstream, and retain the
special public candidate export through a thin owner bridge.

Selection evidence:
- The public `Schema` facade remains 1,161 lines.
- All seven builders are registry providers; only candidate activity also
  serves the special public JSON-schema export clause.
- Identity and activity shape construction already have focused direct owners
  and share the stable-ID pattern.
- Source-window, activity-context, timeline, cadence-import, and uncertainty
  dependencies can preserve laziness through explicit callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Policy schema-provider extraction, selected in `33e14d05` and implemented in
`a90c0166`. The public `Schema` facade moved from 1,176 to 1,161 lines.

Next candidate:
Implement and verify the selected activity provider extraction, then re-rank
the remaining public-facade clusters.

Blocked:
No.
