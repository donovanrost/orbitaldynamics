# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar station matching extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract contact normalization, contact-row/direction classification,
ground-station/time/direction matching, provider-counteroffer inclusion,
availability precedence, top-entry selection, ambiguous-entry synthesis,
unambiguous capacity/direction preservation, window overlap semantics, and the
advertised command-contact direction aliases into
`OrbitalDynamics.Communications.StationCalendar.StationMatching`. Preserve all
public StationCalendar overlay, report, summary, and capability facades.

Selection evidence:
- Live re-ranking places `communications/station_calendar.ex` at 2,268 lines,
  the largest eligible facade behind Schema, Timeline, MissionPlan.Activity,
  and the root public facade.
- The selected matching family spans lines 1,338-1,507 and exclusively decides
  which normalized calendar entries affect a normalized contact and which
  highest-precedence entry represents the overlap.
- Overlay construction already converges through five private helpers for
  normalization, matching, selected entry, contact counting, and precedence.
- Annotation, reservations, provider contention, approval policy, affected-row
  construction, reports/summaries, public clauses, and artifact contracts
  remain outside this boundary.
- Existing shallow recursive key stringification, station-ID aliasing,
  contact-type fallback directions, command/uplink compatibility, strict-open
  interval overlap, available-entry exclusion except counteroffers, precedence
  ranks, deterministic ambiguous IDs, capacity/direction ambiguity behavior,
  exact errors, and capability metadata must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext resource-projection context extraction, selected in
`d5f57df7` and implemented in `c1465974`.
`recommendation_risk_context.ex` moved from 2,274 to 2,142 lines; the dedicated
resource-projection context owner is 168 lines.

Next candidate:
Implement and verify the selected StationCalendar station-matching boundary.

Blocked:
No.
