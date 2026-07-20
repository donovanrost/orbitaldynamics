# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext resource-filter extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract resource-filter context keys, risk filtering, and projection into
`OrbitalDynamics.RecommendationRiskContext.ResourceFilter`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 374 lines, the
  largest remaining facade in this refactor lane.
- Most risk families delegate keys and projection to focused owners, while
  resource-filter projection remains inline.
- The selected code has one responsibility: identify `resource_filter`
  feedback risks and project their stable availability, margin, training, and
  provenance context.
- Other risk-family projections and all public routing remain outside the
  boundary except for facade delegates.
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
RecommendationRiskContext contact-filter extraction, selected in `ea5c6e5e`
and implemented in `8c7b036d`.
`recommendation_risk_context.ex` moved from 473 to 374 lines; the dedicated
ContactFilter owner is 130 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest remaining facade at 345 lines.

Blocked:
No.
