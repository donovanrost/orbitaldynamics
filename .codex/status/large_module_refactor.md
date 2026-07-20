# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-feedback capability routing.

Status:
Completed and pushed.

Selected boundary:
Route the Schema facade's three remaining direct
`TimelineFeedback.capabilities/0` dependencies through the existing
`TimelineCapabilityContext` owner by adding a distinct
`timeline_feedback_capabilities/0` accessor.
Keep timeline-feedback property dispatch, row schema construction, validation,
and all public facades in their current owners.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,187 lines.
- Two lazy property-dispatch callbacks and one row-schema value still query
  TimelineFeedback capabilities directly even though the dedicated timeline
  capability owner already exists.
- Focused function captures and a focused value call complete the facade's
  timeline capability routing while preserving callback timing and per-call
  evaluation.
- Exact capability values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Added `timeline_feedback_capabilities/0` to TimelineCapabilityContext, routed
its existing feedback model-limit projection through that accessor, and
replaced the facade's two direct callback captures and one direct row-schema
value.
The first uncommitted attempt reused `timeline_capabilities/0`; focused tests
proved that accessor correctly exposes the distinct Timeline domain map, so
the implementation was corrected to preserve TimelineFeedback semantics.
`schema.ex` moved from 6,187 to 6,188 lines; the existing owner moved from 34
to 36 lines.

Verification:
- Strict focused timeline-activity/contact-feedback/export baseline before
  routing: 30 passed.
- After correction, the strict schema portion passed 29 and the strict
  timeline-feedback export task passed 1.
- Strict full schema-export task plus adjacent operational-timeline,
  campaign-repair, and fixture-visibility coverage: 5 passed.
- `mix xref callers OrbitalDynamics.Schema.TimelineCapabilityContext` reports
  only `lib/orbital_dynamics/schema.ex (export)`.
- No direct `TimelineFeedback.capabilities/0` call remains in `schema.ex`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,062 files.
- Implementation commit `d5a9fec1` pushed to `main`.

Behavior/schema changes:
None. Public facades, Timeline versus TimelineFeedback capability semantics,
lazy callback timing, per-call evaluation, generated JSON Schema, validation
behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema timeline-feedback capability routing, selected in `5b92a765` and
implemented in `d5a9fec1`.
`schema.ex` moved from 6,187 to 6,188 lines; the existing
TimelineCapabilityContext owner moved from 34 to 36 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
