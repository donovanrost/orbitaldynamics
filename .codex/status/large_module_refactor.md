# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar capability-context extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema contact-contention capability-context extraction, selected in
`81ef520e` and implemented in `b0025203`.
`schema.ex` moved from 6,189 to 6,183 lines; the dedicated
ContactContentionCapabilityContext owner is 15 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
