# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar reservation summary-value extraction.

Status:
Completed and pushed.

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
- Selection was recorded and pushed in `162c6a73`.
- Implementation was committed and pushed in `def426ce`.
- `communications/station_calendar.ex` moved from 2,425 to 2,268 lines.
- `OrbitalDynamics.Communications.StationCalendar.ReservationSummaryValues`
  is a 210-line owner reached through private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,969 files.
- The focused StationCalendar file and six adjacent campaign-strategy and
  CandidateRefresh replay consumers passed together: 52 tests.
- Exact old/new public parity passed for 6 complete
  reservation-to-review-to-hold-to-import-readiness chains covering empty
  evidence, expired/active/missing expirations, provider contention,
  held/on-hold tokens, atom and numeric IDs, and deadline evaluation.
- `mix xref callers` reports only the StationCalendar facade.
- The removed value/routing helpers and two now-unused normalization wrappers
  are absent apart from thin delegates, formatting and `git diff --check`
  passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar reservation summary-value extraction, selected in `162c6a73`
and implemented in `def426ce`.
`communications/station_calendar.ex` moved from 2,425 to 2,268 lines; the
dedicated reservation-summary values owner is 210 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
