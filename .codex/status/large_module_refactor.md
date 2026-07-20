# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Strategy/planning-analysis JSON-property family extraction.

Status:
Implemented and verified.

Selected boundary:
Extract the five contiguous strategy-branch, optimizer-contract, model
capability, Monte Carlo reproducibility, and strategy-recommendation clauses
from `JsonSchemaPropertyRouter` into a strategy/planning-analysis family owner.
Keep the parent router's exact guarded and literal clause heads/order as
delegations.

Selection evidence:
- The parent router remains 1,071 lines across 76 contract-family clauses.
- Five adjacent clauses form a roughly 75-line strategy/planning-analysis
  boundary covering seven related contracts.
- The bodies already delegate through focused strategy, planning-analysis, and
  model-capability dispatchers with shared lazy providers/context/fallback.
- No recursive parent callback or cross-family property lookup is required.

Implementation:
- Added an 82-line `StrategyPlanningPropertyRouter` with the five mechanically
  moved strategy/planning-analysis clause bodies spanning seven contracts.
- Kept all literal and guarded parent clause heads in place as ordered
  delegations.
- Reused shared lazy provider/context/fallback support without a parent
  callback.
- The parent router moved from 1,071 to 1,021 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all five moved bodies are exact and all 76 parent
  clause heads remain in their original order.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the five intended family edges.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,102 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Strategy/planning-analysis JSON-property family extraction, selected in
`15add911` and implemented in `fd11d950`. The parent router moved from 1,071 to
1,021 lines.

Next candidate:
Re-rank maneuver/timeline and ground-network communications cohorts, favoring
another broad exact-body family move.

Blocked:
No.
