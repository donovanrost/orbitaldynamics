# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-feedback capability routing.

Status:
Selected; implementation not started.

Selected boundary:
Route the Schema facade's three remaining direct
`TimelineFeedback.capabilities/0` dependencies through the existing
`TimelineCapabilityContext.timeline_capabilities/0` owner.
Keep timeline-feedback property dispatch, row schema construction, validation,
and all public facades in their current owners.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,187 lines.
- Two lazy property-dispatch callbacks and one row-schema value still query
  TimelineFeedback capabilities directly even though
  `timeline_capabilities/0` is already imported from the dedicated owner.
- Focused function captures and a focused value call complete the facade's
  timeline capability routing while preserving callback timing and per-call
  evaluation.
- Exact capability values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema contact-allocation capability callback routing, selected in `343d06ea`
and implemented in `760401de`.
`schema.ex` moved from 6,188 to 6,187 lines; the existing
ContactAllocationCapabilityContext owner moved from 138 to 142 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
