# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar reservation-hold import-readiness extraction.

Status:
Completed and pushed in `d0e43c2e`.

Selected boundary:
Extract reservation-hold import-status projection, count/status aggregation,
reservation/contact routing by import state, expiration, owner, action,
direction, and ground station, assumptions, and summary construction into
`OrbitalDynamics.Communications.StationCalendar.ReservationHoldImportReadinessSummary`.
Preserve all StationCalendar and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/station_calendar.ex` at 1,814 lines,
  the
  largest ordinary eligible facade.
- StationCalendar already delegates fourteen focused responsibilities, while
  reservation-hold import-readiness construction remains inline at lines
  868-938 with its direction/station routing helpers in the facade.
- The selected block has one responsibility: project reservation-hold review
  rows into a review-only import-readiness handoff.
- Reservation reports, review and hold summaries, overlays, station matching,
  provider contention/counteroffers, and all public contracts remain outside
  the boundary.
- Exact row order/status projection, counts, reservation/contact routing,
  direction normalization, assumptions, omission behavior, public output, and
  error behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.Communications.StationCalendar.ReservationHoldImportReadinessSummary`
  as the owner of import-status row projection, count/status aggregation,
  reservation/contact routing, direction/station routing, assumptions, and
  summary output.
- Preserved StationCalendar and root public APIs as delegates and kept the
  facade's capability-derived model limits authoritative.
- Removed import-readiness-specific routing helpers from the facade while
  retaining the contact/expiration helpers still shared by the hold summary.
- `station_calendar.ex` moved from 1,814 to 1,670 lines; the new owner is 221
  lines.

Verification:
- Strict focused baseline passed all 42 StationCalendar tests.
- Exact old/new public parity passed for four deterministic summaries: dense
  hold routing by status/owner/action/direction/station, atom-key input, empty
  input, and end-to-end reservation-report input.
- Post-extraction focused and adjacent station-provider schema verification
  passed all 48 tests.
- Static checks confirm import-readiness projection/routing helpers left the
  facade; xref reports only StationCalendar as a runtime caller.
- Strict warning-clean forced compile passed for 4,006 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar reservation-hold import-readiness extraction, selected in
`4148524b` and implemented in `d0e43c2e`.
`station_calendar.ex` moved from 1,814 to 1,670 lines; the dedicated
ReservationHoldImportReadinessSummary owner is 221 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_allocation.ex` is now the largest ordinary
eligible facade at 1,804 lines, followed by TimelineFeedback and
ResourceProjection.

Blocked:
No.
