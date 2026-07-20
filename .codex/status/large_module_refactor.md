# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext provider-reservation-request extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract provider-reservation-request context keys, risk selection, and context
projection into
`OrbitalDynamics.RecommendationRiskContext.ProviderReservationRequest`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,033 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-two focused risk families, while
  provider-reservation-request keys, selection, and projection remain inline.
- The selected code has one responsibility: identify provider reservation
  requests by feedback scope or request key and project contact, station,
  reservation, review, assumption, and provenance context.
- Contention, filters, timelines, and all other risk families remain outside
  the boundary.
- Exact context key order, scope/key selection, atom-key normalization,
  multi-key/list flattening, nil omission, value ordering, non-list behavior,
  public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness unavailable-resource summary extraction, selected in
`98f6fe39` and implemented in `6686d3a4`.
`operational_readiness.ex` moved from 1,063 to 903 lines; the dedicated
QualityGateUnavailableResourceSummary owner is 213 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
