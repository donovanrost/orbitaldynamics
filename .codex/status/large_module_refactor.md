# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation returned-allocation extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract contention recommendation lookup maps, allocation-row ordering,
effective allocation status, allocated-row selection, returned contact lookup,
and returned allocation context projection into
`OrbitalDynamics.Communications.ContactAllocation.ReturnedAllocation`.
Preserve all ContactAllocation and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_allocation.ex` at 1,804 lines,
  the
  largest ordinary eligible facade.
- ContactAllocation already delegates nine focused responsibilities, while
  resolution lookup and returned-allocation projection remain inline at lines
  1,433-1,530.
- The selected block has one responsibility: turn finalized allocation rows
  back into the public returned-contact view.
- Allocation report construction, blocked/base row projection, capacity
  packing, validation, approvals, summaries, and all public contracts remain
  outside the boundary.
- Exact recommendation lookup overwrite behavior, row ordering, effective
  status precedence, original-contact lookup, projected fields,
  provider-counteroffer context, omission behavior, and error behavior must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

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
