# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Objective/optimizer JSON-property family extraction.

Status:
Implemented and verified.

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
- Moved five objective/optimizer clause bodies into the existing
  `StrategyPlanningPropertyRouter`, which now owns ten related routes in 154
  lines.
- Kept all guarded and literal parent clause heads in place as ordered
  delegations.
- Reused the planning owner's existing lazy provider/context/fallback support.
- The parent router moved from 864 to 814 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all five moved bodies are exact and all 76 parent
  clause heads remain in their original order.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the five additional planning-family edges.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,104 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Objective/optimizer JSON-property family move, selected in `4b8ee80c` and
implemented in `d75f423d`. The parent router moved from 864 to 814 lines.

Next candidate:
Re-rank the operational readiness/quality-gate cohort for another broad
exact-body family move.

Blocked:
No.
