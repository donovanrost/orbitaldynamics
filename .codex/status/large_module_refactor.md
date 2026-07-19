# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback success-factor reconciliation ownership extraction.

Status:
Selected; implementation not started.

Selected boundary:
Move reconciled contact, command, observation, and maneuver factor/source
projection plus feedback sample weight/source selection into the existing
`OrbitalDynamics.TimelineFeedback.SuccessFactor` owner. Preserve the existing
report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,950 lines, ahead of
  Manifest and ContactAllocation and behind the three larger
  orchestration-heavy facades.
- The selected fields and helpers form one planned-versus-realized
  success-factor evidence responsibility.
- Success-factor normalization already lives in the selected owner; this
  extension completes its reconciliation projection without a parallel module.
- Outcome projection, maneuver comparison, timing, throughput, identity, and
  operational-feedback aggregation remain separate.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation approval-policy ownership extraction, selected in
`af08b116` and implemented in `0593a3ef`.
`communications/contact_allocation.ex` moved from 3,984 to 3,782 lines; the
dedicated owner is 218 lines.

Next candidate:
Implement and verify the selected TimelineFeedback success-factor
reconciliation ownership extraction.

Blocked:
No.
