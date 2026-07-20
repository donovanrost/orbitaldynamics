# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-timeline validation context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Add owner-default required-report, optional-report, and row entry points to
OperationalTimelineValidation. Derive required fields, timeline model limits,
and row callbacks from existing registry/capability/timeline owners, route one
required validation plus two optional callbacks and one row callback directly,
and remove both facade wrappers. Keep the callback-based owner APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,734 lines; the other
  targeted public facades are now 164 to 524 lines.
- The required validator needs only registry required fields, timeline model
  limits, and the operational row validator.
- The row wrapper supplies only TimelineContextValidation owner callbacks.
- Exact usage finds one required report, two optional report callbacks, and one
  row callback.
- Existing registry, capability, and timeline validation owners provide every
  dependency without recursive Schema lookup.
- Owner-default entry points preserve the callback-based APIs.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema maneuver validation context extraction, selected in `9e4614ec` and
implemented in `749ae44e`.
`schema.ex` moved from 5,752 to 5,734 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
