# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation communications-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract planned/realized link-quality measurements and command authority/safety
evidence into
`OrbitalDynamics.TimelineFeedback.ReconciliationCommunicationsEvidence`.
Preserve the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,293 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one communications execution-
  evidence responsibility and depend only on planned and realized row maps.
- Identity, observation evidence, resource state, throughput, timing,
  execution uncertainty, operational-feedback exclusion, and report
  aggregation remain with their current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation provider-counteroffer context extraction, selected in
`5d597e6c` and implemented in `456360fd`.
`communications/contact_allocation.ex` moved from 4,127 to 3,984 lines; the
dedicated owner is 141 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation
communications-evidence extraction.

Blocked:
No.
