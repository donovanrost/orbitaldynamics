# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext score-term extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract score-term context keys, risk classification, and context projection
into `OrbitalDynamics.RecommendationRiskContext.ScoreTerm`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,527 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates sixteen focused risk families, while the
  score-term key registry, context projection, and classifier remain inline at
  lines 353-391, 491, 1,222-1,301, and 1,495-1,497.
- The selected code has one responsibility: identify score-term risks and
  project stable objective, target, activity, scoring, and provenance context.
- Resource margins, timeline integrity, contact/resource filters, objective
  context, and all other risk families remain outside the boundary.
- Exact context keys and order, feedback-scope classification, atom-key
  normalization, list flattening, nil omission, value ordering, non-list
  behavior, public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness source/report identity extraction, selected in `bbd440b7`
and implemented in `1a5b8947`.
`operational_readiness.ex` moved from 1,541 to 1,474 lines; the dedicated
SourceIdentity owner is 80 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
