# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation lifecycle-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract row lifecycle status, planned/realized type and status, public status
transition, protection decision, source activities, and activity contexts into
`OrbitalDynamics.TimelineFeedback.ReconciliationLifecycleEvidence`. Preserve
the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,842 lines, six lines ahead
  of Manifest and ahead of ContactAllocation, behind the three larger
  orchestration-heavy facades.
- The selected fields and five helper families form one planned-versus-realized
  lifecycle/protection evidence responsibility.
- Status transition and protection continue to delegate to the public Timeline
  owner; configuration and algorithms are not duplicated.
- Matching metadata, ingress, plan, resource, timing, outcome, and aggregation
  responsibilities remain separate.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation realized-ingress-evidence extraction, selected
in `498bd1ba` and implemented in `4a574e1d`.
`timeline_feedback.ex` moved from 3,862 to 3,842 lines; the dedicated owner is
33 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation
lifecycle-evidence extraction.

Blocked:
No.
