# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness quality-gate report extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract quality-gate report construction and its gate/row routing helpers into
`OrbitalDynamics.OperationalReadiness.QualityGateReport`. Preserve all
OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 903 lines, the
  largest ordinary eligible facade.
- Quality-gate row projection and all specialized quality summaries already
  have focused owners, while report aggregation and routing remain inline.
- The selected code has one responsibility: turn readiness gates into a
  quality-gate report with stable row IDs, derived classification, counts,
  routing sets, execution boundary, assumptions, and model limits.
- Readiness report construction, evidence construction, row projection, and
  all specialized summaries remain outside the boundary.
- Exact schema/model fields, row order, classification precedence, status and
  count derivation, gate/row ID routing, execution boundary, public output, and
  error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-dependency-impact extraction, selected in
`449fbfe3` and implemented in `5a38cbb3`.
`recommendation_risk_context.ex` moved from 963 to 878 lines; the dedicated
TimelineDependencyImpact owner is 124 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
