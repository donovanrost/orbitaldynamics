# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext contact-contention extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract contact-contention context keys, risk classification, and context
projection into `OrbitalDynamics.RecommendationRiskContext.ContactContention`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 782 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-five focused risk families, while
  contact-contention keys, classification, and projection remain inline.
- The selected code has one responsibility: identify contact-contention scope
  and project contact, scenario, station, demand, timing, contention,
  operator-action, derivation, and provenance context.
- Resolution selection, filters, timeline preservation, and all other risk
  families remain outside the boundary.
- Exact context key order, scope classification, atom-key normalization,
  multi-key/list flattening, nil omission, value ordering, non-list behavior,
  public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness readiness-report assembly extraction, selected in
`d172fe6f` and implemented in `75a5cad0`.
`operational_readiness.ex` moved from 827 to 765 lines; the dedicated
ReadinessReport owner is 89 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
