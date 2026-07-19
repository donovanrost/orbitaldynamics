# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext resource-projection context extraction.

Status:
Completed and pushed.

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
- Selection was recorded and pushed in `d5f57df7`.
- Implementation was committed and pushed in `c1465974`.
- `recommendation_risk_context.ex` moved from 2,274 to 2,142 lines.
- `OrbitalDynamics.RecommendationRiskContext.ResourceProjection` is a 168-line
  owner reached through the two public context/key facades.

Verification:
- Strict warning-clean compilation passed across 3,977 files.
- The focused resource-projection strategy file and four adjacent flow,
  candidate-replay, and policy consumers passed warning-clean: 100 tests.
- The additional recommendation-pressure-events consumer also passed, bringing
  the combined behavior total to 101 tests; its strict process exited nonzero
  only on the pre-existing signed-zero `0.0` pattern warning in that test file.
- Exact old/new public context/key parity passed for 10 cases covering empty
  and irrelevant inputs, atom/string keys, scalar/list source IDs, duplicate
  and nil aggregation, boolean/numeric/map values, availability and all margin
  families, non-list fallbacks, and advertised key ordering.
- `mix xref callers` reports only the RecommendationRiskContext facade.
- The facade-owned resource-projection key list, selector, and builder are
  absent apart from the two thin public delegates, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext resource-projection context extraction, selected in
`d5f57df7` and implemented in `c1465974`.
`recommendation_risk_context.ex` moved from 2,274 to 2,142 lines; the dedicated
resource-projection context owner is 168 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
