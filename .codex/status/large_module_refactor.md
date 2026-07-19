# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation station-calendar-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract reconciled station availability and capacity, calendar provenance,
overlap and ambiguity evidence, and reservation state into
`OrbitalDynamics.TimelineFeedback.ReconciliationStationCalendarEvidence`.
Preserve the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,180 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one planned-versus-realized
  station-calendar execution-evidence responsibility and depend only on the
  planned and realized row maps.
- Station-calendar input normalization remains in the facade. Identity,
  observation, communications and resource evidence, throughput, timing,
  success outcomes, execution uncertainty, operational-feedback exclusion,
  and report aggregation remain with their current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation resource-evidence extraction, selected in
`d44a89d6` and implemented in `8875bd76`.
`timeline_feedback.ex` moved from 4,220 to 4,180 lines; the dedicated owner is
69 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation
station-calendar-evidence extraction.

Blocked:
No.
