# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Objective/optimizer JSON-property family extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the five contiguous objective satisfaction/tradeoff, ranking/Pareto,
score-term, resource-filter-summary, and constraint clauses from
`JsonSchemaPropertyRouter` into the existing `StrategyPlanningPropertyRouter`.
Keep the parent router's exact guarded and literal clause heads/order as
delegations.

Selection evidence:
- The parent router remains 864 lines across 76 contract-family clauses.
- Five adjacent clauses form a roughly 80-line objective/optimizer boundary
  covering eight related contracts.
- They fit the existing strategy/planning-analysis owner and require only its
  current lazy provider/context/fallback support.
- No recursive parent callback or cross-family property lookup is required.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Filter/resource/contention JSON-property family extraction, selected in
`dc58ba33` and implemented in `054c5eb0`. The parent router moved from 914 to
864 lines.

Next candidate:
Implement and verify the selected objective/optimizer move, then re-rank the
operational readiness/quality-gate cohort.

Blocked:
No.
