# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext maneuver-execution-uncertainty extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract maneuver-execution-uncertainty context keys, risk classification, and
context projection into
`OrbitalDynamics.RecommendationRiskContext.ManeuverExecutionUncertainty`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,650 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext already delegates fifteen focused risk families,
  while maneuver-execution-uncertainty keys, projection, and classification
  remain inline at lines 417-443, 526-527, 1,391-1,468, and 1,558-1,576.
- The selected code has one responsibility: identify maneuver execution
  uncertainty risks and project their stable review context.
- Resource margins, timeline integrity, score terms, operational feedback, and
  all other risk families remain outside the boundary.
- Exact context keys and order, accepted type/risk_type/feedback_scope forms,
  atom-key normalization, list flattening, nil omission, value ordering,
  non-list behavior, public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention resolution-summary projection extraction, selected in
`d750f18e` and implemented in `104b9d4b`.
`communications/contact_contention.ex` moved from 1,665 to 1,546 lines; the
dedicated ResolutionSummary owner is 126 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade, followed by the reduced
RecommendationRiskContext and ContactContention facades.

Blocked:
No.
