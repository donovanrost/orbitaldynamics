# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Strategy/planning artifact JSON-property family expansion.

Status:
Selected; implementation pending.

Selected boundary:
Move the five contiguous maneuver-review, branch-comparison,
campaign-strategy, planned-activity, and plan-delta clauses from
`JsonSchemaPropertyRouter` into the existing
`StrategyPlanningPropertyRouter`. Keep the parent router's exact literal
clause heads/order as delegations.

Selection evidence:
- The parent router remains 696 lines across 76 contract-family clauses.
- Five adjacent clauses form a roughly 75-line planning-artifact boundary
  spanning maneuver review, strategy comparison/selection, planned activity,
  and plan delta.
- They fit the existing strategy/planning owner and reuse its current
  provider/context/fallback support without new dependencies.
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
Timeline lifecycle/report JSON-property family expansion, selected in
`a9fa65d3` and implemented in `38ab9bad`. The parent router moved from 772 to
696 lines.

Next candidate:
Implement and verify the selected strategy/planning family expansion, then
re-rank the remaining inline router routes against the public `Schema`
facade's provider-helper boundaries.

Blocked:
No.
