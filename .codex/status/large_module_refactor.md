# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation model ownership.

Status:
Completed and pushed.

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
Moved the three station-reservation report model values into
StationReservationReportJsonSchema and routed both the property-dispatch
callback and report validation directly to that owner.
`schema.ex` moved from 6,131 to 6,123 lines; the report schema owner moved from
188 to 196 lines.

Verification:
- Strict focused station-provider/communications/report-fixture/export
  baseline before move: 33 passed.
- The same strict focused suite after move: 33 passed.
- Strict full schema-export task plus adjacent operator-review,
  Cadence-import, fixture-visibility, and validation coverage: 10 passed.
- `mix xref callers
  OrbitalDynamics.Schema.StationReservationReportJsonSchema` reports the
  expected `schema.ex` and GroundNetworkReportPropertyDispatch callers.
- Static search confirms the facade model function and both indirect consumers
  are gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `a94ebd9f` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback timing, model values and ordering, generated
JSON Schema, validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema station-reservation model ownership, selected in `d94ecb41` and
implemented in `a94ebd9f`.
`schema.ex` moved from 6,131 to 6,123 lines; the station-reservation report
schema owner moved from 188 to 196 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
