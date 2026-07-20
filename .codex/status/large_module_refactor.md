# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner strategy orchestration extraction.

Status:
Selected; implementation not started.

Selected boundary:
Move strategy branch-count/baseline validation, branch evaluation and ranking,
recommendation/report construction, artifact assembly, operator review, and
Cadence import wrapping into a new internal `StrategyOrchestration` module.
Keep public `strategy/1`, `repair/1`, the normalized request boundary, exact
errors, schema version, deterministic ordering, and all artifact behavior
unchanged.

Selection evidence:
- `campaign_planner.ex` is 601 lines after strategy request normalization.
- The selected block is a self-contained strategy execution pipeline after
  normalization and before the returned V3 artifact.
- Its only facade callback is public `repair/1`, which can remain stable through
  `CampaignPlanner.repair/1`.
- The strategy schema-version attribute is used only by this block and moves
  with the owner.
- Exact validation errors, input-order comparison, ranked ordering, report
  content, review/import wrappers, and deterministic output must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner strategy request normalization extraction, selected in
`8676ab29` and implemented in `73b4d57a`.
`campaign_planner.ex` moved from 759 to 601 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
