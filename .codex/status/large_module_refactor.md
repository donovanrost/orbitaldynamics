# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar reservation-review summary extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract reservation-review row projection, expiration evaluation, count/status
aggregation, routing IDs, assumptions, and summary construction into
`OrbitalDynamics.Communications.StationCalendar.ReservationReviewSummary`.
Preserve all StationCalendar and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/station_calendar.ex` at 1,911 lines,
  the largest ordinary eligible facade.
- StationCalendar already delegates thirteen focused responsibilities, while
  reservation-review construction remains inline at lines 806-897.
- The selected block has one responsibility: project reservation-report rows
  into review rows and summarize their expiration status and review routing.
- Reservation-report construction, reservation-hold and import-readiness
  summaries, overlays, station matching, provider contention/counteroffers, and
  all public contracts remain outside the boundary.
- Exact `now_s` parsing, affected/provider row ordering, missing/declared/
  active/expired precedence, counts, routing IDs, assumptions, omission
  behavior, public facade output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness quality-gate import-readiness summary extraction,
selected in `1a2d9063` and implemented in `5b0dab62`.
`operational_readiness.ex` moved from 1,927 to 1,768 lines; the dedicated
QualityGateImportReadinessSummary owner is 227 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/station_calendar.ex` is now the largest ordinary
eligible facade at 1,911 lines, followed by LinkCapacity and ContactFilter.

Blocked:
No.
