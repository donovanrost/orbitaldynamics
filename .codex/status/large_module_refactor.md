# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation resource-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract reconciled resource margins, battery telemetry, spacecraft/payload/
antenna availability, degradation and mode state, and incompatible/suppressed
activity types into
`OrbitalDynamics.TimelineFeedback.ReconciliationResourceEvidence`. Preserve
the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,220 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one planned-versus-realized
  spacecraft resource-state evidence responsibility and depend only on the
  planned and realized row maps.
- Identity, observation and communications evidence, throughput, timing,
  success outcomes, station-calendar evidence, execution uncertainty,
  operational-feedback exclusion, and report aggregation remain with their
  current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation communications-evidence extraction, selected
in `a40726a4` and implemented in `43bf6f27`.
`timeline_feedback.ex` moved from 4,293 to 4,220 lines; the dedicated owner is
107 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation
resource-evidence extraction.

Blocked:
No.
