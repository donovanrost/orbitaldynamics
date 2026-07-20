# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext resource-margin extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract resource-margin context keys, risk classification, and context
projection into `OrbitalDynamics.RecommendationRiskContext.ResourceMargin`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,405 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates seventeen focused risk families, while
  the resource-margin key registry, projection, and classifier remain inline at
  lines 354-377, 458, 1,189-1,244, and 1,315-1,335.
- The selected code has one responsibility: identify resource-margin risks and
  project stable spacecraft, margin, threshold, activity, review, and
  provenance context.
- Timeline integrity, contact/resource filters, objective/score-term context,
  and all other risk families remain outside the boundary.
- Exact context keys and order, resource-field/type classification, atom-key
  normalization, list flattening, nil omission, value ordering, non-list
  behavior, public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness Cadence-import gate extraction, selected in `316e9897` and
implemented in `ab2b108f`.
`operational_readiness.ex` moved from 1,474 to 1,388 lines; the dedicated
CadenceImportGate owner is 101 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
