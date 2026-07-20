# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation model ownership.

Status:
Selected; implementation not started.

Selected boundary:
Move the station-reservation report model enum from the Schema facade into
`OrbitalDynamics.Schema.StationReservationReportJsonSchema`.
Route both station-reservation property dispatch and report validation
directly to that owner.
Keep property dispatch, contact/contention schema construction, executable
validation ownership, and all public facades in their current modules.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,131 lines.
- The three-value enum feeds exactly one StationReservationReportJsonSchema
  property callback and the station-reservation report model validator.
- The report schema already interprets and emits this enum, making it the
  cohesive shared owner for construction and validation.
- Exact model values and ordering, callback timing, generated JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema provider-counteroffer model ownership, selected in `d997b385` and
implemented in `16d36516`.
`schema.ex` moved from 6,140 to 6,131 lines; the provider-counteroffer report
schema owner moved from 105 to 114 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
