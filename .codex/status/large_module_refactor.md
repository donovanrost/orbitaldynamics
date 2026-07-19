# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext objective-tradeoff extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract the objective-tradeoff key contract, scope filtering, atom-key
normalization, scalar/list flattening, stable deduplication, and sparse context
construction into
`OrbitalDynamics.RecommendationRiskContext.ObjectiveTradeoff`. Preserve all
RecommendationRiskContext and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking ties `recommendation_risk_context.ex` and `orbit_data.ex` at
  2,016 lines; RecommendationRiskContext has the clearer bounded boundary.
- RecommendationRiskContext already delegates to twelve context-family owners;
  the objective-tradeoff key contract remains at lines 454-488 and its builder
  at lines 1,605-1,685.
- The selected boundary mirrors existing ObjectiveSatisfaction,
  ContactAllocation, and ResourceProjection owners.
- Score terms, objective satisfaction, resource margins, maneuver execution,
  timeline, contact, station, approval, validation, and all other risk-context
  families remain outside the boundary.
- Exact key ordering, objective-tradeoff scope filtering, atom/string input
  parity, scalar/list flattening, first-seen ordering, deduplication, sparse
  omission, score-term map preservation, and non-list fallback must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness operational-mode decision extraction, selected in
`0582a8c2` and implemented in `5a80b5c7`.
`operational_readiness.ex` moved from 2,018 to 1,927 lines; the dedicated
operational-mode decision owner is 103 lines.

Next candidate:
Complete the selected RecommendationRiskContext objective-tradeoff extraction.

Blocked:
No.
