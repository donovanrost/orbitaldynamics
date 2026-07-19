# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation-identity extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract planned/realized identity selection and comparison for direction,
ground station, spacecraft, target, resource, collection, product, payload,
instrument, pointing, attitude, link configuration, and source window into
`OrbitalDynamics.TimelineFeedback.ReconciliationIdentity`. Move reconciliation
identity-mismatch annotation with the fields it classifies; preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,508 lines. Its
  2,494-3,057 reconciliation-row assembler is the largest remaining single
  responsibility hotspot in the facade.
- Identity selection, pairwise match status, and mismatch-summary annotation
  are a cohesive subset of that assembler and depend only on planned and
  realized row maps.
- Reconciliation matching, timing, throughput, execution uncertainty,
  operational-feedback exclusion, and report aggregation remain in the
  facade.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
RecommendationRiskContext operational-feedback extraction, selected in
`dc4a34a0` and implemented in `8ee8763d`.
`recommendation_risk_context.ex` moved from 4,033 to 3,754 lines; the dedicated
owner is 158 lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation-identity
extraction.

Blocked:
No.
