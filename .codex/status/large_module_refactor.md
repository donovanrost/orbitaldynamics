# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation observation-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract planned/realized pointing, attitude, lighting, image-quality, and
thermal evidence reconciliation into
`OrbitalDynamics.TimelineFeedback.ReconciliationObservationEvidence`. Preserve
the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,376 lines, immediately
  behind MissionPlan.Activity and ahead of Study.Manifest.
- The selected reconciliation-row fields form a contiguous observation-
  evidence responsibility and depend only on planned and realized row maps.
- Identity matching, command authority, link quality, resource state,
  throughput, execution uncertainty, operational-feedback exclusion, and
  report aggregation remain in the facade.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation-identity extraction, selected in `cf67ec01`
and implemented in `eebe8828`. `timeline_feedback.ex` moved from 4,508 to
4,376 lines; the dedicated owner is 92 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation observation-
evidence extraction.

Blocked:
No.
