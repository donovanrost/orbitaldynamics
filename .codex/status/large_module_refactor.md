# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation realized-ingress-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract realized identity reference, source/provider/adapter provenance,
trust/ingest metadata, invalid feedback, unsupported status, and Cadence import
diagnostics into
`OrbitalDynamics.TimelineFeedback.ReconciliationRealizedIngressEvidence`.
Preserve the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,862 lines, ahead of
  Manifest and ContactAllocation and behind the three larger
  orchestration-heavy facades.
- The selected 20 output fields form one normalized realized-ingress evidence
  projection and depend only on the realized row.
- Identity matching, lifecycle transition, protection decisions, source
  activity contexts, and report aggregation remain in the facade or their
  current owners.
- Existing output names and omission behavior remain unchanged.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation plan-evidence extraction, selected in
`54aad1a5` and implemented in `fddf4f52`.
`timeline_feedback.ex` moved from 3,894 to 3,862 lines; the dedicated owner is
45 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation
realized-ingress-evidence extraction.

Blocked:
No.
