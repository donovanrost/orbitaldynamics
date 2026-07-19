# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar reservation summary-value extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract reservation ID/status/owner projection, status and match-status
routing, hold detection, expiration aggregation, row ID projection, and
generic row-value grouping into
`OrbitalDynamics.Communications.StationCalendar.ReservationSummaryValues`.
Preserve all public StationCalendar report, reservation, review, hold, and
import-readiness summary facades.

Selection evidence:
- Live re-ranking places `communications/station_calendar.ex` at 2,425
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 1,195-1,380 and exclusively owns
  normalized reservation values and non-directional routing maps.
- Reservation, review, hold, and hold-import-readiness summaries are the only
  consumers of these projections.
- Direction/station routing, source-row normalization, provider contention,
  overlay matching, approval policy, report construction, public clauses, and
  artifact contracts remain outside this boundary.
- Existing scalar/list flattening, status normalization, one-to-many and
  positional ID/status pairing, nil omission, stable deduplication/sorting,
  hold-token matching, numeric-string expiration normalization, frequency
  counts, empty behavior, and row-value grouping must remain unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity downlink-requirement projection extraction, selected in
`defe0c62` and implemented in `f7c379d7`.
`communications/link_capacity.ex` moved from 2,462 to 2,246 lines; the
dedicated downlink-requirement owner is 270 lines.

Next candidate:
Complete and verify the selected StationCalendar reservation summary-value
extraction.

Blocked:
No.
