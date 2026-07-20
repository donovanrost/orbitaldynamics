# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Strategy/planning artifact JSON-property family expansion.

Status:
Completed and pushed.

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
Selected in `bbe8cc87` and implemented in `51a9b3db`.
`JsonSchemaPropertyRouter` retains all 76 public route heads in their original
order and delegates the five selected clauses to
`StrategyPlanningPropertyRouter`. The family router now owns fifteen related
strategy/planning routes, with the copied dispatch bodies preserving the
original lazy provider/context/fallback behavior.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- AST-rendered comparison confirmed all five moved bodies are exact and all 76
  parent route heads remain exact and ordered.
- Xref reports fifteen runtime edges from the parent to the strategy/planning
  family.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,105 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The parent router shrank from 696 to 641 lines; the strategy/planning family
  grew from 154 to 229 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Strategy/planning artifact JSON-property family expansion, selected in
`bbe8cc87` and implemented in `51a9b3db`. The parent router moved from 696 to
641 lines.

Next candidate:
Re-rank the remaining inline router routes against the public `Schema`
facade's provider-helper boundaries.

Blocked:
No.
