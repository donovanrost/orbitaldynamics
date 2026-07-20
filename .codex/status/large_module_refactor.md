# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-integrity extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract timeline-integrity context keys, risk classification, and context
projection into `OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,304 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates eighteen focused risk families, while
  timeline-integrity keys, projection, and classification remain inline at
  lines 355-378, 439, 1,170-1,230, and 1,236-1,242.
- The selected code has one responsibility: identify timeline-integrity risks
  and project stable dependency, exclusivity, review, and provenance context.
- Contact/resource filters, objective/score/resource-margin context, and all
  other risk families remain outside the boundary.
- Exact context keys and order, type/risk_type/feedback_scope classification,
  atom-key normalization, list flattening, nil omission, value ordering,
  non-list behavior, public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness operator-review gate extraction, selected in `6a29ce91`
and implemented in `426d1036`.
`operational_readiness.ex` moved from 1,338 to 1,295 lines; the dedicated
OperatorReviewGate owner is 51 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
