# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar model-context consolidation.

Status:
Selected; implementation not started.

Selected boundary:
Move the station-calendar report model constant into the existing
`OrbitalDynamics.Schema.StationCalendarCapabilityContext`.
Route the Schema facade's report-model callback and
StationReservationValidation's private model/model-limit helpers through that
owner.
Keep station-calendar/station-reservation property dispatch, schema
construction, executable validators, and all public facades in their current
modules.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,141 lines.
- The facade owns the report-model constant, while
  StationReservationValidation independently defines the same constant and
  re-derives model limits directly from StationCalendar capabilities.
- StationCalendarCapabilityContext already owns the capability accessor and
  exact report model-limit projection, making it the cohesive shared owner.
- Exact model string, model-limit conversion and ordering, callback timing,
  generated JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema relay-data-path status ownership, selected in `90b69684` and
implemented in `2e5c6ea9`.
`schema.ex` moved from 6,145 to 6,141 lines; the relay schema owner moved from
263 to 267 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
