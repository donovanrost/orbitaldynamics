# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-preservation extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract timeline-preservation context keys, risk filtering, and projection into
`OrbitalDynamics.RecommendationRiskContext.TimelinePreservation`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 573 lines, the
  largest remaining facade in this refactor lane.
- Most risk families now delegate keys and projection to focused owners, while
  timeline-preservation projection remains inline.
- The selected code has one responsibility: identify timeline-preservation
  review/type or feedback-scope risks and project their stable multi-field
  context.
- Shared normalization/value collection, other risk-family projections, and
  all public routing remain outside the boundary except for the facade
  delegates.
- Exact key ordering, string/atom-key normalization, nested/list flattening,
  nil rejection, stable first-seen uniqueness, omission of empty keys, and
  non-list fallback behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext contact-contention-resolution extraction, selected
in `be111047` and implemented in `9015373d`.
`recommendation_risk_context.ex` moved from 683 to 573 lines; the dedicated
ContactContentionResolution owner is 130 lines.

Next candidate:
Re-rank the live checkout. RecommendationRiskContext retains cohesive
timeline-preservation, contact-filter, and resource-filter boundaries.

Blocked:
No.
