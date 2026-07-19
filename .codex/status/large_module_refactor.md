# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness quality-gate operator-training summary extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract operator-training quality-gate row selection, requirement aggregation,
role/training/certification/qualification routing, status/classification ID
maps, review-state derivation, and summary assembly into
`OrbitalDynamics.OperationalReadiness.QualityGateOperatorTrainingSummary`.
Preserve the public OperationalReadiness facade and all input-shape/idempotent
clauses.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 2,839 lines, fifth
  behind Schema, Timeline, MissionPlan.Activity, and the intentionally public
  `OrbitalDynamics` facade, and ahead of TimelineFeedback, ContactContention,
  LinkCapacity, StationCalendar, RecommendationRiskContext, and
  ResourceProjection.
- The selected builder spans lines 779-845, with exclusive row/requirement
  selectors at lines 1,120-1,129. It owns operator-training row selection,
  positive requirement count aggregation, required role/training/certification/
  qualification routing, gate row and gate identity maps, review-state
  derivation, assumptions, and model limits.
- Small generic summary operations needed by the owner—row extraction,
  positive map totals, scalar/list normalization, stable IDs, grouped IDs, and
  nil compaction—remain exact local support rather than expanding the boundary
  into unrelated quality-gate summaries.
- Readiness report construction, generic and other specialized quality-gate
  summaries, gate evidence collection, Cadence/review-package routing,
  publication context, policy/resource/schema/import gates, and public
  contracts remain outside this boundary.
- Existing stringification, row filtering, positive-count semantics, stable
  sorting, grouped identity maps, omission of nil summary values, idempotent
  input handling, and exact errors must remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext station-reservation-hold import-readiness
extraction, selected in `4501d5fe` and implemented in `04980e12`.
`recommendation_risk_context.ex` moved from 2,909 to 2,748 lines; the dedicated
context owner is 202 lines.

Next candidate:
Implement and verify the selected OperationalReadiness quality-gate
operator-training summary extraction.

Blocked:
No.
