# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Activity schema-provider extraction.

Status:
Completed and verified.

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
Selected in `d1cb94a8` and implemented in `b2143653`. Added the 82-line
`ActivitySchemaProviders` owner with seven lazy activity/identity closures,
merged its registry providers, passed shared closures downstream, and retained
the special candidate export through a thin owner bridge. The public `Schema`
facade moved from 1,161 to 1,126 lines.

Verification:
- Exact comparison passed for all seven activity-provider keys and outputs
  using sentinel recursive schemas.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `ActivitySchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,124 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Activity schema-provider extraction, selected in `d1cb94a8` and implemented in
`b2143653`. The public `Schema` facade moved from 1,161 to 1,126 lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
