# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext approval-boundary extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract approval-boundary context keys, risk selection, and context projection
into `OrbitalDynamics.RecommendationRiskContext.ApprovalBoundary`. Preserve all
RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,212 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates nineteen focused risk families, while
  approval-boundary keys, risk selection, and projection remain inline at
  lines 26-40, 358, and 425-468.
- The selected code has one responsibility: identify approval-boundary risks
  by feedback scope or pressure type and project approval, authority, policy,
  review, and provenance context.
- Provider reservations, capacity packs, contention, filters, timelines, and
  all other risk families remain outside the boundary.
- Exact context key order, scope/type selection, atom-key normalization, list
  flattening, nil omission, value ordering, non-list behavior, public output,
  and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness operator-training gate extraction, selected in
`c66b1d84` and implemented in `d5794c94`.
`operational_readiness.ex` moved from 1,213 to 1,187 lines; the dedicated
OperatorTrainingGate owner is 31 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
