# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar model-context consolidation.

Status:
Completed and pushed.

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
Added the station-calendar report model to
StationCalendarCapabilityContext, imported it into the Schema facade, and
routed StationReservationValidation's private model/model-limit helpers
through the shared owner.
`schema.ex` moved from 6,141 to 6,140 lines; the capability context moved from
21 to 23 lines. StationReservationValidation remains 51 lines while no longer
duplicating domain model metadata.

Verification:
- Strict focused station-provider/communications/report-fixture/export
  baseline before consolidation: 33 passed.
- The same strict focused suite after consolidation: 33 passed.
- Strict full schema-export task plus adjacent operator-review,
  Cadence-import, fixture-visibility, and validation coverage: 10 passed.
- `mix xref callers
  OrbitalDynamics.Schema.StationCalendarCapabilityContext` reports
  `schema.ex (export)` and `station_reservation_validation.ex (runtime)`.
- Static search confirms neither consumer directly contains the model string
  or queries StationCalendar capabilities.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `26a3fd42` pushed to `main`.

Behavior/schema changes:
None. Public facades, model string, model-limit conversion and ordering,
callback timing, generated JSON Schema, validation behavior, and checked-in
exports remain unchanged.

Last completed slice:
Schema station-calendar model-context consolidation, selected in `e6cebc64`
and implemented in `26a3fd42`.
`schema.ex` moved from 6,141 to 6,140 lines; the station-calendar capability
context moved from 21 to 23 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
