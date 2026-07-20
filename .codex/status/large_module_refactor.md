# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext link-capacity extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract link-capacity context keys, risk classification, and context projection
into `OrbitalDynamics.RecommendationRiskContext.LinkCapacity`. Preserve all
RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 878 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-four focused risk families, while
  link-capacity keys, classification, and projection remain inline.
- The selected code has one responsibility: identify scoped downlink-gap and
  actual-link-capacity risks and project demand, completion, throughput,
  shortfall, status, derivation, and provenance context.
- Contention, filters, timeline preservation, and all other risk families
  remain outside the boundary.
- Exact context key order, classifier forms, atom-key normalization,
  multi-key/list flattening, nil omission, value ordering, non-list behavior,
  public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness quality-gate report extraction, selected in `fc8572eb`
and implemented in `9a00a240`.
`operational_readiness.ex` moved from 903 to 827 lines; the dedicated
QualityGateReport owner is 118 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
