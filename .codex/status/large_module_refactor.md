# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-dependency-impact extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract timeline-dependency-impact context keys, risk selection, and context
projection into
`OrbitalDynamics.RecommendationRiskContext.TimelineDependencyImpact`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 963 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-three focused risk families,
  while timeline-dependency-impact keys, selection, and projection remain
  inline.
- The selected code has one responsibility: identify dependency-impact risks
  by feedback scope or impact key and project dependency, exclusivity,
  operator-action, derivation, and provenance context.
- Contention, filters, timeline preservation, and all other risk families
  remain outside the boundary.
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
RecommendationRiskContext provider-reservation-request extraction, selected
in `4e897f13` and implemented in `58692eff`.
`recommendation_risk_context.ex` moved from 1,033 to 963 lines; the dedicated
ProviderReservationRequest owner is 109 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
