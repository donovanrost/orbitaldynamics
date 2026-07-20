# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext contact-contention-resolution extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract contact-contention-resolution context keys, risk filtering, and
projection into
`OrbitalDynamics.RecommendationRiskContext.ContactContentionResolution`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 683 lines, the
  largest remaining facade in this refactor lane.
- Most risk families already delegate keys and projection to focused owners,
  while contact-contention-resolution projection remains inline.
- The selected code has one responsibility: identify
  `contact_contention_resolution` feedback risks and project their stable
  multi-field context.
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
OperationalReadiness evidence-construction extraction, selected in
`d622a7ab` and implemented in `5dd3ae78`.
`operational_readiness.ex` moved from 765 to 484 lines; the dedicated
ReadinessEvidence owner is 286 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext retains
cohesive timeline-preservation, contact-filter, and resource-filter boundaries.

Blocked:
No.
