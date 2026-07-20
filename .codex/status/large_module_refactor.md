# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation validation routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Complete the existing
`OrbitalDynamics.Schema.StationReservationValidation` extraction by moving the
default-path arity into the owner, routing contract clauses and callback tables
directly to it, and removing five facade pass-through clauses.
Preserve all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,602 lines.
- Station calendar/reservation validation already has a focused owner, but the
  facade retains a default-path adapter plus four one-hop wrappers referenced
  by contract clauses and campaign/candidate callback tables.
- The selected code has one responsibility: route optional station-calendar
  reports and reservation review/hold/import-readiness summaries to the owner.
- Callback-table composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, malformed-input behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema resource-filter validation routing cleanup, selected in `6965e3b1` and
implemented in `db4ce31c`.
`schema.ex` moved from 6,612 to 6,602 lines by completing resource-filter
routing to the existing ResourceValidation owner.

Next candidate:
After this slice, re-rank the remaining schema wrapper clusters while
preserving dependency-injecting adapters.

Blocked:
No.
