# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext resource-projection context extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract resource-projection risk selection, atom-key normalization,
single/multi-field context value aggregation, empty-value omission, the full
resource/availability/margin/downlink/feedback projection, and its advertised
context-key list into
`OrbitalDynamics.RecommendationRiskContext.ResourceProjection`. Preserve the
public RecommendationRiskContext context and context-key facades.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 2,274 lines, the
  largest eligible facade behind Schema, Timeline, MissionPlan.Activity, and
  the root public facade.
- The advertised resource-projection key list at lines 450-489 and public
  context builder at lines 1,679-1,768 form one dedicated projection family.
- Only risks with `feedback_scope == "resource_projection"` participate; the
  builder reads no other recommendation-risk context state.
- Resource filtering, margins, score terms, objectives, contact/station,
  timeline, execution, validation, and operational-feedback contexts remain
  outside this boundary.
- Existing shallow atom-key conversion, input-order preservation, multi-key
  flattening, nil rejection, stable first-occurrence deduplication, boolean/
  numeric/map preservation, empty-key omission, non-list fallback, exact field
  names, and advertised key ordering must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness quality-gate schema-validation summary extraction,
selected in `7eed3ebf` and implemented in `e0ba1c1e`.
`operational_readiness.ex` moved from 2,276 to 2,186 lines; the dedicated
schema-validation summary owner is 171 lines.

Next candidate:
Implement and verify the selected RecommendationRiskContext
resource-projection context boundary.

Blocked:
No.
