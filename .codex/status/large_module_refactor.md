# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar reservation-review summary extraction.

Status:
Completed and pushed in `0635b27d`.

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
- Added `OrbitalDynamics.Communications.StationCalendar.ReservationReviewSummary`
  as the owner of reservation-review row projection, expiration evaluation,
  status/count aggregation, routing IDs, assumptions, and summary output.
- Preserved StationCalendar and root public APIs as delegates and kept the
  facade's capability-derived model limits authoritative.
- Removed the review-specific row and expiration helpers from the facade while
  leaving shared reservation-hold summary values in their existing owner.
- `station_calendar.ex` moved from 1,911 to 1,814 lines; the new owner is 129
  lines.

Verification:
- Strict focused baseline passed all 42 StationCalendar tests.
- Exact old/new public parity passed for four deterministic summaries:
  evaluated active/expired/missing rows, unevaluated declared/missing rows,
  atom-keyed/string-numeric input, and an empty report.
- Post-extraction focused and adjacent schema/replay verification passed all 50
  tests.
- Static checks confirm the review row/expiration helpers left the facade; xref
  reports only StationCalendar as a runtime caller.
- Strict warning-clean forced compile passed for 4,001 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar reservation-review summary extraction, selected in `0da707f7`
and implemented in `0635b27d`.
`station_calendar.ex` moved from 1,911 to 1,814 lines; the dedicated
ReservationReviewSummary owner is 129 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/link_capacity.ex` is now the largest ordinary
eligible facade at 1,904 lines, followed by ContactFilter and
RecommendationRiskContext.

Blocked:
No.
