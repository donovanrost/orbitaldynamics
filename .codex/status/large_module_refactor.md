# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback realized feedback validation extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract realized feedback unit-interval and nonnegative-weight path policy,
invalid-section construction, invalid value and orphaned source sanitization,
nested path lookup/deletion, valid/invalid factor and weight detection,
invalid-row annotation, and failure-reason classification into
`OrbitalDynamics.TimelineFeedback.RealizedFeedbackValidation`. Preserve all
public TimelineFeedback reconciliation, normalization, state, operational
feedback, and capability facades.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 2,267 lines, the largest
  eligible facade behind Schema, Timeline, MissionPlan.Activity, and the root
  public facade.
- The selected validation/sanitization family spans lines 1,095-1,374 and is
  reached through four private helpers during realized-input normalization and
  row construction.
- The family exclusively owns feedback-factor/quality/cloud/blur unit-interval
  policy, feedback-weight nonnegative policy, nested feedback paths, and
  invalid-section annotations.
- Reconciliation identity/matching, planned/realized row construction,
  operational feedback aggregation, throughput/resource/station/thermal/link
  contexts, publication, and artifact contracts remain outside this boundary.
- Existing path order, duplicate field reporting, number/string parsing,
  invalid number versus shape evidence, nested empty-map cleanup, fallback
  source preservation/removal, combined failure reason selection, exact keys,
  and deterministic section order must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar station matching extraction, selected in `bd2cead6` and
implemented in `7e6add9c`.
`communications/station_calendar.ex` moved from 2,268 to 2,068 lines; the
dedicated station-matching owner is 237 lines.

Next candidate:
Implement and verify the selected TimelineFeedback realized-feedback
validation boundary.

Blocked:
No.
