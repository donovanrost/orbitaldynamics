# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner strategy orchestration extraction.

Status:
Completed and pushed.

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
Added `StrategyOrchestration` and moved strategy validation, branch
evaluation/ranking, recommendation/report construction, artifact assembly, and
review/import wrapping behind `run/1`. CampaignPlanner moved from 601 to 502
lines; the new owner is 109 lines.

Verification:
- Strict focused core planner, recommendation, mission-state, and operational
  feedback baseline before extraction: 22 passed.
- The same strict focused suite after extraction: 22 passed.
- Strict adjacent strategy recommendation and branch-repair coverage: 9 passed.
- The known branch-generated candidate-refresh file remains 3/4 with the same
  pre-existing refresh-budget pressure expectation mismatch.
- `mix xref callers` reports CampaignPlanner as the sole
  StrategyOrchestration consumer and the new owner as the expected
  StrategyBranchEvaluation and StrategyArtifact consumer.
- Strict compile removed nine aliases and the schema-version attribute that
  moved with the block.
- Static search confirms both selected functions and facade attribute are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,069 files.
- Implementation commit `e39f726b` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, validation errors, repair callback,
input-order comparison, ranked ordering, reports, review/import wrappers,
schema version, and deterministic strategy artifacts remain unchanged.

Last completed slice:
CampaignPlanner strategy orchestration extraction, selected in `a0d60531` and
implemented in `e39f726b`.
`campaign_planner.ex` moved from 601 to 502 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
