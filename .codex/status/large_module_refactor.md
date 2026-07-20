# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness import-eligibility summary extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract compact import-eligibility artifact projection into
`OrbitalDynamics.OperationalReadiness.ImportEligibilitySummary`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,635 lines, the
  largest ordinary eligible facade.
- OperationalReadiness already delegates eleven focused responsibilities,
  while import-eligibility artifact projection remains inline at lines 428-463.
- The selected block has one responsibility: project readiness identity,
  classification, row-derived gate counts, non-passed gates, and explicit
  execution-boundary assumptions into a compact summary.
- Readiness evidence collection, gate decisions, quality-gate reporting,
  execution-boundary summaries, and all public contracts remain outside the
  boundary.
- Exact schema/model fields, gate count derivation, non-passed gate filtering
  and order, import eligibility classification, assumptions, model limits,
  public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext maneuver-execution-uncertainty extraction, selected
in `e8a5043c` and implemented in `1f5f9672`.
`recommendation_risk_context.ex` moved from 1,650 to 1,527 lines; the dedicated
ManeuverExecutionUncertainty owner is 144 lines.

Next candidate:
After this slice, re-rank the live checkout. ContactContention and
ResourceFilter are the next largest ordinary eligible facades, followed by the
reduced OperationalReadiness and RecommendationRiskContext facades.

Blocked:
No.
