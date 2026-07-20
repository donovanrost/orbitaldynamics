# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar capability-context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract the StationCalendar capability accessor, model-limit projection, and
provider-counteroffer action/state accessors into
`OrbitalDynamics.Schema.StationCalendarCapabilityContext`.
Route the Schema facade's existing schema builders, callback maps, and
operator-review validation through those four focused internal APIs.
Keep all consuming schema construction, property dispatch, validation
ownership, and public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,183 lines.
- StationCalendar capabilities are fetched directly at eight schema and
  validation call sites for the whole capability map, provider-counteroffer
  actions, provider-counteroffer negotiation states, and model limits.
- The selected code has one responsibility: expose schema-facing
  StationCalendar capability context to otherwise independent consumers.
- The four focused accessors replace repeated module coupling while preserving
  callback timing and per-call capability evaluation. Station-calendar,
  contact-allocation, strategy, candidate-refresh, provider-counteroffer, and
  operator-review consumers remain in their current owners.
- Exact atom-to-string conversion, capability values and ordering, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Added `OrbitalDynamics.Schema.StationCalendarCapabilityContext`, which now
owns the StationCalendar capability accessor, model-limit projection, and
provider-counteroffer action/state accessors. The Schema facade routes all
eight former direct capability dependencies through those four focused APIs.
`schema.ex` remains 6,183 lines because the explicit import and focused call
sites replace the removed helper/direct calls; the dedicated owner is 21
lines.

Verification:
- Strict focused communications/report-fixture/contact-allocation/
  provider-counteroffer/operator-review/export baseline before extraction:
  38 passed.
- The same strict focused suite after extraction: 38 passed.
- Strict full schema-export task plus adjacent candidate-refresh provenance,
  campaign-repair strategy, station-provider, strategy-lint, and validation
  evidence coverage: 14 passed.
- `mix xref callers
  OrbitalDynamics.Schema.StationCalendarCapabilityContext` reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,058 files.
- Implementation commit `786b8553` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback timing, per-call capability evaluation,
model-limit conversion, capability ordering, generated JSON Schema, validation
behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema station-calendar capability-context extraction, selected in `297af482`
and implemented in `786b8553`.
`schema.ex` remains 6,183 lines; the dedicated
StationCalendarCapabilityContext owner is 21 lines and all eight direct
StationCalendar capability dependencies moved behind it.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
