# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext execution-success feedback extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract command/maneuver execution-success risk selection, context projection,
advertised output keys, key normalization, scalar/list flattening, nil
omission, and first-seen deduplication into
`OrbitalDynamics.RecommendationRiskContext.ExecutionSuccessFeedback`. Preserve
the public RecommendationRiskContext facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 2,417
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected context spans lines 2,178-2,271, its predicate spans
  2,379-2,387, and its advertised key list spans lines 644-682.
- Recommendation/strategy consumers reach the family only through the two
  public facade functions.
- All other approval, provider, contention, timeline, resource, objective,
  validation, and operational-feedback risk families remain outside this
  boundary.
- Existing type/risk-type matching, atom-key normalization, input ordering,
  scalar versus list wrapping, nil omission, first-seen deduplication, empty
  map behavior, exact output keys, and value shapes must remain unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection activity evidence validation extraction, selected in
`d39bd372` and implemented in `66c5aca8`.
`resource_projection.ex` moved from 2,418 to 2,197 lines; the dedicated
activity-input validation owner is 253 lines.

Next candidate:
Complete and verify the selected execution-success feedback context
extraction.

Blocked:
No.
