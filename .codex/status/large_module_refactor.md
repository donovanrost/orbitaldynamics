# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Strategy/planning-analysis JSON-property family extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Validation/schema-lifecycle JSON-property family extraction, selected in
`28e22361` and implemented in `5e2b8c72`. The parent router moved from 1,146 to
1,071 lines.

Next candidate:
Implement and verify the selected strategy/planning-analysis split, then
re-rank maneuver/timeline or communications cohorts.

Blocked:
No.
