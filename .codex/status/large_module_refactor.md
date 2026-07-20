# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar reservation-hold import-readiness extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OrbitData accepted-planning-state construction extraction, selected in
`036ac21a` and implemented in `fe2b4773`.
`orbit_data.ex` moved from 1,856 to 1,596 lines; the dedicated
AcceptedPlanningState owner is 303 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/station_calendar.ex` is now the largest ordinary
eligible facade at 1,814 lines, followed by ContactAllocation and
TimelineFeedback.

Blocked:
No.
