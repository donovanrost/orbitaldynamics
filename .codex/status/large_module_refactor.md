# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext objective-tradeoff extraction.

Status:
Completed and pushed in `2f581923`.

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
- Added `OrbitalDynamics.RecommendationRiskContext.ObjectiveTradeoff` as the
  owner of the ordered key contract, scope predicate, atom-key normalization,
  scalar/list flattening, stable deduplication, sparse context construction,
  and non-list fallback.
- Preserved all RecommendationRiskContext and root public APIs as two facade
  delegates.
- Removed the objective-tradeoff attribute, builder, and predicate from the
  facade while leaving shared helpers used by other families unchanged.
- `recommendation_risk_context.ex` moved from 2,016 to 1,893 lines; the new
  owner is 159 lines.

Verification:
- Strict focused baseline passed 13 objective-tradeoff operator-review and
  alias-refresh tests.
- Exact old/new public parity passed for six captured cases: ordered keys,
  string and atom risks, mixed/duplicate risks, empty input, and non-list
  fallback.
- Post-extraction focused verification passed the same 13 tests.
- Static checks confirm the attribute and predicate left the facade and only
  its two public delegates remain; xref reports only RecommendationRiskContext
  as a runtime caller of the owner.
- Strict warning-clean forced compile passed for 3,993 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext objective-tradeoff extraction, selected in
`3ebf90d9` and implemented in `2f581923`.
`recommendation_risk_context.ex` moved from 2,016 to 1,893 lines; the dedicated
objective-tradeoff owner is 159 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `orbit_data.ex` is now the largest ordinary eligible facade at
2,016 lines.

Blocked:
No.
