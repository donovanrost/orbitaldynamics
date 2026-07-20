# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext contact-filter extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract contact-filter context keys, risk filtering, and projection into
`OrbitalDynamics.RecommendationRiskContext.ContactFilter`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 473 lines, the
  largest remaining facade in this refactor lane.
- Most risk families delegate keys and projection to focused owners, while
  contact-filter projection remains inline.
- The selected code has one responsibility: identify `contact_filter`
  feedback risks and project their stable contact, reservation, calendar,
  downlink, and provenance context.
- Shared normalization/value collection, other risk-family projections, and
  all public routing remain outside the boundary except for facade delegates.
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
OperationalReadiness capability-metadata extraction, selected in `67e54137`
and implemented in `17398d5d`.
`operational_readiness.ex` moved from 484 to 345 lines; the dedicated
Capability owner is 155 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext retains
the parallel resource-filter boundary.

Blocked:
No.
